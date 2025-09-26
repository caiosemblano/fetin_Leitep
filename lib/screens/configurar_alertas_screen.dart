import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/production_analysis_service.dart';
import '../utils/app_logger.dart';

class ConfigurarAlertasScreen extends StatefulWidget {
  const ConfigurarAlertasScreen({super.key});

  @override
  State<ConfigurarAlertasScreen> createState() =>
      _ConfigurarAlertasScreenState();
}

class _ConfigurarAlertasScreenState extends State<ConfigurarAlertasScreen> {
  List<Map<String, dynamic>> _vacas = [];
  Map<String, Map<String, dynamic>> _alertasConfigurados = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadVacas(),
        _loadAlertasConfigurados(),
      ]);
    } catch (e) {
      AppLogger.error('Erro ao carregar dados', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVacas() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('vacas')
        .where('status', isEqualTo: 'ativa')
        .orderBy('nome')
        .get();

    setState(() {
      _vacas = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              },)
          .toList();
    });
  }

  Future<void> _loadAlertasConfigurados() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('alertas_individuais')
        .get();

    setState(() {
      _alertasConfigurados = {
        for (final doc in snapshot.docs) doc.id: doc.data(),
      };
    });
  }

  Future<void> _configureAlert(Map<String, dynamic> vaca) async {
    final vacaId = vaca['id'] as String;
    final vacaNome = vaca['nome'] as String;
    final alertaAtual = _alertasConfigurados[vacaId];

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AlertConfigDialog(
        vacaNome: vacaNome,
        alertaAtual: alertaAtual,
      ),
    );

    if (result != null) {
      await ProductionAnalysisService.setIndividualCowAlert(
        vacaId: vacaId,
        vacaNome: vacaNome,
        minProduction: result['limite'],
        enabled: result['ativo'],
        customMessage: result['mensagem'],
      );

      await _loadAlertasConfigurados();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alerta configurado para $vacaNome'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Alertas Individuais'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vacas.isEmpty
              ? _buildEmptyState()
              : _buildVacasList(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Nenhuma vaca ativa encontrada',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildVacasList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Text(
            'Configure alertas personalizados para cada vaca\nDefinindo limites mínimos de produção',
            style: TextStyle(color: Colors.blue[700]),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _vacas.length,
            itemBuilder: (context, index) => _buildVacaCard(_vacas[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildVacaCard(Map<String, dynamic> vaca) {
    final vacaId = vaca['id'] as String;
    final vacaNome = vaca['nome'] as String;
    final alerta = _alertasConfigurados[vacaId];
    final temAlerta = alerta != null;
    final alertaAtivo = temAlerta && (alerta['ativo'] as bool? ?? false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: alertaAtivo ? Colors.green : Colors.grey[300],
          child: Icon(
            alertaAtivo ? Icons.notifications_active : Icons.notifications_off,
            color: alertaAtivo ? Colors.white : Colors.grey[600],
          ),
        ),
        title: Text(
          vacaNome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temAlerta && alertaAtivo) ...[
              Text(
                'Limite: ${(alerta['limiteMinimo'] as num).toStringAsFixed(1)}L',
                style: const TextStyle(color: Colors.green),
              ),
              if (alerta['mensagemCustomizada'] != null)
                Text(
                  'Mensagem personalizada configurada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ] else if (temAlerta && !alertaAtivo) ...[
              const Text(
                'Alerta desativado',
                style: TextStyle(color: Colors.orange),
              ),
            ] else ...[
              const Text(
                'Nenhum alerta configurado',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alertaAtivo) Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => _configureAlert(vaca),
              tooltip: 'Configurar alerta',
            ),
          ],
        ),
        onTap: () => _configureAlert(vaca),
      ),
    );
  }
}

class _AlertConfigDialog extends StatefulWidget {
  const _AlertConfigDialog({
    required this.vacaNome,
    this.alertaAtual,
  });
  final String vacaNome;
  final Map<String, dynamic>? alertaAtual;

  @override
  State<_AlertConfigDialog> createState() => _AlertConfigDialogState();
}

class _AlertConfigDialogState extends State<_AlertConfigDialog> {
  late bool _ativo;
  late double _limite;
  late TextEditingController _mensagemController;

  @override
  void initState() {
    super.initState();
    _ativo = widget.alertaAtual?['ativo'] as bool? ?? true;
    _limite = (widget.alertaAtual?['limiteMinimo'] as num?)?.toDouble() ?? 8.0;
    _mensagemController = TextEditingController(
      text: widget.alertaAtual?['mensagemCustomizada'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _mensagemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Configurar Alerta\n${widget.vacaNome}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Ativar alerta'),
              subtitle: const Text('Receber notificações para esta vaca'),
              value: _ativo,
              onChanged: (value) => setState(() => _ativo = value),
            ),
            const SizedBox(height: 16),
            const Text(
              'Limite mínimo de produção (Litros):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _limite,
              min: 1.0,
              max: 20.0,
              divisions: 190,
              label: '${_limite.toStringAsFixed(1)}L',
              onChanged:
                  _ativo ? (value) => setState(() => _limite = value) : null,
            ),
            Text(
              'Atual: ${_limite.toStringAsFixed(1)}L',
              style: TextStyle(
                color: _ativo ? Colors.blue : Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Mensagem personalizada (opcional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mensagemController,
              enabled: _ativo,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Verificar saúde da vaca, ajustar alimentação...',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'ativo': _ativo,
            'limite': _limite,
            'mensagem': _mensagemController.text.trim().isEmpty
                ? null
                : _mensagemController.text.trim(),
          }),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

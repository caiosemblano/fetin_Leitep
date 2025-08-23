import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LimpezaDadosScreen extends StatefulWidget {
  const LimpezaDadosScreen({super.key});

  @override
  State<LimpezaDadosScreen> createState() => _LimpezaDadosScreenState();
}

class _LimpezaDadosScreenState extends State<LimpezaDadosScreen> {
  bool _isScanning = false;
  bool _isCleaning = false;
  int _registrosOrfaos = 0;
  List<String> _problemas = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Limpeza de Dados'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card de Informações
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Limpeza de Dados Órfãos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Esta ferramenta remove registros de produção de vacas que foram excluídas, mantendo seus dados consistentes.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Identifica registros sem vaca associada\n'
                      '• Remove dados inconsistentes\n'
                      '• Melhora performance da dashboard',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Resultados da Análise
            if (_registrosOrfaos > 0 || _problemas.isNotEmpty)
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Problemas Encontrados',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      if (_registrosOrfaos > 0)
                        Text(
                          '📊 $_registrosOrfaos registros de produção órfãos',
                          style: TextStyle(fontSize: 16),
                        ),
                      if (_problemas.isNotEmpty)
                        ..._problemas.map((problema) => Text('• $problema')),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 20),

            // Botões de Ação
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isScanning || _isCleaning ? null : _analisarDados,
                    icon: _isScanning 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.search),
                    label: Text(_isScanning ? 'Analisando...' : 'Analisar Dados'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                
                SizedBox(height: 10),
                
                if (_registrosOrfaos > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isScanning || _isCleaning ? null : _limparDados,
                      icon: _isCleaning 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.cleaning_services),
                      label: Text(_isCleaning ? 'Limpando...' : 'Limpar Dados'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
              ],
            ),

            Spacer(),

            // Aviso
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                border: Border.all(color: Colors.red[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ A limpeza de dados é irreversível. Faça backup antes de prosseguir.',
                      style: TextStyle(color: Colors.red[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _analisarDados() async {
    setState(() {
      _isScanning = true;
      _registrosOrfaos = 0;
      _problemas.clear();
    });

    try {
      // Buscar todas as vacas ativas
      final vacasSnapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .get();
      
      final vacasAtivas = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      // Buscar todos os registros de produção
      final registrosSnapshot = await FirebaseFirestore.instance
          .collection('registros_producao')
          .get();

      int registrosOrfaos = 0;
      List<String> problemas = [];

      for (var doc in registrosSnapshot.docs) {
        final data = doc.data();
        final vacaId = data['vacaId'] as String?;

        if (vacaId == null) {
          problemas.add('Registro sem ID de vaca: ${doc.id}');
        } else if (!vacasAtivas.contains(vacaId)) {
          registrosOrfaos++;
        }
      }

      setState(() {
        _registrosOrfaos = registrosOrfaos;
        _problemas = problemas;
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Análise concluída: $registrosOrfaos registros órfãos encontrados'),
            backgroundColor: registrosOrfaos > 0 ? Colors.orange : Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na análise: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _limparDados() async {
    // Confirmar ação
    final confirmacao = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Limpeza'),
        content: Text(
          'Isso removerá $_registrosOrfaos registros de produção órfãos.\n\n'
          'Esta ação é irreversível. Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmacao != true) return;

    setState(() {
      _isCleaning = true;
    });

    try {
      // Buscar vacas ativas novamente
      final vacasSnapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .get();
      
      final vacasAtivas = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      // Buscar registros órfãos
      final registrosSnapshot = await FirebaseFirestore.instance
          .collection('registros_producao')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      int removidos = 0;

      for (var doc in registrosSnapshot.docs) {
        final data = doc.data();
        final vacaId = data['vacaId'] as String?;

        if (vacaId == null || !vacasAtivas.contains(vacaId)) {
          batch.delete(doc.reference);
          removidos++;
        }
      }

      // Executar limpeza
      await batch.commit();

      setState(() {
        _isCleaning = false;
        _registrosOrfaos = 0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Limpeza concluída: $removidos registros removidos'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      setState(() {
        _isCleaning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na limpeza: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

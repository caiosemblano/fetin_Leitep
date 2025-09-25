import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../widgets/upgrade_prompt_widget.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  String _periodoSelecionado = 'mensal';
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  bool _isLoading = false;
  
  // Dados dos relatórios
  double _producaoTotal = 0;
  double _mediaProducao = 0;
  int _totalVacas = 0;
  List<Map<String, dynamic>> _producaoVacas = [];
  List<Map<String, dynamic>> _producaoTemporal = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final subscription = Provider.of<UserSubscription>(context, listen: false);
      if (subscription.hasRelatoriosAvancados) {
        _carregarDados();
      }
    });
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Buscar dados de produção
      final query = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('registros_producao')
          .where('data', isGreaterThanOrEqualTo: Timestamp.fromDate(_dataInicio))
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(_dataFim))
          .where('tipo', isEqualTo: 'Leite');

      final snapshot = await query.get();
      final registros = snapshot.docs.map((doc) => doc.data()).toList();

      // Calcular métricas
      double producaoTotal = 0;
      Map<String, double> producaoVacas = {};
      Map<String, double> producaoTemporal = {};

      for (var registro in registros) {
        final quantidade = (registro['quantidade'] as num).toDouble();
        final vacaId = registro['vaca_id'] as String;
        final data = (registro['data'] as Timestamp).toDate();
        final dataKey = '${data.day}/${data.month}';

        producaoTotal += quantidade;
        producaoVacas[vacaId] = (producaoVacas[vacaId] ?? 0) + quantidade;
        producaoTemporal[dataKey] = (producaoTemporal[dataKey] ?? 0) + quantidade;
      }

      // Buscar nomes das vacas
      final vacasIds = producaoVacas.keys.toList();
      final vacasData = <String, String>{};
      
      if (vacasIds.isNotEmpty) {
        final vacasQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(userId)
            .collection('vacas')
            .where(FieldPath.documentId, whereIn: vacasIds)
            .get();
            
        for (var doc in vacasQuery.docs) {
          vacasData[doc.id] = doc.data()['nome'] ?? 'Sem nome';
        }
      }

      setState(() {
        _producaoTotal = producaoTotal;
        _mediaProducao = registros.isNotEmpty ? producaoTotal / registros.length : 0;
        _totalVacas = producaoVacas.length;
        
        _producaoVacas = producaoVacas.entries.map((e) => {
          'vaca': vacasData[e.key] ?? 'Vaca ${e.key}',
          'producao': e.value,
        }).toList();
        
        _producaoTemporal = producaoTemporal.entries.map((e) => {
          'data': e.key,
          'producao': e.value,
        }).toList()..sort((a, b) => (a['data'] as String).compareTo(b['data'] as String));
      });
    } catch (e) {
      // AppLogger.log('Erro ao carregar dados dos relatórios: $e', prefix: 'RELATORIOS_ERROR');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selecionarData(bool isInicio) async {
    final data = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (data != null) {
      // Validações antes de atualizar
      DateTime? novaDataInicio = isInicio ? data : _dataInicio;
      DateTime? novaDataFim = isInicio ? _dataFim : data;

      // Verificar se data de início não é após data fim
      if (novaDataInicio.isAfter(novaDataFim)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ A data de início deve ser anterior à data de fim'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
        return;
      }

      // Verificar se período não é muito longo (mais de 2 anos)
      final diferenca = novaDataFim.difference(novaDataInicio).inDays;
      if (diferenca > 730) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('⚠️ Período muito longo (máximo 2 anos)'),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
        }
        return;
      }

      setState(() {
        if (isInicio) {
          _dataInicio = data;
        } else {
          _dataFim = data;
        }
      });
      
      // Recarregar dados com novo período
      final subscription = Provider.of<UserSubscription>(context, listen: false);
      if (subscription.hasRelatoriosAvancados) {
        _carregarDados();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserSubscription>(
      builder: (context, subscription, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Relatórios'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: subscription.hasRelatoriosAvancados ? _carregarDados : null,
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () => _showPlanInfo(context, subscription),
              ),
            ],
          ),
          body: subscription.hasRelatoriosAvancados
              ? _buildAdvancedReports()
              : _buildBasicReports(subscription),
        );
      },
    );
  }

  Widget _buildAdvancedReports() {
    return Column(
      children: [
        // Filtros
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: [
              // Seletor de período
              Row(
                children: [
                  const Text(
                    'Período: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _periodoSelecionado,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'semanal',
                          child: Text('Semanal'),
                        ),
                        DropdownMenuItem(
                          value: 'mensal',
                          child: Text('Mensal'),
                        ),
                        DropdownMenuItem(
                          value: 'trimestral',
                          child: Text('Trimestral'),
                        ),
                        DropdownMenuItem(
                          value: 'anual',
                          child: Text('Anual'),
                        ),
                        DropdownMenuItem(
                          value: 'personalizado',
                          child: Text('Personalizado'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _periodoSelecionado = value!;
                          switch (value) {
                            case 'semanal':
                              _dataInicio = DateTime.now().subtract(
                                const Duration(days: 7),
                              );
                              break;
                            case 'mensal':
                              _dataInicio = DateTime.now().subtract(
                                const Duration(days: 30),
                              );
                              break;
                            case 'trimestral':
                              _dataInicio = DateTime.now().subtract(
                                const Duration(days: 90),
                              );
                              break;
                            case 'anual':
                              _dataInicio = DateTime.now().subtract(
                                const Duration(days: 365),
                              );
                              break;
                          }
                          _dataFim = DateTime.now();
                        });
                        _carregarDados();
                      },
                    ),
                  ),
                ],
              ),
              
              // Seletor de datas personalizadas
              if (_periodoSelecionado == 'personalizado') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selecionarData(true),
                        child: Text('Início: ${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selecionarData(false),
                        child: Text('Fim: ${_dataFim.day}/${_dataFim.month}/${_dataFim.year}'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        // Conteúdo principal
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Cards de métricas
                    _buildMetricaCard(
                      'Produção Total',
                      '${_producaoTotal.toStringAsFixed(2)}L',
                      Icons.water_drop,
                      Colors.blue,
                    ),
                    _buildMetricaCard(
                      'Média por Ordenha',
                      '${_mediaProducao.toStringAsFixed(2)}L',
                      Icons.analytics,
                      Colors.green,
                    ),
                    _buildMetricaCard(
                      'Total de Vacas',
                      _totalVacas.toString(),
                      Icons.pets,
                      Colors.orange,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Gráfico de produção temporal
                    if (_producaoTemporal.isNotEmpty) ...[
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Produção por Período',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: SfCartesianChart(
                                  primaryXAxis: CategoryAxis(),
                                  tooltipBehavior: TooltipBehavior(enable: true),
                                  series: <CartesianSeries>[
                                    LineSeries<Map<String, dynamic>, String>(
                                      dataSource: _producaoTemporal,
                                      xValueMapper: (data, _) => data['data'],
                                      yValueMapper: (data, _) => data['producao'],
                                      color: Colors.blue,
                                      width: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    // Gráfico de produção por vaca
                    if (_producaoVacas.isNotEmpty) ...[
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Text(
                                'Produção por Vaca',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: SfCartesianChart(
                                  primaryXAxis: CategoryAxis(),
                                  tooltipBehavior: TooltipBehavior(enable: true),
                                  series: <CartesianSeries>[
                                    ColumnSeries<Map<String, dynamic>, String>(
                                      dataSource: _producaoVacas,
                                      xValueMapper: (data, _) => data['vaca'],
                                      yValueMapper: (data, _) => data['producao'],
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
        ),
      ],
    );
  }

  Widget _buildMetricaCard(
    String titulo,
    String valor,
    IconData icone,
    Color cor,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withValues(alpha: 0.1),
          child: Icon(icone, color: cor),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Text(
          valor,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: cor,
          ),
        ),
      ),
    );
  }

  /// Relatórios básicos para plano gratuito
  Widget _buildBasicReports(UserSubscription subscription) {
    return const UpgradePromptWidget(
      featureName: 'Relatórios Avançados',
      description: 'Acesse relatórios detalhados de produção, análises comparativas, gráficos avançados e muito mais para otimizar sua fazenda.',
      requiredPlan: 'Intermediário',
    );
  }

  /// Mostrar informações do plano atual
  void _showPlanInfo(BuildContext context, UserSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Plano ${_getPlanDisplayName(subscription.plan)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Acesso aos relatórios:'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    subscription.hasRelatoriosAvancados ? Icons.check_circle : Icons.cancel,
                    color: subscription.hasRelatoriosAvancados ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  const Text('Relatórios Avançados'),
                ],
              ),
              if (!subscription.hasRelatoriosAvancados) ...[
                const SizedBox(height: 16),
                Text(
                  subscription.getUpgradeMessage('relatórios avançados'),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            if (!subscription.hasRelatoriosAvancados)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/planos');
                },
                child: const Text('Upgrade'),
              ),
          ],
        );
      },
    );
  }

  String _getPlanDisplayName(String plan) {
    switch (plan) {
      case 'basic':
        return 'Básico';
      case 'intermediario':
        return 'Intermediário';
      case 'premium':
        return 'Premium';
      default:
        return 'Desconhecido';
    }
  }
}
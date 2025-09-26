import 'dart:async';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/user_service.dart';
import '../utils/app_logger.dart';
import '../widgets/upgrade_prompt_widget.dart';

// Chave global para acessar o estado dos relatórios
final GlobalKey<RelatoriosScreenState> relatoriosScreenKey =
    GlobalKey<RelatoriosScreenState>();

class RelatoriosScreen extends StatefulWidget {
  RelatoriosScreen({Key? key}) : super(key: key ?? relatoriosScreenKey);

  @override
  State<RelatoriosScreen> createState() => RelatoriosScreenState();
}

class RelatoriosScreenState extends State<RelatoriosScreen> {
  String _periodoSelecionado = 'mensal';
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();
  bool _isLoading = false;
  Timer? _timer;

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
      final subscription =
          Provider.of<UserSubscription>(context, listen: false);
      if (subscription.hasRelatoriosAvancados) {
        _carregarDados();

        // Recarregar dados a cada 30 segundos para capturar novos registros
        _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
          if (mounted) {
            AppLogger.info('🔄 [RELATÓRIOS] Recarregamento automático...');
            _carregarDados();
          }
        });
      }
    });
  }

  // Método público para recarregar os dados
  void recarregarDados() {
    AppLogger.info('🔄 [RELATÓRIOS] Recarregamento forçado solicitado');
    _carregarDados();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    AppLogger.info('📊 [RELATÓRIOS] Iniciando carregamento dos dados...');
    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        AppLogger.info('❌ [RELATÓRIOS] Usuário não autenticado');
        return;
      }

      AppLogger.info('✅ [RELATÓRIOS] Usuário ID: $userId');
      AppLogger.info('📅 [RELATÓRIOS] Período: $_dataInicio até $_dataFim');

      // Buscar dados de produção com consulta simplificada para evitar índice composto
      final query = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(userId)
          .collection('registros_producao')
          .where('data',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_dataInicio),)
          .where('data', isLessThanOrEqualTo: Timestamp.fromDate(_dataFim));

      final snapshot = await query.get();
      AppLogger.info(
          '📝 [RELATÓRIOS] Total de documentos encontrados: ${snapshot.docs.length}',);

      // Log dos dados encontrados
      for (final doc in snapshot.docs) {
        final data = doc.data();
        AppLogger.info(
            '📄 [RELATÓRIOS] Doc: ${doc.id} - Tipo: ${data['tipo']} - Data: ${data['data']} - Quantidade: ${data['quantidade']}',);
      }

      // Filtrar por tipo 'Leite' no código para evitar índice composto
      final registros = snapshot.docs
          .map((doc) => doc.data())
          .where((registro) => registro['tipo'] == 'Leite')
          .toList();

      AppLogger.info(
          '🥛 [RELATÓRIOS] Registros de leite filtrados: ${registros.length}',);

      // Calcular métricas
      double producaoTotal = 0;
      final Map<String, double> producaoVacas = {};
      final Map<String, double> producaoTemporal = {};

      for (final registro in registros) {
        final quantidade = (registro['quantidade'] as num).toDouble();
        final vacaId = registro['vaca_id'] as String;
        final data = (registro['data'] as Timestamp).toDate();

        // Melhor formatação da data para ordenação
        String dataKey;
        switch (_periodoSelecionado) {
          case 'semanal':
            // Para semanal, usar dia/mês
            dataKey =
                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
            break;
          case 'mensal':
            // Para mensal, usar dia/mês
            dataKey =
                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
            break;
          case 'trimestral':
            // Para trimestral, usar semana do ano
            final semana = ((data.day - 1) ~/ 7) + 1;
            dataKey = 'Sem $semana/${data.month.toString().padLeft(2, '0')}';
            break;
          case 'anual':
            // Para anual, usar mês/ano
            dataKey = '${data.month.toString().padLeft(2, '0')}/${data.year}';
            break;
          default:
            dataKey =
                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
        }

        AppLogger.info(
            '📈 [RELATÓRIOS] Processando: Vaca $vacaId - Quantidade: ${quantidade}L - Data: $dataKey',);

        producaoTotal += quantidade;
        producaoVacas[vacaId] = (producaoVacas[vacaId] ?? 0) + quantidade;
        producaoTemporal[dataKey] =
            (producaoTemporal[dataKey] ?? 0) + quantidade;
      }

      AppLogger.info('💯 [RELATÓRIOS] Produção total calculada: ${producaoTotal}L');
      AppLogger.info('🐄 [RELATÓRIOS] Vacas únicas: ${producaoVacas.keys.length}');

      // Buscar nomes das vacas
      final vacasIds = producaoVacas.keys.toList();
      final vacasData = <String, String>{};
      final vacasExistentes = <String>{};

      if (vacasIds.isNotEmpty) {
        AppLogger.info('🔍 [RELATÓRIOS] Buscando nomes das vacas: $vacasIds');

        // Buscar cada vaca individualmente para evitar problemas com whereIn
        for (final String vacaId in vacasIds) {
          try {
            // Primeiro, tentar na subcoleção do usuário
            final docUser = await FirebaseFirestore.instance
                .collection('usuarios')
                .doc(userId)
                .collection('vacas')
                .doc(vacaId)
                .get();

            if (docUser.exists && docUser.data() != null) {
              vacasData[vacaId] = docUser.data()!['nome'] ?? 'Sem nome';
              vacasExistentes.add(vacaId);
              AppLogger.info(
                  '🐮 [RELATÓRIOS] Vaca encontrada (subcoleção): $vacaId = ${vacasData[vacaId]}',);
              continue;
            }

            // Se não encontrou na subcoleção, buscar na coleção global
            final docGlobal = await FirebaseFirestore.instance
                .collection('vacas')
                .doc(vacaId)
                .get();

            if (docGlobal.exists && docGlobal.data() != null) {
              final data = docGlobal.data()!;
              // Verificar se a vaca pertence ao usuário atual
              if (data['userId'] == userId) {
                vacasData[vacaId] = data['nome'] ?? 'Sem nome';
                vacasExistentes.add(vacaId);
                AppLogger.info(
                    '🐮 [RELATÓRIOS] Vaca encontrada (global): $vacaId = ${vacasData[vacaId]}',);
                continue;
              }
            }

            // Se não encontrou, não incluir na contagem mas permitir exibição
            vacasData[vacaId] = 'Vaca ${vacaId.substring(0, 8)}... (removida)';
            AppLogger.info(
                '⚠️ [RELATÓRIOS] Vaca não encontrada (pode ter sido removida): $vacaId',);
          } catch (e) {
            AppLogger.info('❌ [RELATÓRIOS] Erro ao buscar vaca $vacaId: $e');
            vacasData[vacaId] = 'Vaca ${vacaId.substring(0, 8)}... (erro)';
          }
        }
      }

      final mediaProducao = registros.isNotEmpty
          ? (producaoTotal / registros.length).toDouble()
          : 0.0;

      AppLogger.info('📊 [RELATÓRIOS] Atualizando estado com:');
      AppLogger.info('  - Produção total: ${producaoTotal}L');
      AppLogger.info('  - Média por registro: ${mediaProducao}L');
      AppLogger.info('  - Total de vacas existentes: ${vacasExistentes.length}');
      AppLogger.info('  - Total de IDs com produção: ${producaoVacas.length}');

      setState(() {
        _producaoTotal = producaoTotal;
        _mediaProducao = mediaProducao;
        _totalVacas =
            vacasExistentes.length; // Contar apenas vacas que realmente existem

        _producaoVacas = producaoVacas.entries
            .map((e) => {
                  'vaca': vacasData[e.key] ?? 'Vaca ${e.key}',
                  'producao': e.value,
                },)
            .toList();

        // Melhor ordenação dos dados temporais
        final tempData = producaoTemporal.entries.toList();
        tempData.sort((a, b) {
          try {
            // Tentar ordenar por data
            final partsA = a.key.split('/');
            final partsB = b.key.split('/');

            if (partsA.length >= 2 && partsB.length >= 2) {
              // Se tem ano (formato dd/mm/yyyy ou mm/yyyy)
              if (partsA.length == 3 || partsB.length == 3) {
                final anoA = partsA.length == 3
                    ? int.parse(partsA[2])
                    : DateTime.now().year;
                final anoB = partsB.length == 3
                    ? int.parse(partsB[2])
                    : DateTime.now().year;
                if (anoA != anoB) return anoA.compareTo(anoB);
              }

              // Comparar mês
              final mesA = int.parse(partsA[1]);
              final mesB = int.parse(partsB[1]);
              if (mesA != mesB) return mesA.compareTo(mesB);

              // Comparar dia (se existir)
              if (partsA.length >= 2 &&
                  partsB.length >= 2 &&
                  partsA[0].length <= 2 &&
                  partsB[0].length <= 2) {
                final diaA = int.parse(partsA[0]);
                final diaB = int.parse(partsB[0]);
                return diaA.compareTo(diaB);
              }
            }
          } catch (e) {
            AppLogger.info('Erro na ordenação de datas: $e');
          }
          return a.key.compareTo(b.key);
        });

        _producaoTemporal = tempData
            .map((e) => {
                  'data': e.key,
                  'producao': e.value,
                },)
            .toList();

        AppLogger.info(
            '📊 [RELATÓRIOS] Dados temporais organizados: ${_producaoTemporal.length} pontos',);
        for (final item in _producaoTemporal) {
          AppLogger.info('  ${item['data']}: ${item['producao']}L');
        }
      });

      AppLogger.info('✅ [RELATÓRIOS] Estado atualizado com sucesso!');
    } catch (e) {
      AppLogger.info('Erro ao carregar dados dos relatórios: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Erro ao carregar relatórios. Tente novamente.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: _carregarDados,
            ),
          ),
        );
      }

      // Definir valores padrão em caso de erro
      setState(() {
        _producaoTotal = 0;
        _mediaProducao = 0;
        _totalVacas = 0;
        _producaoVacas = [];
        _producaoTemporal = [];
      });
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
      final DateTime novaDataInicio = isInicio ? data : _dataInicio;
      final DateTime novaDataFim = isInicio ? _dataFim : data;

      // Verificar se data de início não é após data fim
      if (novaDataInicio.isAfter(novaDataFim)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  '⚠️ A data de início deve ser anterior à data de fim',),
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
      final subscription =
          Provider.of<UserSubscription>(context, listen: false);
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
                onPressed:
                    subscription.hasRelatoriosAvancados ? _carregarDados : null,
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
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
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
                        child: Text(
                            'Início: ${_dataInicio.day}/${_dataInicio.month}/${_dataInicio.year}',),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selecionarData(false),
                        child: Text(
                            'Fim: ${_dataFim.day}/${_dataFim.month}/${_dataFim.year}',),
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
                              if (_producaoTemporal.isEmpty)
                                SizedBox(
                                  height: 200,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.insert_chart,
                                          size: 48,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Nenhum dado de produção encontrado\npara o período selecionado',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                SizedBox(
                                  height: 300,
                                  child: SfCartesianChart(
                                    primaryXAxis: const CategoryAxis(
                                      labelRotation: -45,
                                      labelIntersectAction:
                                          AxisLabelIntersectAction.rotate45,
                                    ),
                                    primaryYAxis: const NumericAxis(
                                      title: AxisTitle(text: 'Produção (L)'),
                                    ),
                                    tooltipBehavior: TooltipBehavior(
                                      enable: true,
                                      format: 'point.x: point.yL',
                                      header: '',
                                      canShowMarker: false,
                                    ),
                                    series: <CartesianSeries>[
                                      LineSeries<Map<String, dynamic>, String>(
                                        dataSource: _producaoTemporal,
                                        xValueMapper: (data, _) =>
                                            data['data'].toString(),
                                        yValueMapper: (data, _) =>
                                            (data['producao'] as num)
                                                .toDouble(),
                                        name: 'Produção',
                                        color: Colors.blue,
                                        width: 3,
                                        markerSettings: const MarkerSettings(
                                          isVisible: true,
                                          shape: DataMarkerType.circle,
                                          width: 6,
                                          height: 6,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

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
                                    primaryXAxis: const CategoryAxis(),
                                    tooltipBehavior: TooltipBehavior(
                                      enable: true,
                                      format: 'point.x: point.yL',
                                      header: '',
                                      canShowMarker: false,
                                    ),
                                    series: <CartesianSeries>[
                                      ColumnSeries<Map<String, dynamic>,
                                          String>(
                                        dataSource: _producaoVacas,
                                        xValueMapper: (data, _) => data['vaca'],
                                        yValueMapper: (data, _) =>
                                            (data['producao'] as num)
                                                .toDouble(),
                                        color: Colors.green,
                                        name: 'Produção',
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
      description:
          'Acesse relatórios detalhados de produção, análises comparativas, gráficos avançados e muito mais para otimizar sua fazenda.',
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
                    subscription.hasRelatoriosAvancados
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: subscription.hasRelatoriosAvancados
                        ? Colors.green
                        : Colors.red,
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

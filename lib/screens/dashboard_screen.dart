import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'atividades_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';
import 'notificacoes_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/production_analysis_service.dart';
import 'alertas_producao_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedChart = 'Produção';

  // Dados do Firebase
  int _totalVacas = 0;
  int _vacasLactacao = 0;
  double _mediaProducaoDiaria = 0.0;
  List<ChartData> _producaoSemanal = [];
  List<ChartData> _saudeData = [];
  List<ChartData> _cicloData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadVacasData(),
        _loadProducaoData(),
        _loadSaudeData(),
        _loadCicloData(),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar dados da dashboard', e);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadVacasData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .where('userId', isEqualTo: user.uid)
          .get();

      AppLogger.info('Dashboard - Carregando vacas para o usuário: ${user.uid}');
      AppLogger.info('Dashboard - Número de vacas encontradas: ${snapshot.docs.length}');

      final totalVacas = snapshot.docs.length;

      // Contar vacas em lactação
      int vacasLactacao = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['lactacao'] == true || data['status'] == 'lactacao') {
          vacasLactacao++;
        }
      }

      setState(() {
        _totalVacas = totalVacas;
        _vacasLactacao = vacasLactacao;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar dados das vacas', e);
    }
  }

  Future<void> _loadProducaoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    // Primeiro, buscar IDs das vacas ativas do usuário
    final vacasSnapshot = await FirebaseFirestore.instance
        .collection('vacas')
        .where('userId', isEqualTo: user.uid)
        .get();

    final vacasAtivas = vacasSnapshot.docs.map((doc) => doc.id).toSet();

    // Consulta simplificada - apenas por userId primeiro
    final snapshot = await FirebaseFirestore.instance
        .collection('registros_producao')
        .where('userId', isEqualTo: user.uid)
        .get();

    // Agrupar por dia da semana
    Map<String, double> producaoPorDia = {
      'Seg': 0.0,
      'Ter': 0.0,
      'Qua': 0.0,
      'Qui': 0.0,
      'Sex': 0.0,
      'Sáb': 0.0,
      'Dom': 0.0,
    };

    List<String> diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
    double totalProducao = 0.0;
    int totalRegistros = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final vacaId = data['vacaId'] as String;
      final tipo = data['tipo'] as String?;
      final dataHora = (data['dataHora'] as Timestamp).toDate();

      // Filtros aplicados no cliente para evitar índices complexos
      // 1. Só processar se a vaca ainda existir
      if (!vacasAtivas.contains(vacaId)) {
        continue;
      }

      // 2. Só processar registros de leite
      if (tipo != 'Leite') {
        continue;
      }

      // 3. Só processar registros dos últimos 7 dias
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      if (dataHora.isBefore(sevenDaysAgo)) {
        continue;
      }

      final quantidade = (data['quantidade'] as num).toDouble();

      final diaSemana = diasSemana[dataHora.weekday % 7];
      producaoPorDia[diaSemana] = producaoPorDia[diaSemana]! + quantidade;

      totalProducao += quantidade;
      totalRegistros++;
    }

    // Calcular média diária
    final mediaDiaria = totalRegistros > 0 ? totalProducao / 7 : 0.0;

    setState(() {
      _mediaProducaoDiaria = mediaDiaria;
      _producaoSemanal = producaoPorDia.entries
          .map((entry) => ChartData(entry.key, entry.value))
          .toList();
    });
  }

  Future<void> _loadSaudeData() async {
    final repo = Provider.of<AtividadesRepository>(context, listen: false);
    final saudeActivities = repo.getAtividadesPorCategoria('Saúde');

    // Agrupar por mês (últimos 6 meses)
    Map<String, int> saudePorMes = {
      'Jan': 0,
      'Fev': 0,
      'Mar': 0,
      'Abr': 0,
      'Mai': 0,
      'Jun': 0,
    };

    // Para este exemplo, vamos usar dados simulados baseados nas atividades existentes
    List<String> meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
    for (int i = 0; i < meses.length; i++) {
      saudePorMes[meses[i]] = (saudeActivities.length / 6).round();
    }

    setState(() {
      _saudeData = saudePorMes.entries
          .map((entry) => ChartData(entry.key, entry.value.toDouble()))
          .toList();
    });
  }

  Future<void> _loadCicloData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('vacas')
        .where('userId', isEqualTo: user.uid)
        .get();

    Map<String, int> cicloCounts = {
      'Cio': 0,
      'Insem.': 0,
      'Gest.': 0,
      'Parto': 0,
    };

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final status = data['status_reprodutivo'] ?? data['ciclo'] ?? 'Cio';

      if (cicloCounts.containsKey(status)) {
        cicloCounts[status] = cicloCounts[status]! + 1;
      } else {
        // Mapear outros status para os conhecidos
        if (status.toString().toLowerCase().contains('cio')) {
          cicloCounts['Cio'] = cicloCounts['Cio']! + 1;
        } else if (status.toString().toLowerCase().contains('insem')) {
          cicloCounts['Insem.'] = cicloCounts['Insem.']! + 1;
        } else if (status.toString().toLowerCase().contains('gest')) {
          cicloCounts['Gest.'] = cicloCounts['Gest.']! + 1;
        } else {
          cicloCounts['Cio'] = cicloCounts['Cio']! + 1;
        }
      }
    }

    setState(() {
      _cicloData = cicloCounts.entries
          .map((entry) => ChartData(entry.key, entry.value.toDouble()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 20),
                _buildQuickStats(context),
                const SizedBox(height: 20),
                _buildChartSelector(context),
                const SizedBox(height: 10),
                _buildSelectedChart(context),
                const SizedBox(height: 20),
                _buildRecentActivities(context),
              ],
            ),
          );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Dashboard",
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboardData,
              tooltip: 'Atualizar dados',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Bem-vindo, Fazendeiro! 👨‍🌾",
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          "Resumo da sua fazenda leiteira",
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildStatCard(
          "Total de Vacas",
          _totalVacas.toString(),
          Icons.pets,
          Colors.blue,
        ),
        _buildStatCard(
          "Vacas em Lactação",
          _vacasLactacao.toString(),
          Icons.opacity,
          Colors.green,
        ),
        _buildStatCard(
          "Média Diária (L)",
          _mediaProducaoDiaria.toStringAsFixed(1),
          Icons.local_drink,
          Colors.orange,
        ),
        _buildNotificationCard(),
        _buildProductionAlertsCard(),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(title, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return FutureBuilder<List<PendingNotificationRequest>>(
      future: NotificationService.getPendingNotifications(),
      builder: (context, snapshot) {
        final notificationsCount = snapshot.data?.length ?? 0;

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificacoesScreen(),
              ),
            );
          },
          child: Card(
            elevation: 4,
            child: Container(
              width: 160,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Icon(Icons.notifications, size: 32, color: Colors.purple),
                      if (notificationsCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              notificationsCount > 9
                                  ? '9+'
                                  : notificationsCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    notificationsCount.toString(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Notificações',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductionAlertsCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AlertasProducaoScreen(),
          ),
        );
      },
      child: Card(
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics, color: Colors.red[600], size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'Análise\nProdução',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  await ProductionAnalysisService.analyzeAllCowsProduction();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Análise concluída!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 32),
                ),
                child: const Text('Analisar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Produção', 'Saúde', 'Ciclo'].map((title) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(title),
              selected: _selectedChart == title,
              onSelected: (selected) {
                setState(() {
                  _selectedChart = title;
                });
              },
              selectedColor: Colors.blue[700],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context) {
    switch (_selectedChart) {
      case 'Saúde':
        return _buildHealthChart(context);
      case 'Ciclo':
        return _buildCycleChart(context);
      case 'Produção':
      default:
        return _buildProductionChart(context);
    }
  }

  Widget _buildProductionChart(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Produção Semanal de Leite (L)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: _producaoSemanal.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Nenhum dado de produção disponível'),
                          Text(
                            'Registre a produção de leite para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      series: <CartesianSeries>[
                        ColumnSeries<ChartData, String>(
                          dataSource: _producaoSemanal,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Colors.blue,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
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

  Widget _buildHealthChart(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saúde do Rebanho',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: _saudeData.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text('Nenhum dado de saúde disponível'),
                          Text(
                            'Registre atividades de saúde para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, String>(
                          dataSource: _saudeData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Colors.red,
                          markerSettings: const MarkerSettings(isVisible: true),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Número de problemas de saúde por mês',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleChart(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ciclo Reprodutivo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: _cicloData.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cable, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('Nenhum dado de ciclo disponível'),
                          Text(
                            'Cadastre vacas com status reprodutivo para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: CategoryAxis(),
                      series: <CartesianSeries>[
                        BarSeries<ChartData, String>(
                          dataSource: _cicloData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Colors.purple,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                      ],
                    ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Status reprodutivo do rebanho',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Consumer<AtividadesRepository>(
      builder: (context, repo, _) {
        final todayActivities = repo.getAtividadesDoDia(DateTime.now());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Registros Recentes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: todayActivities.isEmpty
                    ? const Center(
                        child: Column(
                          children: [
                            Icon(Icons.list_alt, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Nenhum registro recente'),
                            Text('Faça registros para visualizá-los aqui'),
                          ],
                        ),
                      )
                    : Column(
                        children: todayActivities
                            .take(3)
                            .map(
                              (activity) => ListTile(
                                leading: Icon(
                                  activity.category == 'Leite'
                                      ? Icons.local_drink
                                      : activity.category == 'Saúde'
                                      ? Icons.medical_services
                                      : Icons.cable,
                                  color: activity.category == 'Leite'
                                      ? Colors.blue
                                      : activity.category == 'Saúde'
                                      ? Colors.green
                                      : Colors.purple,
                                ),
                                title: Text(activity.name),
                                subtitle: Text(activity.time.format(context)),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ChartData {
  final String x;
  final double y;

  ChartData(this.x, this.y);
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../services/atividades_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';
import '../widgets/loading_skeleton.dart';
import '../utils/app_logger.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/production_analysis_service.dart';
import 'alertas_producao_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
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
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Recarregar dados quando o app volta ao foco
      AppLogger.info('📊 [DASHBOARD] App resumido, recarregando dados');
      _loadDashboardData();
    }
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

      // Tentar buscar no cache primeiro
      final cacheKey = CacheService.dashboardCacheKey(user.uid);
      final Map<String, dynamic>? cachedData =
          CacheService.get<Map<String, dynamic>>(cacheKey);

      if (cachedData != null) {
        AppLogger.info(
            '📊 Dashboard - Dados carregados do cache para usuário: ${user.uid}',);
        setState(() {
          _totalVacas = cachedData['totalVacas'] ?? 0;
          _vacasLactacao = cachedData['vacasLactacao'] ?? 0;
        });
        return;
      }

      // Se não encontrou no cache, buscar no Firestore
      // Buscar primeiro na subcoleção do usuário
      var snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('vacas')
          .get();

      // Se não encontrou na subcoleção, buscar na coleção global
      if (snapshot.docs.isEmpty) {
        snapshot = await FirebaseFirestore.instance
            .collection('vacas')
            .where('userId', isEqualTo: user.uid)
            .get();
      }

      AppLogger.info(
          '📊 Dashboard - Carregando vacas do Firestore para usuário: ${user.uid}',);
      AppLogger.info(
          '📊 Dashboard - Número de vacas encontradas: ${snapshot.docs.length}',);

      final totalVacas = snapshot.docs.length;

      // Contar vacas em lactação
      int vacasLactacao = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['lactacao'] == true || data['status'] == 'lactacao') {
          vacasLactacao++;
        }
      }

      // Armazenar no cache
      final dashboardData = {
        'totalVacas': totalVacas,
        'vacasLactacao': vacasLactacao,
      };
      CacheService.put(cacheKey, dashboardData,
          ttl: const Duration(minutes: 5),);

      setState(() {
        _totalVacas = totalVacas;
        _vacasLactacao = vacasLactacao;
      });
    } catch (e) {
      AppLogger.error('❌ Erro ao carregar dados das vacas', e);
    }
  }

  Future<void> _loadProducaoData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    AppLogger.info(
        '📊 [DASHBOARD] Carregando dados de produção para usuário: ${user.uid}',);

    // Primeiro, buscar IDs das vacas ativas do usuário
    var vacasSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('vacas')
        .get();

    // Se não encontrou na subcoleção, buscar na coleção global
    if (vacasSnapshot.docs.isEmpty) {
      vacasSnapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .where('userId', isEqualTo: user.uid)
          .get();
    }

    final vacasAtivas = vacasSnapshot.docs.map((doc) => doc.id).toSet();
    AppLogger.info(
        '📊 [DASHBOARD] Vacas ativas encontradas: ${vacasAtivas.length}',);

    // Consulta simplificada - buscar na subcoleção do usuário
    final snapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('registros_producao')
        .get();

    AppLogger.info(
        '📊 [DASHBOARD] Total de registros encontrados: ${snapshot.docs.length}',);

    // Agrupar por dia da semana
    final Map<String, double> producaoPorDia = {
      'Seg': 0.0,
      'Ter': 0.0,
      'Qua': 0.0,
      'Qui': 0.0,
      'Sex': 0.0,
      'Sáb': 0.0,
      'Dom': 0.0,
    };

    final List<String> diasSemana = [
      'Dom',
      'Seg',
      'Ter',
      'Qua',
      'Qui',
      'Sex',
      'Sáb',
    ];
    double totalProducao = 0.0;
    int totalRegistros = 0;
    int registrosProcessados = 0;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final vacaId =
          data['vaca_id'] as String?; // CORRIGIDO: usar nome correto do campo
      final tipo = data['tipo'] as String?;
      final dataHora = (data['data'] as Timestamp?)
          ?.toDate(); // CORRIGIDO: usar nome correto do campo

      AppLogger.info(
          '📊 [DASHBOARD] Processando registro: VacaID=$vacaId, Tipo=$tipo, Data=$dataHora',);

      // Filtros aplicados no cliente para evitar índices complexos
      // 1. Só processar se a vaca ainda existir (TEMPORARIAMENTE DESABILITADO PARA DEBUG)
      if (vacaId == null) {
        AppLogger.info('📊 [DASHBOARD] Registro ignorado: vacaId é null');
        continue;
      }

      // 2. Só processar registros de leite
      if (tipo != 'Leite') {
        AppLogger.info('📊 [DASHBOARD] Registro ignorado: não é leite ($tipo)');
        continue;
      }

      // 3. Só processar registros dos últimos 7 dias
      if (dataHora == null || dataHora.isBefore(sevenDaysAgo)) {
        AppLogger.info('📊 [DASHBOARD] Registro ignorado: muito antigo');
        continue;
      }

      final quantidade = (data['quantidade'] as num?)?.toDouble() ?? 0.0;
      AppLogger.info('📊 [DASHBOARD] Registro processado: ${quantidade}L');

      final diaSemana = diasSemana[dataHora.weekday % 7];
      producaoPorDia[diaSemana] = producaoPorDia[diaSemana]! + quantidade;

      totalProducao += quantidade;
      totalRegistros++;
      registrosProcessados++;
    }

    AppLogger.info(
        '📊 [DASHBOARD] Registros processados: $registrosProcessados/${snapshot.docs.length}',);
    AppLogger.info('📊 [DASHBOARD] Produção total: ${totalProducao}L');

    // Calcular média diária
    final mediaDiaria = totalRegistros > 0 ? totalProducao / 7 : 0.0;

    setState(() {
      _mediaProducaoDiaria = mediaDiaria;
      _producaoSemanal = producaoPorDia.entries
          .map((entry) => ChartData(entry.key, entry.value))
          .toList();
    });

    AppLogger.info('📊 [DASHBOARD] Média diária calculada: ${mediaDiaria}L');
  }

  Future<void> _loadSaudeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      AppLogger.info('🏥 [DASHBOARD] Carregando dados de saúde');

      // Buscar todos os registros para filtrar no cliente (evitar índices compostos)
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_producao')
          .get();

      AppLogger.info(
          '🏥 [DASHBOARD] Total de registros encontrados: ${snapshot.docs.length}',);

      // Agrupar por mês
      final Map<String, int> saudePorMes = {
        'Jan': 0,
        'Fev': 0,
        'Mar': 0,
        'Abr': 0,
        'Mai': 0,
        'Jun': 0,
        'Jul': 0,
        'Ago': 0,
        'Set': 0,
        'Out': 0,
        'Nov': 0,
        'Dez': 0,
      };

      final mesesNomes = [
        'Jan',
        'Fev',
        'Mar',
        'Abr',
        'Mai',
        'Jun',
        'Jul',
        'Ago',
        'Set',
        'Out',
        'Nov',
        'Dez',
      ];

      final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
      int registrosSaudeProcessados = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'] as String?;
        final dataHora = (data['data'] as Timestamp?)
            ?.toDate(); // CORRIGIDO: usar nome correto do campo

        // Filtrar no cliente
        if (tipo != 'Saúde' ||
            dataHora == null ||
            dataHora.isBefore(sixMonthsAgo)) {
          continue;
        }

        final mesIndex = dataHora.month - 1;
        if (mesIndex >= 0 && mesIndex < mesesNomes.length) {
          final mesNome = mesesNomes[mesIndex];
          saudePorMes[mesNome] = saudePorMes[mesNome]! + 1;
          registrosSaudeProcessados++;
        }
      }

      AppLogger.info(
          '🏥 [DASHBOARD] Registros de saúde processados: $registrosSaudeProcessados',);

      // Pegar apenas os últimos 6 meses
      final agora = DateTime.now();
      final List<ChartData> dadosGrafico = [];

      for (int i = 5; i >= 0; i--) {
        final mes = DateTime(agora.year, agora.month - i);
        final mesIndex = mes.month - 1;
        if (mesIndex >= 0 && mesIndex < mesesNomes.length) {
          final mesNome = mesesNomes[mesIndex];
          final quantidade = saudePorMes[mesNome] ?? 0;

          dadosGrafico.add(ChartData(mesNome, quantidade.toDouble()));
        }
      }

      AppLogger.info(
          '🏥 [DASHBOARD] Dados do gráfico de saúde: ${dadosGrafico.map((d) => '${d.x}: ${d.y}').join(', ')}',);

      setState(() {
        _saudeData = dadosGrafico;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar dados de saúde', e);
      setState(() {
        _saudeData = [];
      });
    }
  }

  Future<void> _loadCicloData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // Buscar informações das vacas primeiro
      var vacasSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('vacas')
          .get();

      // Se não encontrou na subcoleção, buscar na coleção global
      if (vacasSnapshot.docs.isEmpty) {
        vacasSnapshot = await FirebaseFirestore.instance
            .collection('vacas')
            .where('userId', isEqualTo: user.uid)
            .get();
      }

      AppLogger.info(
          'Vacas encontradas para ciclo: ${vacasSnapshot.docs.length}',);

      final Map<String, int> cicloCounts = {
        'Cio': 0,
        'Insem.': 0,
        'Gest.': 0,
        'Parto': 0,
      };

      // Para cada vaca, buscar o registro de ciclo mais recente
      for (final vacaDoc in vacasSnapshot.docs) {
        final vacaId = vacaDoc.id;
        final vacaData = vacaDoc.data();

        // Buscar o último registro de ciclo desta vaca
        final registroQuery = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('registros_producao')
            .where('vaca_id',
                isEqualTo: vacaId,) // CORRIGIDO: usar nome correto do campo
            .where('tipo', isEqualTo: 'Ciclo')
            .limit(1)
            .get();

        String statusFinal;
        if (registroQuery.docs.isNotEmpty) {
          // Usar o registro mais recente (pode não estar ordenado, mas é o único que temos)
          final registro = registroQuery.docs.first.data();
          statusFinal = registro['periodoCiclo'] ?? 'Cio';
          AppLogger.info('Vaca $vacaId tem registro de ciclo: $statusFinal');
        } else {
          // Usar status_reprodutivo da vaca
          statusFinal = vacaData['status_reprodutivo'] ?? 'Cio';
          AppLogger.info(
              'Vaca $vacaId sem registro, usando status: $statusFinal',);
        }

        // Mapear e contar
        final String statusMapeado = _mapearStatus(statusFinal);
        cicloCounts[statusMapeado] = cicloCounts[statusMapeado]! + 1;
      }

      AppLogger.info('Contagem final de ciclos: ${cicloCounts.toString()}');

      setState(() {
        _cicloData = cicloCounts.entries
            .map((entry) => ChartData(entry.key, entry.value.toDouble()))
            .toList();
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar dados de ciclo', e);
      setState(() {
        _cicloData = [];
      });
    }
  }

  String _mapearStatus(String status) {
    final statusLower = status.toString().toLowerCase();

    if (statusLower.contains('cio')) {
      return 'Cio';
    } else if (statusLower.contains('insem') ||
        statusLower.contains('cobertura')) {
      return 'Insem.';
    } else if (statusLower.contains('gest') ||
        statusLower.contains('prenhez')) {
      return 'Gest.';
    } else if (statusLower.contains('parto') ||
        statusLower.contains('lactação')) {
      return 'Parto';
    } else {
      return 'Cio'; // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                const LoadingSkeleton(height: 32, width: 200),
                const SizedBox(height: 8),
                const LoadingSkeleton(height: 16, width: 150),
                const SizedBox(height: 20),

                // Quick stats skeleton
                const Row(
                  children: [
                    Expanded(child: DashboardCardSkeleton()),
                    SizedBox(width: 16),
                    Expanded(child: DashboardCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: DashboardCardSkeleton()),
                    SizedBox(width: 16),
                    Expanded(child: DashboardCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart skeleton
                const ChartSkeleton(),
                const SizedBox(height: 20),

                // Recent activities skeleton
                const LoadingSkeleton(height: 24, width: 180),
                const SizedBox(height: 16),
                ...List.generate(
                    3,
                    (index) => const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: LoadingSkeleton(height: 60),
                        ),),
              ],
            ),
          )
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
                'Dashboard',
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
          'Bem-vindo, Fazendeiro! 👨‍🌾',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          'Resumo da sua fazenda leiteira',
          style: Theme.of(
            context,
          )
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
          'Total de Vacas',
          _totalVacas.toString(),
          Icons.pets,
          Colors.blue, // Cor fixa
        ),
        _buildStatCard(
          'Vacas em Lactação',
          _vacasLactacao.toString(),
          Icons.opacity,
          Colors.green, // Cor fixa
        ),
        _buildStatCard(
          'Média Diária (L)',
          _mediaProducaoDiaria.toStringAsFixed(1),
          Icons.local_drink,
          Colors.orange, // Cor fixa
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
    return SizedBox(
      width: 160, // Tamanho padronizado
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Ajusta o tamanho ao conteúdo
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(title,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,),),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    return FutureBuilder<List<PendingNotificationRequest>>(
      future: NotificationService.getPendingNotifications(),
      builder: (context, snapshot) {
        final notificationsCount = snapshot.data?.length ?? 0;

        return SizedBox(
          width: 160, // Tamanho padronizado
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      const Icon(Icons.notifications,
                          color: Colors.amber,), // Cor fixa
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
                        fontSize: 20, fontWeight: FontWeight.bold,),
                  ),
                  Text(
                    'Notificações',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,),
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
      child: SizedBox(
        width: 340, // Tamanho maior horizontalmente como era antes
        child: Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Padding maior
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Análise de Produção',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Monitore a produção das suas vacas e receba alertas automáticos.',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,),
                ),
                const SizedBox(height: 12),
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
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('Analisar Agora'),
                ),
              ],
            ),
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
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,),
                          const SizedBox(height: 8),
                          const Text('Nenhum dado de produção disponível'),
                          const Text(
                            'Registre a produção de leite para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      series: <CartesianSeries>[
                        ColumnSeries<ChartData, String>(
                          dataSource: _producaoSemanal,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Theme.of(context).colorScheme.primary,
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          const Text('Nenhum dado de saúde disponível'),
                          const Text(
                            'Registre atividades de saúde para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      series: <CartesianSeries>[
                        LineSeries<ChartData, String>(
                          dataSource: _saudeData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Theme.of(context).colorScheme.error,
                          markerSettings: const MarkerSettings(isVisible: true),
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Número de problemas de saúde por mês',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cable,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,),
                          const SizedBox(height: 8),
                          const Text('Nenhum dado de ciclo disponível'),
                          const Text(
                            'Cadastre vacas com status reprodutivo para ver os gráficos',
                          ),
                        ],
                      ),
                    )
                  : SfCartesianChart(
                      primaryXAxis: const CategoryAxis(),
                      primaryYAxis: const NumericAxis(
                        interval: 1,
                        minimum: 0,
                        labelFormat: '{value}',
                        decimalPlaces: 0,
                      ),
                      series: <CartesianSeries>[
                        BarSeries<ChartData, String>(
                          dataSource: _cicloData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          color: Theme.of(context).colorScheme.tertiary,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Status reprodutivo do rebanho',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,),
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
              'Registros Recentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: todayActivities.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(Icons.list_alt,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,),
                            const SizedBox(height: 8),
                            const Text('Nenhum registro recente'),
                            const Text(
                                'Faça registros para visualizá-los aqui',),
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
  ChartData(this.x, this.y);
  final String x;
  final double y;
}

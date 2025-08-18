import 'package:fetin/screens/atividades_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'atividades_repository.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedChart = 'Produção';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Bem-vindo, Fazendeiro! 👨‍🌾",
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          "Resumo da sua fazenda leiteira",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
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
          "24", 
          Icons.pets, 
          Colors.blue,
        ),
        _buildStatCard(
          "Vacas em Lactação", 
          "18", 
          Icons.opacity, 
          Colors.green,
        ),
        _buildStatCard(
          "Média Diária (L)", 
          "320", 
          Icons.local_drink, 
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
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
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
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
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  ColumnSeries<ChartData, String>(
                    dataSource: [
                      ChartData('Seg', 310),
                      ChartData('Ter', 320),
                      ChartData('Qua', 290),
                      ChartData('Qui', 330),
                      ChartData('Sex', 340),
                      ChartData('Sáb', 300),
                      ChartData('Dom', 280),
                    ],
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Colors.blue,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
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
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  LineSeries<ChartData, String>(
                    dataSource: [
                      ChartData('Jan', 2),
                      ChartData('Fev', 1),
                      ChartData('Mar', 3),
                      ChartData('Abr', 0),
                      ChartData('Mai', 1),
                      ChartData('Jun', 2),
                    ],
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Colors.red,
                    markerSettings: const MarkerSettings(isVisible: true),
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Número de casos de saúde por mês',
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
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries>[
                  BarSeries<ChartData, String>(
                    dataSource: [
                      ChartData('Cio', 5),
                      ChartData('Insem.', 3),
                      ChartData('Gest.', 2),
                      ChartData('Parto', 1),
                    ],
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                    color: Colors.purple,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  )
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
                  ? const Center(child: Text('Nenhum registro recente'))
                  : Column(
                      children: todayActivities
                          .take(3)
                          .map((activity) => ListTile(
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
                              ))
                          .toList(),
                    ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AtividadesScreen(),
                    ),
                  );
                },
                child: const Text('Ver todos os registros'),
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
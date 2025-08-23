import 'package:flutter/material.dart';
import '../services/production_analysis_service.dart';
import '../utils/app_logger.dart';
import 'configurar_alertas_screen.dart';

class AlertasProducaoScreen extends StatefulWidget {
  const AlertasProducaoScreen({super.key});

  @override
  State<AlertasProducaoScreen> createState() => _AlertasProducaoScreenState();
}

class _AlertasProducaoScreenState extends State<AlertasProducaoScreen> {
  List<Map<String, dynamic>> _alertas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAlertas();
  }

  Future<void> _loadAlertas() async {
    setState(() => _isLoading = true);
    try {
      final alertas = await ProductionAnalysisService.getPendingAlerts();
      setState(() {
        _alertas = alertas;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar alertas', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runAnalysis() async {
    setState(() => _isLoading = true);
    try {
      await ProductionAnalysisService.analyzeAllCowsProduction();
      await _loadAlertas(); // Recarregar após análise
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análise de produção concluída!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Erro ao executar análise', e);
      setState(() => _isLoading = false);
      
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

  Future<void> _markAsViewed(String alertId) async {
    try {
      await ProductionAnalysisService.markAlertAsViewed(alertId);
      _loadAlertas(); // Recarregar lista
    } catch (e) {
      AppLogger.error('Erro ao marcar alerta como visualizado', e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Produção'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConfigurarAlertasScreen(),
                ),
              );
            },
            tooltip: 'Configurar Alertas Individuais',
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _isLoading ? null : _runAnalysis,
            tooltip: 'Executar Análise',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAlertas,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _alertas.isEmpty
              ? _buildEmptyState()
              : _buildAlertsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum alerta de produção',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Todas as vacas estão com produção normal',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _runAnalysis,
            icon: const Icon(Icons.analytics),
            label: const Text('Executar Análise'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsList() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.orange[50],
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_alertas.length} alerta(s) de queda de produção detectado(s)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _alertas.length,
            itemBuilder: (context, index) => _buildAlertCard(_alertas[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alerta) {
    final vacaNome = alerta['vacaNome'] ?? 'Vaca sem nome';
    final percentualQueda = alerta['percentualQueda']?.toDouble() ?? 0.0;
    final producaoRecente = alerta['producaoRecente']?.toDouble() ?? 0.0;
    final producaoAnterior = alerta['producaoAnterior']?.toDouble() ?? 0.0;
    final diasAnalisados = alerta['diasAnalisados'] ?? 0;
    
    // Converter timestamp se necessário
    DateTime? dataAlerta;
    if (alerta['dataAlerta'] != null) {
      final timestamp = alerta['dataAlerta'];
      if (timestamp is Map && timestamp.containsKey('_seconds')) {
        dataAlerta = DateTime.fromMillisecondsSinceEpoch(
          timestamp['_seconds'] * 1000,
        );
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: Colors.red[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vacaNome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Queda de ${percentualQueda.toStringAsFixed(1)}% na produção',
                        style: TextStyle(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () => _markAsViewed(alerta['id']),
                  tooltip: 'Marcar como visualizado',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricItem(
                        'Produção Anterior',
                        '${producaoAnterior.toStringAsFixed(1)}L',
                        Colors.green,
                      ),
                      _buildMetricItem(
                        'Produção Recente',
                        '${producaoRecente.toStringAsFixed(1)}L',
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Análise de $diasAnalisados dias',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (dataAlerta != null)
                        Text(
                          'Detectado em ${dataAlerta.day}/${dataAlerta.month}/${dataAlerta.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToVacaDetails(alerta['vacaId']),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Ver Detalhes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToProducaoHistory(alerta['vacaId']),
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Histórico'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _navigateToVacaDetails(String vacaId) {
    // Navegar para tela de detalhes da vaca
    AppLogger.info('Navegando para detalhes da vaca: $vacaId');
    
    // Mostrar diálogo com informações da vaca por enquanto
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🐄 Detalhes da Vaca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: $vacaId'),
            const SizedBox(height: 8),
            const Text('Esta funcionalidade permitirá visualizar:'),
            const SizedBox(height: 8),
            const Text('• Informações gerais da vaca'),
            const Text('• Status de saúde atual'),
            const Text('• Dados reprodutivos'),
            const Text('• Histórico médico'),
            const Text('• Gráficos de produção'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Futura navegação para VacaDetailsScreen(vacaId: vacaId)
            },
            child: const Text('Ir para Detalhes'),
          ),
        ],
      ),
    );
  }

  void _navigateToProducaoHistory(String vacaId) {
    // Navegar para histórico de produção
    AppLogger.info('Navegando para histórico de produção da vaca: $vacaId');
    
    // Mostrar diálogo com preview do histórico por enquanto
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Histórico de Produção'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Vaca ID: $vacaId'),
              const SizedBox(height: 16),
              const Text('Esta tela mostrará:'),
              const SizedBox(height: 8),
              const Text('• Gráfico de produção mensal'),
              const Text('• Comparação com médias do rebanho'),
              const Text('• Tendências de produção'),
              const Text('• Alertas históricos'),
              const Text('• Correlação com eventos (parto, doenças)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Funcionalidade em desenvolvimento',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Futura navegação para ProducaoHistoryScreen(vacaId: vacaId)
            },
            child: const Text('Ver Histórico'),
          ),
        ],
      ),
    );
  }
}

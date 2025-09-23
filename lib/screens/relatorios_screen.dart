import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

class RelatoriosScreen extends StatefulWidget {
  const RelatoriosScreen({super.key});

  @override
  State<RelatoriosScreen> createState() => _RelatoriosScreenState();
}

class _RelatoriosScreenState extends State<RelatoriosScreen> {
  String _periodoSelecionado = 'mensal';
  DateTime _dataInicio = DateTime.now().subtract(const Duration(days: 30));
  DateTime _dataFim = DateTime.now();

  // Dados reais do Firebase
  bool _isLoading = true;
  double _producaoTotal = 0.0;
  double _mediaDiaria = 0.0;
  String _melhorVaca = 'Nenhuma';
  double _eficiencia = 0.0;
  List<Map<String, dynamic>> _producaoVacas = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;

      // Verificar autenticação
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      // Buscar todas as produções no período
      final producoes = await firestore
          .collection('registros_producao')
          .where('userId', isEqualTo: user.uid)
          .where('tipo', isEqualTo: 'Leite')
          .where(
            'dataHora',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_dataInicio),
          )
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(_dataFim))
          .get();

      if (producoes.docs.isEmpty) {
        setState(() {
          _producaoTotal = 0;
          _mediaDiaria = 0;
          _melhorVaca = 'Nenhuma';
          _eficiencia = 0;
          _producaoVacas = [];
          _isLoading = false;
        });
        return;
      }

      // Calcular métricas
      double total = 0;
      Map<String, double> producaoPorVaca = {};
      Map<String, String> nomeVacas = {};

      // Buscar nomes das vacas primeiro
      final vacas = await firestore.collection('vacas').get();
      for (var doc in vacas.docs) {
        nomeVacas[doc.id] = doc.data()['nome'] ?? 'Sem nome';
      }

      for (var doc in producoes.docs) {
        final data = doc.data();
        // Verificar se é um registro de leite
        if (data['tipo'] != 'Leite') continue;

        final quantidade = (data['quantidade'] as num?)?.toDouble() ?? 0;
        final vacaId = data['vacaId'] as String?;

        total += quantidade;

        if (vacaId != null) {
          final nomeVaca = nomeVacas[vacaId] ?? 'Vaca $vacaId';
          producaoPorVaca[nomeVaca] =
              (producaoPorVaca[nomeVaca] ?? 0) + quantidade;
        }
      }

      // Média diária
      final dias = _dataFim.difference(_dataInicio).inDays + 1;
      final media = dias > 0 ? total / dias : 0.0;

      // Melhor vaca
      String melhorVaca = 'Nenhuma';
      double maiorProducao = 0;
      producaoPorVaca.forEach((nome, producao) {
        if (producao > maiorProducao) {
          maiorProducao = producao;
          melhorVaca = '$nome (${producao.toStringAsFixed(1)}L)';
        }
      });

      // Eficiência (simulada com base na produção)
      double eficiencia = total > 0
          ? (total / (vacas.docs.length * dias * 30)) * 100
          : 0;
      if (eficiencia > 100) eficiencia = 100;

      // Lista para o gráfico
      final producaoVacas = producaoPorVaca.entries
          .map((entry) => {'vaca': entry.key, 'producao': entry.value})
          .toList();

      setState(() {
        _producaoTotal = total;
        _mediaDiaria = media;
        _melhorVaca = melhorVaca;
        _eficiencia = eficiencia;
        _producaoVacas = producaoVacas;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Erro ao carregar dados dos relatórios', e);
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
      setState(() {
        if (isInicio) {
          _dataInicio = data;
        } else {
          _dataFim = data;
        }
      });
      await _carregarDados(); // Recarregar dados com novo período
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.3),
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

                // Datas personalizadas
                if (_periodoSelecionado == 'personalizado') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Data Início',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selecionarData(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Data Fim',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () => _selecionarData(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Cards de métricas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    children: [
                      _buildMetricaCard(
                        'Produção Total',
                        '${_producaoTotal.toStringAsFixed(1)} L',
                        Icons.opacity,
                        Colors.blue,
                      ),
                      _buildMetricaCard(
                        'Média Diária',
                        '${_mediaDiaria.toStringAsFixed(1)} L',
                        Icons.timeline,
                        Colors.green,
                      ),
                      _buildMetricaCard(
                        'Melhor Vaca',
                        _melhorVaca,
                        Icons.star,
                        Colors.orange,
                      ),
                      _buildMetricaCard(
                        'Eficiência',
                        '${_eficiencia.toStringAsFixed(1)}%',
                        Icons.trending_up,
                        Colors.purple,
                      ),

                      // Gráfico de produção por vaca
                      Card(
                        margin: const EdgeInsets.all(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                child: _producaoVacas.isEmpty
                                    ? const Center(
                                        child: Text('Nenhum dado disponível'),
                                      )
                                    : SfCartesianChart(
                                        primaryXAxis: const CategoryAxis(),
                                        title: ChartTitle(
                                          text: 'Produção Individual',
                                        ),
                                        legend: Legend(isVisible: false),
                                        tooltipBehavior: TooltipBehavior(
                                          enable: true,
                                        ),
                                        series: <CartesianSeries>[
                                          ColumnSeries<
                                            Map<String, dynamic>,
                                            String
                                          >(
                                            dataSource: _producaoVacas,
                                            xValueMapper: (data, _) =>
                                                data['vaca'],
                                            yValueMapper: (data, _) =>
                                                data['producao'],
                                            color: Colors.blue,
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
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
}

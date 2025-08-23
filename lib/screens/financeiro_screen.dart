import 'package:flutter/material.dart';

class FinanceiroScreen extends StatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final double _receitaTotal = 0.0;
  final double _despesaTotal = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão Financeira'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _adicionarTransacao,
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de resumo financeiro
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildFinanceCard(
                    'Receita',
                    _receitaTotal,
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinanceCard(
                    'Despesas',
                    _despesaTotal,
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ),
          // Lucro/Prejuízo
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Resultado:', style: TextStyle(fontSize: 18)),
                  Text(
                    'R\$ ${(_receitaTotal - _despesaTotal).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: (_receitaTotal - _despesaTotal) >= 0 
                          ? Colors.green 
                          : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String title, double value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(
              'R\$ ${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _adicionarTransacao() {
    // Dialog para adicionar receita/despesa
  }
}

import 'package:flutter/material.dart';

class SaudeScreen extends StatefulWidget {
  const SaudeScreen({super.key});

  @override
  State<SaudeScreen> createState() => _SaudeScreenState();
}

class _SaudeScreenState extends State<SaudeScreen> {
  final List<Map<String, dynamic>> _tratamentos = [];
  final List<Map<String, dynamic>> _vacinacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() async {
    // Carregar tratamentos e vacinações
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Saúde do Rebanho'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.medical_services), text: 'Tratamentos'),
              Tab(icon: Icon(Icons.vaccines), text: 'Vacinações'),
              Tab(icon: Icon(Icons.schedule), text: 'Próximos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTratamentosTab(),
            _buildVacinacoesTab(),
            _buildProximosTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _adicionarTratamento,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildTratamentosTab() {
    return ListView.builder(
      itemCount: _tratamentos.length,
      itemBuilder: (context, index) {
        final tratamento = _tratamentos[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.medical_services, color: Colors.red),
            title: Text(tratamento['medicamento'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vaca: ${tratamento['vaca_id']}'),
                Text('Data: ${tratamento['data']}'),
                Text('Dosagem: ${tratamento['dosagem']}'),
              ],
            ),
            trailing: Icon(
              tratamento['concluido'] ? Icons.check_circle : Icons.pending,
              color: tratamento['concluido'] ? Colors.green : Colors.orange,
            ),
          ),
        );
      },
    );
  }

  Widget _buildVacinacoesTab() {
    return ListView.builder(
      itemCount: _vacinacoes.length,
      itemBuilder: (context, index) {
        final vacinacao = _vacinacoes[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ListTile(
            leading: const Icon(Icons.vaccines, color: Colors.blue),
            title: Text(vacinacao['vacina'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vaca: ${vacinacao['vaca_id']}'),
                Text('Data: ${vacinacao['data']}'),
                Text('Próxima dose: ${vacinacao['proxima_dose']}'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProximosTab() {
    return const Center(
      child: Text('Próximos tratamentos e vacinações'),
    );
  }

  void _adicionarTratamento() {
    // Dialog para adicionar tratamento/vacinação
  }
}

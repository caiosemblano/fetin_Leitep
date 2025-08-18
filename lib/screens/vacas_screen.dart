import 'package:flutter/material.dart';

class VacasScreen extends StatefulWidget {
  const VacasScreen({super.key});

  @override
  State<VacasScreen> createState() => _VacasScreenState();
}

class _VacasScreenState extends State<VacasScreen> {
  final List<Map<String, dynamic>> _vacas = [
    {
      'id': '1',
      'nome': 'Mimosa',
      'raca': 'Holandesa',
      'idade': '5',
      'peso': '550',
      'lactacao': true
    },
    {
      'id': '2',
      'nome': 'Estrela',
      'raca': 'Jersey',
      'idade': '4',
      'peso': '450',
      'lactacao': true
    },
    {
      'id': '3',
      'nome': 'Flor',
      'raca': 'Gir',
      'idade': '6',
      'peso': '600',
      'lactacao': false
    },
  ];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();

  String _selectedFilter = 'Todas';
  bool _showOnlyLactantes = false;
  List<Map<String, dynamic>> _filteredVacas = [];
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _filteredVacas = _vacas;
    _searchController.addListener(_filterVacas);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _filterVacas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVacas = _vacas.where((vaca) {
        final matchesSearch = vaca['nome'].toLowerCase().contains(query) ||
            vaca['raca'].toLowerCase().contains(query);
        final matchesFilter =
            _selectedFilter == 'Todas' || vaca['raca'] == _selectedFilter;
        final matchesLactacao = !_showOnlyLactantes || vaca['lactacao'];

        return matchesSearch && matchesFilter && matchesLactacao;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Vacas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          _buildFilterRow(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _filterVacas();
                });
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filteredVacas.length,
                itemBuilder: (context, index) {
                  final vaca = _filteredVacas[index];
                  return _buildVacaCard(vaca);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVacaForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedFilter,
              items: ['Todas', 'Holandesa', 'Jersey', 'Gir']
                  .map((raca) => DropdownMenuItem(
                        value: raca,
                        child: Text(raca),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                  _filterVacas();
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filtrar por raça',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FilterChip(
            label: const Text('Em lactação'),
            selected: _showOnlyLactantes,
            onSelected: (value) {
              setState(() {
                _showOnlyLactantes = value;
                _filterVacas();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVacaCard(Map<String, dynamic> vaca) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.pets, size: 40),
        title: Text(vaca['nome']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raça: ${vaca['raca']}'),
            Text('Idade: ${vaca['idade']} anos'),
            Text('Peso: ${vaca['peso']} kg'),
            if (vaca['lactacao'])
              const Text('Em lactação',
                  style: TextStyle(color: Colors.green)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showVacaForm(context, vaca: vaca),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteVaca(vaca),
            ),
          ],
        ),
      ),
    );
  }

  void _showVacaForm(BuildContext context, {Map<String, dynamic>? vaca}) {
    final isEditing = vaca != null;
    _editingId = isEditing ? vaca['id'] : null;

    if (isEditing) {
      _nomeController.text = vaca['nome'];
      _racaController.text = vaca['raca'];
      _idadeController.text = vaca['idade'];
      _pesoController.text = vaca['peso'];
    }

    bool lactacao = isEditing ? vaca['lactacao'] : false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Editar Vaca' : 'Adicionar Vaca'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _racaController,
                      decoration: const InputDecoration(
                        labelText: 'Raça',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _idadeController,
                      decoration: const InputDecoration(
                        labelText: 'Idade (anos)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pesoController,
                      decoration: const InputDecoration(
                        labelText: 'Peso (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Em lactação'),
                      value: lactacao,
                      onChanged: (value) => setState(() => lactacao = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _clearForm();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_validateForm()) {
                      _saveVaca(
                        nome: _nomeController.text,
                        raca: _racaController.text,
                        idade: _idadeController.text,
                        peso: _pesoController.text,
                        lactacao: lactacao,
                      );
                      _clearForm();
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Salvar' : 'Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _validateForm() {
    return _nomeController.text.isNotEmpty &&
        _racaController.text.isNotEmpty &&
        _idadeController.text.isNotEmpty &&
        _pesoController.text.isNotEmpty;
  }

  void _saveVaca({
    required String nome,
    required String raca,
    required String idade,
    required String peso,
    required bool lactacao,
  }) {
    final newVaca = {
      'id': _editingId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'nome': nome,
      'raca': raca,
      'idade': idade,
      'peso': peso,
      'lactacao': lactacao,
    };

    setState(() {
      if (_editingId != null) {
        final index = _vacas.indexWhere((v) => v['id'] == _editingId);
        if (index != -1) _vacas[index] = newVaca;
      } else {
        _vacas.add(newVaca);
      }
      _filterVacas();
    });
  }

  void _deleteVaca(Map<String, dynamic> vaca) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja remover ${vaca['nome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _vacas.removeWhere((v) => v['id'] == vaca['id']);
                _filterVacas();
              });
              Navigator.pop(context);
            },
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearForm() {
    _nomeController.clear();
    _racaController.clear();
    _idadeController.clear();
    _pesoController.clear();
    _editingId = null;
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VacasScreen extends StatefulWidget {
  const VacasScreen({super.key});

  @override
  State<VacasScreen> createState() => _VacasScreenState();
}

class _VacasScreenState extends State<VacasScreen> {
  final List<Map<String, dynamic>> _vacas = [];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _racaController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _maeController = TextEditingController();
  final TextEditingController _paiController = TextEditingController();

  String _selectedFilter = 'Todas';
  String _selectedTipoFilter = 'Todos';
  bool _showOnlyLactantes = false;
  List<Map<String, dynamic>> _filteredVacas = [];
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterVacas);
    _loadVacas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _maeController.dispose();
    _paiController.dispose();
    super.dispose();
  }

  void _filterVacas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredVacas = _vacas.where((vaca) {
        final matchesSearch =
            vaca['nome'].toLowerCase().contains(query) ||
            vaca['raca'].toLowerCase().contains(query);
        final matchesFilter =
            _selectedFilter == 'Todas' || vaca['raca'] == _selectedFilter;
        final matchesTipo =
            _selectedTipoFilter == 'Todos' ||
            (vaca['tipo'] ?? 'vaca') == _selectedTipoFilter;
        final matchesLactacao =
            !_showOnlyLactantes || (vaca['lactacao'] ?? false);

        return matchesSearch && matchesFilter && matchesTipo && matchesLactacao;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Animais'),
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
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  items: ['Todas', 'Holandesa', 'Jersey', 'Gir']
                      .map(
                        (raca) =>
                            DropdownMenuItem(value: raca, child: Text(raca)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                      _filterVacas();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Raça',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedTipoFilter,
                  items: ['Todos', 'vaca', 'bezerro', 'bezerra', 'novilha']
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(_formatTipo(tipo)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTipoFilter = value!;
                      _filterVacas();
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Tipo',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
        ],
      ),
    );
  }

  String _formatTipo(String tipo) {
    switch (tipo) {
      case 'Todos':
        return 'Todos';
      case 'vaca':
        return 'Vaca Adulta';
      case 'bezerro':
        return 'Bezerro';
      case 'bezerra':
        return 'Bezerra';
      case 'novilha':
        return 'Novilha';
      default:
        return tipo;
    }
  }

  Widget _buildVacaCard(Map<String, dynamic> vaca) {
    final tipo = vaca['tipo'] ?? 'vaca';
    final isYoung = tipo == 'bezerro' || tipo == 'bezerra' || tipo == 'novilha';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(tipo),
          child: Icon(_getTypeIcon(tipo), color: Colors.white),
        ),
        title: Row(
          children: [
            Expanded(child: Text(vaca['nome'])),
            if (isYoung)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatTipo(tipo),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raça: ${vaca['raca']}'),
            Text('Idade: ${vaca['idade']} anos'),
            Text('Peso: ${vaca['peso']} kg'),
            if (vaca['lactacao'] == true)
              const Text('Em lactação', style: TextStyle(color: Colors.green)),
            if (isYoung && _isReadyToPromote(vaca))
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎉 Pronto para ser vaca adulta!',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isYoung && _isReadyToPromote(vaca))
              IconButton(
                icon: const Icon(Icons.trending_up, color: Colors.green),
                tooltip: 'Promover para vaca adulta',
                onPressed: () => _promoteAnimal(vaca),
              ),
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

  Color _getTypeColor(String tipo) {
    switch (tipo) {
      case 'bezerro':
      case 'bezerra':
        return Colors.brown[300]!;
      case 'novilha':
        return Colors.amber[600]!;
      case 'vaca':
      default:
        return Colors.blue[600]!;
    }
  }

  IconData _getTypeIcon(String tipo) {
    switch (tipo) {
      case 'bezerro':
      case 'bezerra':
        return Icons.child_care;
      case 'novilha':
        return Icons.person;
      case 'vaca':
      default:
        return Icons.pets;
    }
  }

  bool _isReadyToPromote(Map<String, dynamic> animal) {
    try {
      if (animal.containsKey('dataNascimento')) {
        final dataNascimento = (animal['dataNascimento'] as Timestamp).toDate();
        final idade = DateTime.now().difference(dataNascimento);
        return idade.inDays >= (18 * 30); // 18 meses
      } else if (animal.containsKey('idadeMeses')) {
        final idadeMeses = animal['idadeMeses'] as int;
        return idadeMeses >= 18;
      } else if (animal.containsKey('idade')) {
        final idadeAnos = double.tryParse(animal['idade'].toString()) ?? 0;
        return idadeAnos >= 1.5; // 18 meses = 1.5 anos
      }
      return false;
    } catch (e) {
      return false;
    }
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
                  onPressed: () async {
                    if (_validateForm()) {
                      final navigator = Navigator.of(context);
                      await _saveVaca(
                        nome: _nomeController.text,
                        raca: _racaController.text,
                        idade: _idadeController.text,
                        peso: _pesoController.text,
                        lactacao: lactacao,
                      );
                      _clearForm();
                      navigator.pop();
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

  Future<void> _saveVaca({
    required String nome,
    required String raca,
    required String idade,
    required String peso,
    required bool lactacao,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final vacaData = {
      'nome': nome,
      'raca': raca,
      'idade': idade,
      'peso': peso,
      'lactacao': lactacao,
      'userId': user.uid,
    };

    final messenger = ScaffoldMessenger.of(context);

    if (_editingId != null) {
      // Atualiza vaca existente
      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(_editingId)
          .set(vacaData, SetOptions(merge: true));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Vaca atualizada com sucesso!')),
      );
    } else {
      // Adiciona nova vaca
      await FirebaseFirestore.instance.collection('vacas').add(vacaData);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Vaca adicionada com sucesso!')),
      );
    }

    await _loadVacas();
    _filterVacas();
  }

  Future<void> _loadVacas() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .where('userId', isEqualTo: user.uid)
          .get();

      print('Carregando vacas para o usuário: ${user.uid}');
      print('Número de vacas encontradas: ${snapshot.docs.length}');

      setState(() {
        _vacas.clear();
        for (var doc in snapshot.docs) {
          final data = {'id': doc.id, ...doc.data()};
          print('Vaca carregada: ${data['nome']} (ID: ${data['id']})');
          _vacas.add(data);
        }
        _filterVacas();
      });
    } catch (e) {
      print('Erro ao carregar vacas: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar vacas: $e')));
    }
  }

  void _deleteVaca(Map<String, dynamic> vaca) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deseja remover ${vaca['nome']}?'),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Isso também removerá:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const Text('• Todos os registros de produção'),
            const Text('• Histórico de atividades relacionadas'),
            const Text('• Dados de saúde e ciclo reprodutivo'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(context);

              try {
                // Mostrar loading
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // 1. Excluir registros de produção
                final producaoSnapshot = await FirebaseFirestore.instance
                    .collection('registros_producao')
                    .where('vacaId', isEqualTo: vaca['id'])
                    .get();

                final batch = FirebaseFirestore.instance.batch();

                for (var doc in producaoSnapshot.docs) {
                  batch.delete(doc.reference);
                }

                // 2. Excluir a vaca
                batch.delete(
                  FirebaseFirestore.instance
                      .collection('vacas')
                      .doc(vaca['id']),
                );

                // Executar batch
                await batch.commit();

                // Fechar loading
                navigator.pop();
                // Fechar dialog principal
                navigator.pop();

                await _loadVacas();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      '${vaca['nome']} e todos os registros relacionados foram removidos',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // Fechar loading se ainda estiver aberto
                navigator.pop();
                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Remover Tudo',
              style: TextStyle(color: Colors.red),
            ),
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
    _maeController.clear();
    _paiController.clear();
    _editingId = null;
  }

  // Promover animal individual
  Future<void> _promoteAnimal(Map<String, dynamic> animal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Promover Animal'),
        content: Text(
          'Deseja promover ${animal['nome']} para vaca adulta?\n\n'
          'Esta ação irá:\n'
          '• Alterar o tipo para "vaca adulta"\n'
          '• Atualizar o peso estimado\n'
          '• Habilitar para lactação',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Promover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Atualizar dados do animal
        final updatedData = Map<String, dynamic>.from(animal);
        updatedData['tipo'] = 'vaca';
        updatedData['categoria'] = 'adulta';
        updatedData['dataPromocao'] = Timestamp.now();

        // Estimar peso adulto baseado na raça
        switch (updatedData['raca'].toString().toLowerCase()) {
          case 'holandesa':
            updatedData['peso'] = '650';
            break;
          case 'jersey':
            updatedData['peso'] = '450';
            break;
          case 'gir':
            updatedData['peso'] = '500';
            break;
          default:
            updatedData['peso'] = '550';
        }

        await FirebaseFirestore.instance
            .collection('vacas')
            .doc(animal['id'])
            .update(updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${animal['nome']} promovido para vaca adulta!'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadVacas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao promover animal: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

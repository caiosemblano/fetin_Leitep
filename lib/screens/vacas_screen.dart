import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/orphan_cleanup_service.dart';
import '../services/plan_validation_service.dart';
import '../services/user_service.dart';
import '../utils/app_logger.dart';

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
      floatingActionButton: Consumer<UserSubscription>(
        builder: (context, subscription, _) {
          return FloatingActionButton(
            heroTag: "vacas_fab",
            onPressed: () async {
              if (await PlanValidationService.canAddCow(context, subscription)) {
                _showVacaForm(context);
              }
            },
            child: const Icon(Icons.add),
          );
        },
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

  void _showVacaDetails(Map<String, dynamic> vaca) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return VacaDetailsDialog(vaca: vaca);
      },
    );
  }

  Widget _buildVacaCard(Map<String, dynamic> vaca) {
    final tipo = vaca['tipo'] ?? 'vaca';
    final isYoung = tipo == 'bezerro' || tipo == 'bezerra' || tipo == 'novilha';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () => _showVacaDetails(vaca),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(tipo),
            child: Icon(_getTypeIcon(tipo), color: Theme.of(context).colorScheme.onPrimary),
          ),
          title: Row(
            children: [
              Expanded(child: Text(vaca['nome'])),
              if (isYoung)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatTipo(tipo),
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
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
                Text('Em lactação', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              if (isYoung && _isReadyToPromote(vaca))
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎉 Pronto para ser vaca adulta!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
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
                  icon: Icon(Icons.trending_up, color: Theme.of(context).colorScheme.tertiary),
                  tooltip: 'Promover para vaca adulta',
                  onPressed: () => _promoteAnimal(vaca),
                ),
              IconButton(
                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _showVacaForm(context, vaca: vaca),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                onPressed: () => _deleteVaca(vaca),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String tipo) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (tipo) {
      case 'bezerro':
      case 'bezerra':
        return colorScheme.secondary;
      case 'novilha':
        return colorScheme.tertiary;
      case 'vaca':
      default:
        return colorScheme.primary;
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
      // Buscar peso anterior antes de atualizar
      final docSnapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .doc(_editingId)
          .get();
      
      if (docSnapshot.exists) {
        final dadosAtuais = docSnapshot.data()!;
        final pesoAnterior = dadosAtuais['peso'] as String?;
        
        // Se o peso mudou, salvar no histórico
        if (pesoAnterior != null && pesoAnterior != peso) {
          await _salvarHistoricoPeso(
            vacaId: _editingId!,
            pesoAnterior: pesoAnterior,
            pesoNovo: peso,
          );
        }
      }
      
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

  Future<void> _salvarHistoricoPeso({
    required String vacaId,
    required String pesoAnterior,
    required String pesoNovo,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final historicoPesoData = {
      'vaca_id': vacaId,
      'userId': user.uid,
      'pesoAnterior': pesoAnterior,
      'pesoNovo': pesoNovo,
      'dataAlteracao': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('historico_peso')
        .add(historicoPesoData);
    
    AppLogger.info('💾 Histórico de peso salvo - Anterior: $pesoAnterior kg → Novo: $pesoNovo kg');
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

      AppLogger.info('Carregando vacas para o usuário: ${user.uid}');
      AppLogger.info('Número de vacas encontradas: ${snapshot.docs.length}');

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
      AppLogger.error('Erro ao carregar vacas: $e');
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
            Text(
              '⚠️ Isso também removerá:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
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
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;
                
                // Mostrar loading
                showDialog(
                  context: dialogContext,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                // 1. Excluir registros de produção
                final producaoSnapshot = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .collection('registros_producao')
                    .where('vaca_id', isEqualTo: vaca['id'])
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

                // Limpeza automática de órfãos relacionados à vaca deletada
                await OrphanCleanupService.cleanupAfterCowDeletion(
                  vaca['id'], 
                  user.uid,
                );

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
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                );
              } catch (e) {
                // Fechar loading se ainda estiver aberto
                navigator.pop();
                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erro ao excluir: $e'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            },
            child: Text(
              'Remover Tudo',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
              backgroundColor: Theme.of(context).colorScheme.tertiary,
            ),
          );
          await _loadVacas();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao promover animal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class VacaDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> vaca;

  const VacaDetailsDialog({super.key, required this.vaca});

  @override
  State<VacaDetailsDialog> createState() => _VacaDetailsDialogState();
}

class _VacaDetailsDialogState extends State<VacaDetailsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _registrosProducao = [];
  List<Map<String, dynamic>> _registrosSaude = [];
  List<Map<String, dynamic>> _registrosCiclo = [];
  List<Map<String, dynamic>> _historicoPeso = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadRegistros();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRegistros() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print('🔍 Iniciando busca de registros para vaca: ${widget.vaca['id']}');
      print('🔍 User ID: ${user.uid}');

      // Buscar todos os registros desta vaca na subcoleção correta
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_producao')
          .where('vaca_id', isEqualTo: widget.vaca['id'])
          .get();

      print('🔍 Total de registros encontrados: ${snapshot.docs.length}');

      List<Map<String, dynamic>> producao = [];
      List<Map<String, dynamic>> saude = [];
      List<Map<String, dynamic>> ciclo = [];

      for (var doc in snapshot.docs) {
        final data = {...doc.data(), 'id': doc.id};
        final tipo = data['tipo'] as String?;
        
        print('🔍 Registro encontrado - Tipo: $tipo, Data: ${data['data']}, VacaId: ${data['vaca_id']}');

        switch (tipo) {
          case 'Leite':
            producao.add(data);
            print('📊 Adicionado à produção: quantidade=${data['quantidade']}');
            break;
          case 'Saúde':
            saude.add(data);
            print('🏥 Adicionado à saúde: observacao=${data['observacao']}');
            break;
          case 'Ciclo':
            ciclo.add(data);
            print('🔄 Adicionado ao ciclo: periodo=${data['periodoCiclo']}');
            break;
        }
      }

      print('📊 Total produção: ${producao.length}');
      print('🏥 Total saúde: ${saude.length}');
      print('🔄 Total ciclo: ${ciclo.length}');

      // Buscar histórico de peso (usando apenas um filtro para evitar índice composto)
      final historicoPesoSnapshot = await FirebaseFirestore.instance
          .collection('historico_peso')
          .where('userId', isEqualTo: user.uid)
          .get();

      List<Map<String, dynamic>> historicoPeso = [];
      for (var doc in historicoPesoSnapshot.docs) {
        final data = {...doc.data(), 'id': doc.id};
        // Filtrar por vaca_id no lado do cliente
        if (data['vaca_id'] == widget.vaca['id']) {
          historicoPeso.add(data);
        }
      }
      
      // Ordenar no lado do cliente por dataAlteracao (mais recente primeiro)
      historicoPeso.sort((a, b) {
        final timestampA = a['dataAlteracao'] as Timestamp?;
        final timestampB = b['dataAlteracao'] as Timestamp?;
        if (timestampA == null || timestampB == null) return 0;
        return timestampB.compareTo(timestampA);
      });
      
      print('⚖️ Total histórico de peso: ${historicoPeso.length}');

      if (mounted) {
        setState(() {
          _registrosProducao = producao;
          _registrosSaude = saude;
          _registrosCiclo = ciclo;
          _historicoPeso = historicoPeso;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('❌ Erro ao carregar registros: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vaca = widget.vaca;
    final tipo = vaca['tipo'] ?? 'vaca';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Icon(
                      _getTypeIcon(tipo),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vaca['nome'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_formatTipo(tipo)} • ${vaca['raca']}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                ],
              ),
            ),
            // Informações básicas
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInfoCard('Idade', '${vaca['idade']} anos', Icons.cake),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard('Peso', '${vaca['peso']} kg', Icons.monitor_weight),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoCard(
                      'Status',
                      vaca['lactacao'] == true ? 'Lactação' : 'Seca',
                      vaca['lactacao'] == true ? Icons.water_drop : Icons.block,
                    ),
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Geral'),
                Tab(text: 'Produção'),
                Tab(text: 'Saúde'),
                Tab(text: 'Ciclo'),
                Tab(text: 'Peso'),
              ],
            ),
            // Conteúdo das tabs
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeralTab(),
                  _buildProducaoTab(),
                  _buildSaudeTab(),
                  _buildCicloTab(),
                  _buildPesoTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeralTab() {
    final vaca = widget.vaca;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações Genealógicas',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Nome', vaca['nome']),
          _buildDetailRow('Raça', vaca['raca']),
          _buildDetailRow('Tipo', _formatTipo(vaca['tipo'] ?? 'vaca')),
          _buildDetailRow('Idade', '${vaca['idade']} anos'),
          _buildDetailRow('Peso', '${vaca['peso']} kg'),
          if (vaca['mae'] != null && vaca['mae'].toString().isNotEmpty)
            _buildDetailRow('Mãe', vaca['mae']),
          if (vaca['pai'] != null && vaca['pai'].toString().isNotEmpty)
            _buildDetailRow('Pai', vaca['pai']),
          _buildDetailRow('Status Reprodutivo', vaca['status_reprodutivo'] ?? 'Não definido'),
          _buildDetailRow('Em Lactação', vaca['lactacao'] == true ? 'Sim' : 'Não'),
        ],
      ),
    );
  }

  Widget _buildProducaoTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_registrosProducao.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Nenhum registro de produção encontrado'),
          ],
        ),
      );
    }

    // Calcular estatísticas
    double totalProducao = 0;
    double mediaProducao = 0;
    double maiorProducao = 0;

    for (var registro in _registrosProducao) {
      final quantidade = (registro['quantidade'] as num?)?.toDouble() ?? 0;
      totalProducao += quantidade;
      if (quantidade > maiorProducao) maiorProducao = quantidade;
    }

    mediaProducao = _registrosProducao.isNotEmpty ? totalProducao / _registrosProducao.length : 0;

    return Column(
      children: [
        // Estatísticas
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard('Total', '${totalProducao.toStringAsFixed(1)}L', Icons.opacity),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Média', '${mediaProducao.toStringAsFixed(1)}L', Icons.trending_up),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Maior', '${maiorProducao.toStringAsFixed(1)}L', Icons.star),
              ),
            ],
          ),
        ),
        const Divider(),
        // Lista de registros
        Expanded(
          child: ListView.builder(
            itemCount: _registrosProducao.length,
            itemBuilder: (context, index) {
              final registro = _registrosProducao[index];
              final data = registro['data'];
              if (data == null) return const SizedBox(); // Pular registros sem data
              final dataHora = (data as Timestamp).toDate();
              final quantidade = (registro['quantidade'] as num?)?.toDouble() ?? 0;

              return ListTile(
                leading: Icon(Icons.water_drop, color: Theme.of(context).colorScheme.primary),
                title: Text('${quantidade.toStringAsFixed(1)} litros'),
                subtitle: Text('${dataHora.day}/${dataHora.month}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}'),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSaudeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_registrosSaude.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.health_and_safety_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Nenhum registro de saúde encontrado'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registrosSaude.length,
      itemBuilder: (context, index) {
        final registro = _registrosSaude[index];
        final data = registro['data'];
        if (data == null) return const SizedBox(); // Pular registros sem data
        final dataHora = (data as Timestamp).toDate();
        final observacao = registro['observacao'] ?? '';

        return Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: ListTile(
            leading: Icon(Icons.health_and_safety, color: Theme.of(context).colorScheme.error),
            title: Text(observacao),
            subtitle: Text('${dataHora.day}/${dataHora.month}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}'),
          ),
        );
      },
    );
  }

  Widget _buildCicloTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_registrosCiclo.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.autorenew_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            const Text('Nenhum registro de ciclo encontrado'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _registrosCiclo.length,
      itemBuilder: (context, index) {
        final registro = _registrosCiclo[index];
        final data = registro['data'];
        if (data == null) return const SizedBox(); // Pular registros sem data
        final dataHora = (data as Timestamp).toDate();
        final periodoCiclo = registro['periodoCiclo'] ?? '';
        final observacao = registro['observacao'] ?? '';

        return Card(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: ListTile(
            leading: Icon(_getCicloIcon(periodoCiclo), color: _getCicloColor(periodoCiclo)),
            title: Text(periodoCiclo),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${dataHora.day}/${dataHora.month}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}'),
                if (observacao.isNotEmpty) Text(observacao),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPesoTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Peso atual
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.monitor_weight, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 32),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Peso Atual',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${widget.vaca['peso']} kg',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Título do histórico
          Text(
            'Histórico de Alterações',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // Lista de histórico
          Expanded(
            child: _historicoPeso.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma alteração de peso registrada',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _historicoPeso.length,
                    itemBuilder: (context, index) {
                      final historico = _historicoPeso[index];
                      final dataAlteracao = historico['dataAlteracao'] != null
                          ? (historico['dataAlteracao'] as Timestamp).toDate()
                          : DateTime.now();
                      final pesoAnterior = historico['pesoAnterior'] as String;
                      final pesoNovo = historico['pesoNovo'] as String;
                      
                      final diferenca = (double.tryParse(pesoNovo) ?? 0) - 
                                       (double.tryParse(pesoAnterior) ?? 0);
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: diferenca >= 0 
                                ? Theme.of(context).colorScheme.tertiaryContainer
                                : Theme.of(context).colorScheme.errorContainer,
                            child: Icon(
                              diferenca >= 0 ? Icons.trending_up : Icons.trending_down,
                              color: diferenca >= 0 
                                  ? Theme.of(context).colorScheme.onTertiaryContainer
                                  : Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '$pesoAnterior kg',
                                style: TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$pesoNovo kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${dataAlteracao.day}/${dataAlteracao.month}/${dataAlteracao.year} às '
                                '${dataAlteracao.hour.toString().padLeft(2, '0')}:'
                                '${dataAlteracao.minute.toString().padLeft(2, '0')}',
                              ),
                              Text(
                                '${diferenca >= 0 ? '+' : ''}${diferenca.toStringAsFixed(1)} kg',
                                style: TextStyle(
                                  color: diferenca >= 0 
                                      ? Theme.of(context).colorScheme.tertiary
                                      : Theme.of(context).colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
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

  String _formatTipo(String tipo) {
    switch (tipo) {
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

  IconData _getCicloIcon(String periodo) {
    switch (periodo.toLowerCase()) {
      case 'cio':
        return Icons.favorite;
      case 'cobertura':
      case 'inseminação':
        return Icons.male;
      case 'prenhez confirmada':
      case 'gestação':
        return Icons.pregnant_woman;
      case 'parto':
        return Icons.child_care;
      case 'seca':
        return Icons.block;
      default:
        return Icons.autorenew;
    }
  }

  Color _getCicloColor(String periodo) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (periodo.toLowerCase()) {
      case 'cio':
        return colorScheme.error;
      case 'cobertura':
      case 'inseminação':
        return colorScheme.primary;
      case 'prenhez confirmada':
      case 'gestação':
        return colorScheme.tertiary;
      case 'parto':
        return colorScheme.secondary;
      case 'seca':
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.outline;
    }
  }
}

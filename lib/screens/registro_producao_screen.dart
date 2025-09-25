import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/plan_validation_service.dart';
import '../services/user_service.dart';
import '../utils/app_logger.dart';

class RegistroProducaoScreen extends StatefulWidget {
  final VoidCallback? onNavigateToVacas;

  const RegistroProducaoScreen({super.key, this.onNavigateToVacas});

  @override
  State<RegistroProducaoScreen> createState() => _RegistroProducaoScreenState();
}

class _RegistroProducaoScreenState extends State<RegistroProducaoScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  final _vacaController = TextEditingController();
  final _observacaoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedTipo = 'Leite';
  String _selectedPeriodoCiclo = 'Cio';
  List<Map<String, dynamic>> _vacas = [];
  String? _selectedVacaId;
  bool _isRefreshing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadVacas();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quantidadeController.dispose();
    _vacaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Recarregar a lista quando o app voltar ao foco
      _loadVacas();
    }
  }

  Future<void> _loadVacas() async {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      AppLogger.info('Carregando vacas para o usuário: ${user.uid}');
      final snapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .where('userId', isEqualTo: user.uid)
          .get();

      AppLogger.info('Número de vacas encontradas: ${snapshot.docs.length}');

      if (mounted) {
        setState(() {
          _vacas = snapshot.docs.map((doc) {
            final data = {'id': doc.id, ...doc.data()};
            AppLogger.info('Vaca carregada: ${data['nome']} (ID: ${data['id']})');
            return data;
          }).toList();
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar vacas: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Produção'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadVacas,
            tooltip: 'Atualizar lista de vacas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Aviso quando lista está sendo carregada
              if (_isRefreshing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Atualizando lista de vacas...'),
                    ],
                  ),
                ),

              // Aviso quando não há vacas cadastradas
              if (!_isRefreshing && _vacas.isEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700], size: 32),
                      const SizedBox(height: 8),
                      const Text(
                        'Nenhuma vaca cadastrada',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Você precisa cadastrar pelo menos uma vaca antes de fazer registros de produção.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navega para a tela de cadastro de vacas (índice 2 no bottom navigation)
                          if (widget.onNavigateToVacas != null) {
                            widget.onNavigateToVacas!();
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Cadastrar Nova Vaca'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma vaca cadastrada',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você precisa cadastrar pelo menos uma vaca antes de fazer registros de produção.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).pop(); // Voltar para tela anterior
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Voltar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[100],
                          foregroundColor: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                ),

              DropdownButtonFormField<String>(
                value: _selectedTipo,
                items: ['Leite', 'Saúde', 'Ciclo']
                    .map(
                      (tipo) =>
                          DropdownMenuItem(value: tipo, child: Text(tipo)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedTipo = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Tipo de Registro',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedVacaId,
                items: _vacas.isEmpty
                    ? []
                    : _vacas.map((vaca) {
                        return DropdownMenuItem<String>(
                          value: vaca['id'],
                          child: Text('${vaca['nome']} - ${vaca['raca']}'),
                        );
                      }).toList(),
                onChanged: _vacas.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedVacaId = value;
                          final selectedVaca = _vacas.firstWhere(
                            (vaca) => vaca['id'] == value,
                          );
                          _vacaController.text = selectedVaca['nome'];
                        });
                      },
                decoration: InputDecoration(
                  labelText: 'Identificação da Vaca',
                  border: const OutlineInputBorder(),
                  helperText: _vacas.isEmpty ? 'Nenhuma vaca encontrada' : null,
                ),
                validator: (value) {
                  if (_vacas.isEmpty) {
                    return 'Nenhuma vaca cadastrada. Cadastre uma vaca primeiro.';
                  }
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma vaca';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedTipo == 'Leite')
                TextFormField(
                  controller: _quantidadeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Quantidade (litros)',
                    border: OutlineInputBorder(),
                    suffixText: 'L',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a quantidade';
                    }
                    final quantidade = double.tryParse(
                      value.replaceAll(',', '.'),
                    );
                    if (quantidade == null) {
                      return 'Por favor, insira um número válido';
                    }
                    if (quantidade <= 0) {
                      return 'A quantidade deve ser maior que zero';
                    }
                    if (quantidade > 100) {
                      return 'Quantidade muito alta. Verifique o valor.';
                    }
                    return null;
                  },
                ),
              if (_selectedTipo != 'Leite')
                TextFormField(
                  controller: _observacaoController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _selectedTipo == 'Saúde'
                        ? 'Observações de Saúde'
                        : 'Detalhes do Ciclo',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, preencha este campo';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              if (_selectedTipo == 'Ciclo')
                DropdownButtonFormField<String>(
                  value: _selectedPeriodoCiclo,
                  items:
                      [
                            'Cio',
                            'Cobertura',
                            'Prenhez Confirmada',
                            'Seca',
                            'Parto',
                          ]
                          .map(
                            (periodo) => DropdownMenuItem(
                              value: periodo,
                              child: Text(periodo),
                            ),
                          )
                          .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriodoCiclo = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Período do Ciclo',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Data',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Hora',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: Consumer<UserSubscription>(
                  builder: (context, subscription, _) {
                    return ElevatedButton(
                      onPressed: _isSaving ? null : () => _submitForm(subscription),
                      child: _isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Salvando...'),
                              ],
                            )
                          : const Text('Salvar Registro'),
                      );
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitForm(UserSubscription subscription) async {
    print('🚀 [DEBUG] Iniciando submissão do formulário...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ [DEBUG] Validação do formulário falhou');
      return;
    }

    if (_isSaving) {
      print('⚠️ [DEBUG] Já salvando - evitando duplo clique');
      return; // Evitar duplo clique
    }

    print('📝 [DEBUG] Tipo selecionado: $_selectedTipo');

    // Verificar limitações do plano apenas para registros de produção
    if (_selectedTipo == 'Leite') {
      print('🔍 [DEBUG] Verificando limitações do plano...');
      final canAdd = await PlanValidationService.canAddProductionRecord(context, subscription);
      print('✅ [DEBUG] Resultado da validação: $canAdd');
      if (!canAdd) {
        print('🚫 [DEBUG] Validação falhou - cancelando submissão');
        return;
      }
    }

    print('💾 [DEBUG] Iniciando salvamento...');
    setState(() {
      _isSaving = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro: Usuário não autenticado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final dataHora = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      print('📅 [DEBUG] Data/hora sendo salva: $dataHora');
      print('🔍 [DEBUG] Timestamp: ${Timestamp.fromDate(dataHora)}');
      
      final registroData = {
        'vaca_id': _selectedVacaId!, // Corrigir nome do campo
        'tipo': _selectedTipo,
        'data': Timestamp.fromDate(dataHora), // Corrigir nome do campo
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedTipo == 'Leite') {
        // Tratar vírgula como separador decimal para brasileiro
        final quantidadeText = _quantidadeController.text.replaceAll(',', '.');
        final quantidade = double.tryParse(quantidadeText);
        if (quantidade == null) {
          throw Exception('Quantidade inválida');
        }
        registroData['quantidade'] = quantidade;
      } else {
        registroData['observacao'] = _observacaoController.text;
        if (_selectedTipo == 'Ciclo') {
          registroData['periodoCiclo'] = _selectedPeriodoCiclo;
        }
      }

      print('💾 [DEBUG] Salvando registro no Firestore...');
      print('📊 [DEBUG] Dados do registro:');
      print('  - Usuário: ${user.uid}');
      print('  - Vaca ID: ${_selectedVacaId}');
      print('  - Tipo: ${_selectedTipo}');
      print('  - Data/Hora: $dataHora');
      print('  - Timestamp: ${Timestamp.fromDate(dataHora)}');
      print('  - Caminho: usuarios/${user.uid}/registros_producao');

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_producao')
          .add(registroData);
          
      print('✅ [DEBUG] Registro salvo com sucesso no Firestore!');
      print('🔍 [DEBUG] Caminho final: usuarios/${user.uid}/registros_producao/{doc_id}');

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Forçar atualização dos relatórios usando callback simples
      try {
        print('🔄 [REGISTRO] Solicitando atualização dos relatórios...');
        // Aguardar um pouco antes de tentar recarregar para garantir que o Firestore processou
        Future.delayed(const Duration(milliseconds: 500), () {
          // Aqui vamos implementar uma solução mais robusta
          print('✅ [REGISTRO] Dados salvos com sucesso, relatórios devem ser atualizados automaticamente');
        });
      } catch (e) {
        print('❌ [REGISTRO] Erro ao processar callback de atualização: $e');
      }

      // Limpar formulário
      _quantidadeController.clear();
      _observacaoController.clear();
      setState(() {
        _selectedVacaId = null;
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedTipo = 'Leite';
        _selectedPeriodoCiclo = 'Cio';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar registro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

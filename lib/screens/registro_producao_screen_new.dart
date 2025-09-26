import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroProducaoScreen extends StatefulWidget {
  const RegistroProducaoScreen({super.key});

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
      final snapshot =
          await FirebaseFirestore.instance.collection('vacas').get();
      if (mounted) {
        setState(() {
          _vacas = snapshot.docs.map((doc) {
            return {'id': doc.id, ...doc.data()};
          }).toList();
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar vacas: $e')),
        );
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
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
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
                items: _vacas.map((vaca) {
                  return DropdownMenuItem<String>(
                    value: vaca['id'],
                    child: Text('${vaca['nome']} - ${vaca['raca']}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedVacaId = value;
                    final selectedVaca =
                        _vacas.firstWhere((vaca) => vaca['id'] == value);
                    _vacaController.text = selectedVaca['nome'];
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Identificação da Vaca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
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
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade (litros)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe a quantidade';
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
                  items: [
                    'Cio',
                    'Cobertura',
                    'Prenhez Confirmada',
                    'Seca',
                    'Parto',
                  ]
                      .map((periodo) => DropdownMenuItem(
                          value: periodo, child: Text(periodo),),)
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
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Salvar Registro'),
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final dataHora = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      final registroData = {
        'vacaId': _selectedVacaId!,
        'tipo': _selectedTipo,
        'dataHora': Timestamp.fromDate(dataHora),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedTipo == 'Leite') {
        registroData['quantidade'] = double.parse(_quantidadeController.text);
      } else {
        registroData['observacao'] = _observacaoController.text;
        if (_selectedTipo == 'Ciclo') {
          registroData['periodoCiclo'] = _selectedPeriodoCiclo;
        }
      }

      await FirebaseFirestore.instance
          .collection('registros_producao')
          .add(registroData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar registro: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

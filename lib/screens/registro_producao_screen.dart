import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'atividades_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroProducaoScreen extends StatefulWidget {
  const RegistroProducaoScreen({super.key});

  @override
  State<RegistroProducaoScreen> createState() => _RegistroProducaoScreenState();
}

class _RegistroProducaoScreenState extends State<RegistroProducaoScreen> {
  Future<void> salvarRegistroProducao({
    required String vacaId,
    required double quantidade,
    required DateTime dataHora,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('registros_producao').add({
        'vacaId': vacaId,
        'quantidade': quantidade,
        'dataHora': Timestamp.fromDate(dataHora),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

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

  @override
  void initState() {
    super.initState();
    _loadVacas();
  }

  Future<void> _loadVacas() async {
    final snapshot = await FirebaseFirestore.instance.collection('vacas').get();
    setState(() {
      _vacas = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _vacaController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Produção')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                    final selectedVaca = _vacas.firstWhere((vaca) => vaca['id'] == value);
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
                    'Prenhez Avançada',
                    'Parto',
                    'Pós-Parto',
                    'Lactação',
                    'Secagem'
                  ].map((periodo) => DropdownMenuItem(
                        value: periodo,
                        child: Text(periodo),
                      )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriodoCiclo = value!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Período do Ciclo Reprodutivo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione o período do ciclo';
                    }
                    return null;
                  },
                ),
              if (_selectedTipo == 'Ciclo') const SizedBox(height: 16),
              ListTile(
                title: const Text('Data'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('Horário'),
                subtitle: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      _selectedTime = time;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final messenger = ScaffoldMessenger.of(context);
                    
                    // Verificação adicional para _selectedVacaId
                    if (_selectedVacaId == null || _selectedVacaId!.isEmpty) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Por favor, selecione uma vaca!'),
                        ),
                      );
                      return;
                    }
                    
                    if (_selectedTipo == 'Leite') {
                      try {
                        final quantidade = double.tryParse(
                          _quantidadeController.text,
                        );
                        if (quantidade == null) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Quantidade inválida!'),
                            ),
                          );
                          return;
                        }
                        
                        final dataHoraCompleta = DateTime(
                          _selectedDate.year,
                          _selectedDate.month,
                          _selectedDate.day,
                          _selectedTime.hour,
                          _selectedTime.minute,
                        );
                        
                        await salvarRegistroProducao(
                          vacaId: _selectedVacaId!,
                          quantidade: quantidade,
                          dataHora: dataHoraCompleta,
                        );
                        
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Registro salvo com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Limpar o formulário
                        _quantidadeController.clear();
                        _selectedVacaId = null;
                        _vacaController.clear();
                        setState(() {
                          _selectedDate = DateTime.now();
                          _selectedTime = TimeOfDay.now();
                          _selectedTipo = 'Leite';
                          _selectedPeriodoCiclo = 'Cio';
                        });
                        
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar registro: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      try {
                        // Mantém o comportamento anterior para Saúde/Ciclo
                        final repo = Provider.of<AtividadesRepository>(
                          context,
                          listen: false,
                        );
                        
                        final atividade = Activity(
                          name: _selectedTipo == 'Saúde'
                              ? 'Saúde: ${_vacaController.text} - ${_observacaoController.text}'
                              : 'Ciclo: ${_vacaController.text} - $_selectedPeriodoCiclo - ${_observacaoController.text}',
                          time: _selectedTime,
                          category: _selectedTipo,
                        );
                        
                        repo.addAtividade(_selectedDate, atividade);
                        
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Registro salvo com sucesso!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        
                        // Limpar o formulário
                        _observacaoController.clear();
                        _selectedVacaId = null;
                        _vacaController.clear();
                        setState(() {
                          _selectedDate = DateTime.now();
                          _selectedTime = TimeOfDay.now();
                          _selectedTipo = 'Leite';
                          _selectedPeriodoCiclo = 'Cio';
                        });
                        
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar registro: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Salvar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

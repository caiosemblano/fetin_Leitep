import 'package:fetin/screens/atividades_screen.dart';
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
        'dataHora': dataHora,
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
              TextFormField(
                controller: _vacaController,
                decoration: const InputDecoration(
                  labelText: 'Identificação da Vaca',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe a vaca';
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
                    if (_selectedTipo == 'Leite') {
                      try {
                        final quantidade = double.tryParse(
                          _quantidadeController.text,
                        );
                        if (quantidade == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quantidade inválida!'),
                            ),
                          );
                          return;
                        }
                        await salvarRegistroProducao(
                          vacaId: _vacaController.text,
                          quantidade: quantidade,
                          dataHora: DateTime(
                            _selectedDate.year,
                            _selectedDate.month,
                            _selectedDate.day,
                            _selectedTime.hour,
                            _selectedTime.minute,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registro salvo com sucesso!'),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar registro: $e'),
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
                              : 'Ciclo: ${_vacaController.text} - ${_observacaoController.text}',
                          time: _selectedTime,
                          category: _selectedTipo,
                        );
                        repo.addAtividade(_selectedDate, atividade);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registro salvo com sucesso!'),
                          ),
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Erro ao salvar registro: $e'),
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

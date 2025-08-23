import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'atividades_repository.dart';

class AtividadesScreen extends StatefulWidget {
  const AtividadesScreen({super.key});

  @override
  State<AtividadesScreen> createState() => _AtividadesScreenState();
}

class _AtividadesScreenState extends State<AtividadesScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final Map<String, Color> _categories = {
    'Ordenha': Colors.blue,
    'Saúde': Colors.green,
    'Reprodução': Colors.purple,
  };

  @override
  Widget build(BuildContext context) {
    final repo = Provider.of<AtividadesRepository>(context);
    final activities = _selectedDay != null ? repo.getAtividadesDoDia(_selectedDay!) : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Atividades'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            onFormatChanged: (format) {
              setState(() => _calendarFormat = format);
            },
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: repo.getAtividadesDoDia,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Color.fromRGBO(33, 150, 243, 0.3),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _selectedDay == null
                ? const Center(child: Text('Selecione um dia no calendário'))
                : activities.isEmpty
                    ? const Center(child: Text('Nenhuma atividade para este dia'))
                    : ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          final activity = activities[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _categories[activity.category],
                                child: const Icon(Icons.event,
                                    color: Colors.white),
                              ),
                              title: Text(activity.name),
                              subtitle: Text(
                                  '${activity.time.format(context)} - ${activity.category}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () => repo.removeAtividade(
                                    _selectedDay!, activity),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivityDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context) {
    final repo = Provider.of<AtividadesRepository>(context, listen: false);
    final nameController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    String selectedCategory = 'Ordenha';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Atividade'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Atividade',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Horário'),
                      subtitle: Text(selectedTime.format(context)),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (time != null) {
                          setState(() => selectedTime = time);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: _categories.keys
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedCategory = value!);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty) {
                      final activity = Activity(
                        name: nameController.text,
                        time: selectedTime,
                        category: selectedCategory,
                      );
                      repo.addAtividade(_selectedDay ?? DateTime.now(), activity);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
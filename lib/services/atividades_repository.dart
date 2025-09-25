import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class Activity {
  final String name;
  final TimeOfDay time;
  final String category;

  Activity({
    required this.name,
    required this.time,
    required this.category,
  });
}

class AtividadesRepository extends ChangeNotifier {
  final Map<DateTime, List<Activity>> _activities = {};

  List<Activity> getAtividadesDoDia(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return _activities[normalizedDate] ?? [];
  }

  List<Activity> getAtividadesPorCategoria(String categoria) {
    return _activities.values
        .expand((list) => list)
        .where((activity) => activity.category == categoria)
        .toList();
  }

  List<Activity> getTodasAtividades() {
    return _activities.values.expand((list) => list).toList();
  }

  void addAtividade(DateTime date, Activity activity) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _activities.putIfAbsent(normalizedDate, () => []).add(activity);
    
    // Notificação imediata confirmando criação da atividade
    NotificationService.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch,
      title: '✅ Atividade Criada',
      body: '${activity.name} agendada para ${_formatDate(normalizedDate)} às ${_formatTime(activity.time)}',
      payload: 'atividade_criada_${activity.hashCode}',
    );
    
    notifyListeners();
  }

  void removeAtividade(DateTime date, Activity activity) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _activities[normalizedDate]?.remove(activity);
    notifyListeners();
  }

  String _formatDate(DateTime date) {
    final hoje = DateTime.now();
    final amanha = hoje.add(const Duration(days: 1));
    
    if (date.year == hoje.year && date.month == hoje.month && date.day == hoje.day) {
      return 'hoje';
    } else if (date.year == amanha.year && date.month == amanha.month && date.day == amanha.day) {
      return 'amanhã';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

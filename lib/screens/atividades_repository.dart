import 'package:flutter/material.dart';
import 'atividades_screen.dart';
import '../services/notification_service.dart';

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
    
    // Se a atividade é para hoje ou no futuro, criar notificação
    final hoje = DateTime.now();
    final hojeNormalizado = DateTime(hoje.year, hoje.month, hoje.day);
    
    if (normalizedDate.isAfter(hojeNormalizado) || 
        normalizedDate.isAtSameMomentAs(hojeNormalizado)) {
      
      final dataHoraAtividade = DateTime(
        normalizedDate.year,
        normalizedDate.month,
        normalizedDate.day,
        activity.time.hour,
        activity.time.minute,
      );
      
      // Criar notificação 30 minutos antes da atividade
      final notificationTime = dataHoraAtividade.subtract(const Duration(minutes: 30));
      
      if (notificationTime.isAfter(DateTime.now())) {
        NotificationService.scheduleNotification(
          id: activity.hashCode, // Usar hash como ID único
          title: '⏰ Atividade Programada',
          body: '${activity.name} em 30 minutos',
          scheduledDate: notificationTime,
          payload: 'atividade_${activity.hashCode}',
        );
      }
    }
    
    notifyListeners();
  }

  void removeAtividade(DateTime date, Activity activity) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _activities[normalizedDate]?.remove(activity);
    
    // Cancelar notificação relacionada à atividade
    NotificationService.cancelNotification(activity.hashCode);
    
    notifyListeners();
  }
}
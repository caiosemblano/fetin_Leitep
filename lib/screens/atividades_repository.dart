import 'package:flutter/material.dart';
import 'atividades_screen.dart';

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
    notifyListeners();
  }

  void removeAtividade(DateTime date, Activity activity) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _activities[normalizedDate]?.remove(activity);
    notifyListeners();
  }
}
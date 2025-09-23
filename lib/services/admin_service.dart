import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getAllUsersWithPlans() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      List<Map<String, dynamic>> usersWithPlans = [];

      for (var doc in usersSnapshot.docs) {
        final userData = doc.data();
        final subscription =
            userData['subscription'] ?? {'plan': 'basic', 'status': 'active'};

        usersWithPlans.add({
          'userId': doc.id,
          'email': userData['email'] ?? 'Email não disponível',
          'name': userData['name'] ?? 'Nome não disponível',
          'plan': subscription['plan'] ?? 'basic',
          'status': subscription['status'] ?? 'active',
          'createdAt': userData['createdAt'] ?? Timestamp.now(),
        });
      }

      // Ordenar por data de criação, mais recentes primeiro
      usersWithPlans.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      return usersWithPlans;
    } catch (e) {
      AppLogger.error('Erro ao buscar usuários: $e');
      return [];
    }
  }
}

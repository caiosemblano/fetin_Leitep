import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSubscription {
  final String plan;
  final List<String> modules;
  final String status;

  UserSubscription({
    this.plan = 'basic', // Plano padrão é o básico
    this.modules = const [],
    this.status = 'active',
  });

  factory UserSubscription.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return UserSubscription();
    return UserSubscription(
      plan: data['plan'] ?? 'basic',
      status: data['status'] ?? 'active',
      modules: List<String>.from(data['modules'] ?? []),
    );
  }

  // Verificações de acesso
  bool get hasIntermediateAccess => plan == 'intermediario' || plan == 'premium';
  bool get hasPremiumAccess => plan == 'premium';
  bool hasModule(String moduleName) => modules.contains(moduleName);
}

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<UserSubscription> getSubscriptionStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(UserSubscription());

    return _db.collection('usuarios').doc(userId).snapshots().map((snapshot) {
      final data = snapshot.data();
      return UserSubscription.fromFirestore(data?['subscription']);
    });
  }
}


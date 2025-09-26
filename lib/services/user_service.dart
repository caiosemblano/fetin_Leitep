import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserSubscription {
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
  final String plan;
  final List<String> modules;
  final String status;

  // Verificações de acesso
  bool get hasIntermediateAccess =>
      plan == 'intermediario' || plan == 'premium';
  bool get hasPremiumAccess => plan == 'premium';
  bool hasModule(String moduleName) => modules.contains(moduleName);

  // Limitações por plano
  int get maxVacas {
    switch (plan) {
      case 'basic':
        return 5;
      case 'intermediario':
        return 50;
      case 'premium':
        return -1; // Ilimitado
      default:
        return 5;
    }
  }

  int get maxRegistrosProducaoPorMes {
    switch (plan) {
      case 'basic':
        return 30; // 1 por dia
      case 'intermediario':
        return 300; // ~10 por dia
      case 'premium':
        return -1; // Ilimitado
      default:
        return 30;
    }
  }

  bool get hasFinanceiroAccess => hasIntermediateAccess;
  bool get hasRelatoriosAvancados => hasIntermediateAccess;
  bool get hasBackupAutomatico => hasIntermediateAccess;
  bool get hasAnalisesPreditivas => hasPremiumAccess;
  bool get hasSuportePrioritario => hasPremiumAccess;
  bool get hasConsultoriaEspecializada => hasPremiumAccess;

  // Verificar se pode adicionar mais vacas
  bool canAddMoreCows(int currentCount) {
    if (maxVacas == -1) return true; // Ilimitado
    return currentCount < maxVacas;
  }

  // Verificar se pode fazer mais registros de produção
  bool canAddMoreProductionRecords(int currentMonthCount) {
    if (maxRegistrosProducaoPorMes == -1) return true; // Ilimitado
    return currentMonthCount < maxRegistrosProducaoPorMes;
  }

  // Mensagem de upgrade para funcionalidade bloqueada
  String getUpgradeMessage(String feature) {
    switch (plan) {
      case 'basic':
        return r'Esta funcionalidade está disponível no plano Intermediário (R$ 59,90/mês) ou Premium (R$ 109,90/mês).';
      case 'intermediario':
        return r'Esta funcionalidade está disponível apenas no plano Premium (R$ 109,90/mês).';
      default:
        return 'Upgrade necessário para acessar esta funcionalidade.';
    }
  }
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

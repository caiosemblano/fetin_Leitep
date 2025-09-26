import '../core/constants/app_constants.dart';

/// Modelo de dados para assinatura/plano do usuário
class UserSubscription {
  const UserSubscription({
    this.plan = PlanConstants.basicPlan,
    this.modules = const [],
    this.status = 'active',
    this.expiryDate,
    this.createdAt,
    this.updatedAt,
  });

  /// Cria uma instância a partir de dados do Firestore
  factory UserSubscription.fromFirestore(Map<String, dynamic>? data) {
    if (data == null) return const UserSubscription();

    return UserSubscription(
      plan: data['plan'] ?? PlanConstants.basicPlan,
      modules: List<String>.from(data['modules'] ?? []),
      status: data['status'] ?? 'active',
      expiryDate: data['expiryDate']?.toDate(),
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }
  final String plan;
  final List<String> modules;
  final String status;
  final DateTime? expiryDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'plan': plan,
      'modules': modules,
      'status': status,
      'expiryDate': expiryDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Cria uma cópia com campos atualizados
  UserSubscription copyWith({
    String? plan,
    List<String>? modules,
    String? status,
    DateTime? expiryDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      plan: plan ?? this.plan,
      modules: modules ?? this.modules,
      status: status ?? this.status,
      expiryDate: expiryDate ?? this.expiryDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Verificações de acesso
  bool get hasIntermediateAccess =>
      plan == PlanConstants.intermediatePlan ||
      plan == PlanConstants.premiumPlan;
  bool get hasPremiumAccess => plan == PlanConstants.premiumPlan;
  bool get isActive => status == 'active' && !isExpired;
  bool get isExpired => expiryDate?.isBefore(DateTime.now()) ?? false;

  /// Verifica se tem acesso a um módulo específico
  bool hasModule(String moduleName) => modules.contains(moduleName);

  /// Limitações por plano
  int get maxVacas => PlanConstants.cowLimits[plan] ?? 10;
  int get maxRegistrosProducaoPorMes =>
      PlanConstants.productionRecordLimits[plan] ?? 100;

  /// Funcionalidades por plano
  bool get hasFinanceiroAccess => hasIntermediateAccess;
  bool get hasRelatoriosAvancados => hasIntermediateAccess;
  bool get hasBackupAutomatico => hasIntermediateAccess;
  bool get hasAnalisesPreditivas => hasPremiumAccess;
  bool get hasSuportePrioritario => hasPremiumAccess;
  bool get hasConsultoriaEspecializada => hasPremiumAccess;

  /// Verificar se pode adicionar mais vacas
  bool canAddMoreCows(int currentCount) {
    if (maxVacas == -1) return true; // Ilimitado
    return currentCount < maxVacas;
  }

  /// Verificar se pode fazer mais registros de produção
  bool canAddMoreProductionRecords(int currentMonthCount) {
    if (maxRegistrosProducaoPorMes == -1) return true; // Ilimitado
    return currentMonthCount < maxRegistrosProducaoPorMes;
  }

  /// Mensagem de upgrade para funcionalidade bloqueada
  String getUpgradeMessage(String feature) {
    switch (plan) {
      case PlanConstants.basicPlan:
        return 'Esta funcionalidade requer o plano Intermediário ou Premium. Faça upgrade para acessar $feature.';
      case PlanConstants.intermediatePlan:
        return 'Esta funcionalidade é exclusiva do plano Premium. Faça upgrade para acessar $feature.';
      default:
        return 'Você tem acesso completo a todas as funcionalidades!';
    }
  }

  /// Nome do plano para exibição
  String get displayName {
    switch (plan) {
      case PlanConstants.basicPlan:
        return 'Básico';
      case PlanConstants.intermediatePlan:
        return 'Intermediário';
      case PlanConstants.premiumPlan:
        return 'Premium';
      default:
        return 'Desconhecido';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserSubscription &&
        other.plan == plan &&
        other.modules.length == modules.length &&
        other.modules.every(modules.contains) &&
        other.status == status &&
        other.expiryDate == expiryDate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      plan,
      modules,
      status,
      expiryDate,
      createdAt,
      updatedAt,
    );
  }
}

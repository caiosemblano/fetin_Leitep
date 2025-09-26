/// Constantes de configuração do Firebase
class FirebaseConstants {
  // Collections
  static const String usersCollection = 'usuarios';
  static const String cowsCollection = 'vacas';
  static const String productionCollection = 'registros_producao';
  static const String activitiesCollection = 'atividades';
  static const String backupsCollection = 'backups';
  static const String notificationsCollection = 'notifications';
  static const String healthCollection = 'saude';
  static const String cycleCollection = 'ciclo_reprodutivo';
  static const String financeCollection = 'financeiro';

  // Storage paths
  static const String backupStoragePath = 'backups';
  static const String profilePicturesPath = 'profile_pictures';
  static const String documentsPath = 'documents';

  // Query limits
  static const int defaultQueryLimit = 50;
  static const int maxQueryLimit = 100;
  static const int defaultPageSize = 20;
}

/// Constantes da aplicação
class AppConstants {
  // App info
  static const String appName = 'Leite+';
  static const String appVersion = '1.0.0';

  // Cache configuration
  static const Duration defaultCacheTtl = Duration(minutes: 5);
  static const Duration longCacheTtl = Duration(minutes: 30);
  static const Duration shortCacheTtl = Duration(minutes: 1);
  static const int maxCacheItems = 1000;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;

  // Validation
  static const int minPasswordLength = 6;
  static const int maxUsernameLength = 30;
  static const double minProductionValue = 0.0;
  static const double maxProductionValue = 100.0;

  // Notification channels
  static const String defaultNotificationChannelId = 'default_channel';
  static const String productionNotificationChannelId = 'production_channel';
  static const String healthNotificationChannelId = 'health_channel';
}

/// Constantes de planos de usuário
class PlanConstants {
  // Plan types
  static const String basicPlan = 'basic';
  static const String intermediatePlan = 'intermediario';
  static const String premiumPlan = 'premium';

  // Plan limits
  static const Map<String, int> cowLimits = {
    basicPlan: 10,
    intermediatePlan: 50,
    premiumPlan: -1, // Unlimited
  };

  static const Map<String, int> productionRecordLimits = {
    basicPlan: 100,
    intermediatePlan: 500,
    premiumPlan: -1, // Unlimited
  };

  // Plan features
  static const Map<String, List<String>> planFeatures = {
    basicPlan: ['basic_reports', 'cow_management', 'production_tracking'],
    intermediatePlan: ['advanced_reports', 'financial_tracking', 'backup'],
    premiumPlan: ['predictive_analytics', 'priority_support', 'consultation'],
  };
}

import 'package:flutter/foundation.dart';

/// Configurações específicas para cada ambiente
abstract class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  /// Ambiente atual
  static String get current {
    if (kDebugMode) return development;
    if (kProfileMode) return staging;
    return production;
  }

  /// Verifica se está em desenvolvimento
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;
}

/// Configuração da aplicação baseada no ambiente
class AppConfig {
  const AppConfig._({
    required this.appName,
    required this.baseUrl,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.enableAnalytics,
    required this.networkTimeout,
    required this.maxRetryAttempts,
    required this.cacheDefaultTtl,
    required this.enableOfflineMode,
    required this.buildVariant,
  });
  final String appName;
  final String baseUrl;
  final bool enableLogging;
  final bool enableCrashlytics;
  final bool enableAnalytics;
  final Duration networkTimeout;
  final int maxRetryAttempts;
  final Duration cacheDefaultTtl;
  final bool enableOfflineMode;
  final String buildVariant;

  /// Configuração para desenvolvimento
  static const AppConfig development = AppConfig._(
    appName: 'Leite+ Dev',
    baseUrl: 'https://api-dev.leitemais.com',
    enableLogging: true,
    enableCrashlytics: false,
    enableAnalytics: false,
    networkTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
    cacheDefaultTtl: Duration(minutes: 2),
    enableOfflineMode: true,
    buildVariant: 'development',
  );

  /// Configuração para staging
  static const AppConfig staging = AppConfig._(
    appName: 'Leite+ Staging',
    baseUrl: 'https://api-staging.leitemais.com',
    enableLogging: true,
    enableCrashlytics: true,
    enableAnalytics: false,
    networkTimeout: Duration(seconds: 30),
    maxRetryAttempts: 3,
    cacheDefaultTtl: Duration(minutes: 5),
    enableOfflineMode: true,
    buildVariant: 'staging',
  );

  /// Configuração para produção
  static const AppConfig production = AppConfig._(
    appName: 'Leite+',
    baseUrl: 'https://api.leitemais.com',
    enableLogging: false,
    enableCrashlytics: true,
    enableAnalytics: true,
    networkTimeout: Duration(seconds: 30),
    maxRetryAttempts: 5,
    cacheDefaultTtl: Duration(minutes: 10),
    enableOfflineMode: true,
    buildVariant: 'production',
  );

  /// Obtém a configuração baseada no ambiente atual
  static AppConfig get current {
    switch (Environment.current) {
      case Environment.development:
        return development;
      case Environment.staging:
        return staging;
      case Environment.production:
        return production;
      default:
        return development;
    }
  }

  /// Configurações do Firebase por ambiente
  FirebaseConfig get firebase {
    switch (buildVariant) {
      case 'development':
        return FirebaseConfig.development;
      case 'staging':
        return FirebaseConfig.staging;
      case 'production':
        return FirebaseConfig.production;
      default:
        return FirebaseConfig.development;
    }
  }

  @override
  String toString() => 'AppConfig(variant: $buildVariant, name: $appName)';
}

/// Configurações específicas do Firebase
class FirebaseConfig {
  const FirebaseConfig._({
    required this.projectId,
    required this.appId,
    required this.databaseUrl,
    required this.storageBucket,
    this.emulatorConfig = const {},
    this.useEmulators = false,
  });
  final String projectId;
  final String appId;
  final String databaseUrl;
  final String storageBucket;
  final Map<String, dynamic> emulatorConfig;
  final bool useEmulators;

  static const FirebaseConfig development = FirebaseConfig._(
    projectId: 'pleite-dev',
    appId: '1:123456789:android:abcdef123456',
    databaseUrl: 'https://pleite-dev-default-rtdb.firebaseio.com',
    storageBucket: 'pleite-dev.appspot.com',
    useEmulators: true,
    emulatorConfig: {
      'firestore': {'host': 'localhost', 'port': 8080},
      'auth': {'host': 'localhost', 'port': 9099},
      'storage': {'host': 'localhost', 'port': 9199},
    },
  );

  static const FirebaseConfig staging = FirebaseConfig._(
    projectId: 'pleite-staging',
    appId: '1:123456789:android:staging123456',
    databaseUrl: 'https://pleite-staging-default-rtdb.firebaseio.com',
    storageBucket: 'pleite-staging.appspot.com',
    useEmulators: false,
  );

  static const FirebaseConfig production = FirebaseConfig._(
    projectId: 'pleite-prod',
    appId: '1:123456789:android:prod123456',
    databaseUrl: 'https://pleite-prod-default-rtdb.firebaseio.com',
    storageBucket: 'pleite-prod.appspot.com',
    useEmulators: false,
  );
}

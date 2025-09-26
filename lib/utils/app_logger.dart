import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../core/config/app_config.dart';

/// Sistema centralizado de logging da aplicação
class AppLogger {
  static late Logger _logger;
  static bool _isInitialized = false;

  /// Inicializa o logger com configurações baseadas no ambiente
  static void initialize() {
    if (_isInitialized) return;

    final config = AppConfig.current;

    _logger = Logger(
      level: config.enableLogging ? Level.debug : Level.error,
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      filter: ProductionFilter(),
    );

    _isInitialized = true;
    info('🚀 AppLogger inicializado - Ambiente: ${Environment.current}');
  }

  /// Verifica se o logger está inicializado
  static void _ensureInitialized() {
    if (!_isInitialized) {
      initialize();
    }
  }

  /// Log de debug (apenas em desenvolvimento)
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    if (Environment.isDevelopment) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log de informação
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log de warning
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log de erro
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Em produção, enviar para serviço de crash reporting
    if (Environment.isProduction && AppConfig.current.enableCrashlytics) {
      _sendToCrashlytics(message, error, stackTrace);
    }
  }

  /// Log de erro fatal
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Sempre enviar erros fatais para crash reporting
    if (AppConfig.current.enableCrashlytics) {
      _sendToCrashlytics(message, error, stackTrace, isFatal: true);
    }
  }

  static void trace(String message) {
    _ensureInitialized();
    _logger.t(message);
  }

  /// Log de operações de rede
  static void network(
    String message, {
    String? method,
    String? url,
    int? statusCode,
    dynamic data,
  }) {
    _ensureInitialized();
    final logMessage =
        '🌐 [$method] $url ${statusCode != null ? '($statusCode)' : ''} - $message';

    if (statusCode != null && statusCode >= 400) {
      warning(logMessage, data);
    } else {
      info(logMessage, data);
    }
  }

  /// Log de operações do cache
  static void cache(String message, {String? key, String? operation}) {
    _ensureInitialized();
    if (Environment.isDevelopment) {
      debug(
          '💾 Cache${operation != null ? ' [$operation]' : ''} ${key ?? ''} - $message',);
    }
  }

  /// Log de operações do banco de dados
  static void database(String message,
      {String? collection, String? operation, String? documentId,}) {
    _ensureInitialized();
    final details = [
      if (operation != null) operation,
      if (collection != null) collection,
      if (documentId != null) documentId,
    ].join(' > ');

    info('🗄️ DB${details.isNotEmpty ? ' [$details]' : ''} - $message');
  }

  /// Envia erro para serviço de crash reporting (Firebase Crashlytics)
  static void _sendToCrashlytics(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    bool isFatal = false,
  }) {
    // TODO: Implementar integração com Firebase Crashlytics
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: isFatal);

    // Por enquanto, apenas log no console em produção se habilitado
    if (kDebugMode) {
      debugPrint('🔥 CRASHLYTICS ${isFatal ? '[FATAL]' : '[ERROR]'}: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}

/// Filtro customizado para logs em produção
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (Environment.isProduction) {
      // Em produção, apenas logs de warning, error e fatal
      return event.level.index >= Level.warning.index;
    }

    // Em desenvolvimento e staging, todos os logs
    return true;
  }
}

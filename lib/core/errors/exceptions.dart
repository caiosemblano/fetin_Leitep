/// Classe base para exceções customizadas da aplicação
abstract class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => 'AppException: $message';
}

/// Exceções relacionadas à rede
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Exceções relacionadas à autenticação
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Exceções relacionadas ao Firebase
class FirebaseException extends AppException {
  const FirebaseException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Exceções relacionadas à validação
class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
    super.stackTrace,
  });
  final Map<String, String>? fieldErrors;
}

/// Exceções relacionadas ao cache
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Exceções relacionadas a permissões
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Exceções relacionadas a planos/assinaturas
class SubscriptionException extends AppException {
  const SubscriptionException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

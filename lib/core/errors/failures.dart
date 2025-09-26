import 'package:flutter/foundation.dart';
import '../constants/ui_constants.dart';
import 'exceptions.dart';

/// Classe para representar falhas que podem ser mostradas ao usuário
class Failure {
  const Failure({
    required this.message,
    this.code,
    this.type = FailureType.generic,
  });

  factory Failure.network({String? message}) {
    return Failure(
      message: message ?? UIStrings.networkError,
      type: FailureType.network,
    );
  }

  factory Failure.auth({String? message}) {
    return Failure(
      message: message ?? UIStrings.authError,
      type: FailureType.auth,
    );
  }

  factory Failure.validation({String? message, String? code}) {
    return Failure(
      message: message ?? UIStrings.validationError,
      code: code,
      type: FailureType.validation,
    );
  }

  factory Failure.permission({String? message}) {
    return Failure(
      message: message ?? UIStrings.permissionError,
      type: FailureType.permission,
    );
  }

  factory Failure.generic({String? message}) {
    return Failure(
      message: message ?? UIStrings.genericError,
      type: FailureType.generic,
    );
  }
  final String message;
  final String? code;
  final FailureType type;

  @override
  String toString() => 'Failure: $message';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Failure &&
        other.message == message &&
        other.code == code &&
        other.type == type;
  }

  @override
  int get hashCode => message.hashCode ^ code.hashCode ^ type.hashCode;
}

/// Tipos de falhas possíveis
enum FailureType {
  network,
  auth,
  validation,
  permission,
  subscription,
  cache,
  firebase,
  generic,
}

/// Conversor de exceções para falhas
class FailureMapper {
  static Failure fromException(Object exception, [StackTrace? stackTrace]) {
    // Log da exceção em modo debug
    if (kDebugMode) {
      debugPrint('Exception: $exception');
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }

    if (exception is AppException) {
      return _mapAppException(exception);
    }

    // Exceções específicas do Firebase
    if (exception.toString().contains('firebase')) {
      return const Failure(
        message: 'Erro no servidor. Tente novamente.',
        type: FailureType.firebase,
      );
    }

    // Exceções de rede
    if (exception.toString().toLowerCase().contains('socket') ||
        exception.toString().toLowerCase().contains('network') ||
        exception.toString().toLowerCase().contains('connection')) {
      return Failure.network();
    }

    // Exceção genérica
    return Failure.generic();
  }

  static Failure _mapAppException(AppException exception) {
    switch (exception.runtimeType) {
      case NetworkException _:
        return Failure.network(message: exception.message);
      case AuthException _:
        return Failure.auth(message: exception.message);
      case ValidationException _:
        return Failure.validation(
          message: exception.message,
          code: exception.code,
        );
      case PermissionException _:
        return Failure.permission(message: exception.message);
      case SubscriptionException _:
        return Failure(
          message: exception.message,
          code: exception.code,
          type: FailureType.subscription,
        );
      case CacheException _:
        return Failure(
          message: exception.message,
          code: exception.code,
          type: FailureType.cache,
        );
      case FirebaseException _:
        return Failure(
          message: exception.message,
          code: exception.code,
          type: FailureType.firebase,
        );
      default:
        return Failure.generic(message: exception.message);
    }
  }
}

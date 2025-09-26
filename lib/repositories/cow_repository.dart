import '../models/cow.dart';
import '../core/errors/failures.dart';

/// Interface para repository de vacas
abstract class CowRepository {
  /// Busca todas as vacas do usuário
  Future<Either<Failure, List<Cow>>> getUserCows(String userId);

  /// Busca uma vaca específica
  Future<Either<Failure, Cow?>> getCowById(String cowId, String userId);

  /// Adiciona uma nova vaca
  Future<Either<Failure, String>> addCow(Cow cow);

  /// Atualiza uma vaca existente
  Future<Either<Failure, void>> updateCow(Cow cow);

  /// Remove uma vaca
  Future<Either<Failure, void>> deleteCow(String cowId, String userId);

  /// Busca vacas com filtros
  Future<Either<Failure, List<Cow>>> getCowsWithFilters({
    required String userId,
    String? status,
    String? tipo,
    bool? lactacao,
  });

  /// Conta o número de vacas do usuário
  Future<Either<Failure, int>> getUserCowCount(String userId);

  /// Stream de vacas do usuário (tempo real)
  Stream<Either<Failure, List<Cow>>> watchUserCows(String userId);
}

/// Tipo Either para representar resultado ou erro
sealed class Either<L, R> {
  const Either();
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;
}

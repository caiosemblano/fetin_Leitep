import '../models/production_record.dart';
import '../core/errors/failures.dart';
import 'cow_repository.dart'; // Para usar o Either

/// Interface para repository de produção
abstract class ProductionRepository {
  /// Busca todos os registros de produção do usuário
  Future<Either<Failure, List<ProductionRecord>>> getUserProductionRecords(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    String? lastDocumentId,
  });

  /// Busca registros de produção de uma vaca específica
  Future<Either<Failure, List<ProductionRecord>>> getCowProductionRecords(
    String cowId,
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Busca um registro específico
  Future<Either<Failure, ProductionRecord?>> getProductionRecordById(
    String recordId,
    String userId,
  );

  /// Adiciona um novo registro de produção
  Future<Either<Failure, String>> addProductionRecord(ProductionRecord record);

  /// Atualiza um registro existente
  Future<Either<Failure, void>> updateProductionRecord(ProductionRecord record);

  /// Remove um registro
  Future<Either<Failure, void>> deleteProductionRecord(
    String recordId,
    String userId,
  );

  /// Remove todos os registros de uma vaca
  Future<Either<Failure, void>> deleteCowProductionRecords(
    String cowId,
    String userId,
  );

  /// Busca estatísticas de produção
  Future<Either<Failure, ProductionStats>> getProductionStats(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    String? cowId,
  });

  /// Conta registros de produção do mês atual
  Future<Either<Failure, int>> getCurrentMonthProductionCount(String userId);

  /// Stream de registros de produção (tempo real)
  Stream<Either<Failure, List<ProductionRecord>>> watchUserProductionRecords(
    String userId, {
    int? limit,
  });
}

/// Estatísticas de produção
class ProductionStats {
  const ProductionStats({
    required this.totalProduction,
    required this.averageProduction,
    required this.recordCount,
    required this.maxProduction,
    required this.minProduction,
    required this.productionByPeriod,
    required this.productionByCow,
  });

  factory ProductionStats.empty() {
    return const ProductionStats(
      totalProduction: 0,
      averageProduction: 0,
      recordCount: 0,
      maxProduction: 0,
      minProduction: 0,
      productionByPeriod: {},
      productionByCow: {},
    );
  }
  final double totalProduction;
  final double averageProduction;
  final int recordCount;
  final double maxProduction;
  final double minProduction;
  final Map<String, double> productionByPeriod;
  final Map<String, double> productionByCow;
}

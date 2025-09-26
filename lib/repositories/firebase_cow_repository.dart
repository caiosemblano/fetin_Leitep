import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cow.dart';
import '../core/errors/failures.dart';
import '../utils/app_logger.dart';
import 'cow_repository.dart';

class FirebaseCowRepository implements CowRepository {
  const FirebaseCowRepository({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<Either<Failure, List<Cow>>> getUserCows(String userId) async {
    try {
      // Buscar na coleção de vacas
      final QuerySnapshot snapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Cow> cows = snapshot.docs
          .map((doc) =>
              Cow.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),)
          .toList();

      AppLogger.info('🐄 ${cows.length} vacas carregadas do Firebase');
      return Right(cows);
    } catch (e) {
      AppLogger.error('Erro ao buscar vacas', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao buscar vacas: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, String>> addCow(Cow cow) async {
    try {
      final DocumentReference docRef =
          await _firestore.collection('vacas').add(cow.toFirestore());

      AppLogger.info('🐄 Vaca adicionada: ${cow.nome} (ID: ${docRef.id})');
      return Right(docRef.id);
    } catch (e) {
      AppLogger.error('Erro ao adicionar vaca', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao adicionar vaca: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, void>> updateCow(Cow cow) async {
    try {
      await _firestore
          .collection('vacas')
          .doc(cow.id)
          .update(cow.toFirestore());

      AppLogger.info('🐄 Vaca atualizada: ${cow.nome}');
      return const Right(null);
    } catch (e) {
      AppLogger.error('Erro ao atualizar vaca', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao atualizar vaca: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, void>> deleteCow(String cowId, String userId) async {
    try {
      await _firestore.collection('vacas').doc(cowId).delete();

      AppLogger.info('🐄 Vaca removida (ID: $cowId)');
      return const Right(null);
    } catch (e) {
      AppLogger.error('Erro ao deletar vaca', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao deletar vaca: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, Cow?>> getCowById(String cowId, String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('vacas').doc(cowId).get();

      if (!doc.exists) {
        AppLogger.info('🐄 Vaca não encontrada (ID: $cowId)');
        return const Right(null);
      }

      final Cow cow =
          Cow.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      AppLogger.info('🐄 Vaca encontrada: ${cow.nome}');
      return Right(cow);
    } catch (e) {
      AppLogger.error('Erro ao buscar vaca', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao buscar vaca: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, List<Cow>>> getCowsWithFilters({
    required String userId,
    String? status,
    String? tipo,
    bool? lactacao,
  }) async {
    try {
      Query query =
          _firestore.collection('vacas').where('userId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (tipo != null) {
        query = query.where('tipo', isEqualTo: tipo);
      }
      if (lactacao != null) {
        query = query.where('lactacao', isEqualTo: lactacao);
      }

      final QuerySnapshot snapshot = await query.get();
      final List<Cow> cows = snapshot.docs
          .map((doc) =>
              Cow.fromFirestore(doc.id, doc.data() as Map<String, dynamic>),)
          .toList();

      AppLogger.info('🐄 ${cows.length} vacas encontradas com filtros');
      return Right(cows);
    } catch (e) {
      AppLogger.error(
          'Erro ao buscar vacas com filtros', e, StackTrace.current,);
      return Left(
          Failure.generic(message: 'Erro ao buscar vacas: ${e.toString()}'),);
    }
  }

  @override
  Future<Either<Failure, int>> getUserCowCount(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .get();

      return Right(snapshot.docs.length);
    } catch (e) {
      AppLogger.error('Erro ao contar vacas', e, StackTrace.current);
      return Left(
          Failure.generic(message: 'Erro ao contar vacas: ${e.toString()}'),);
    }
  }

  @override
  Stream<Either<Failure, List<Cow>>> watchUserCows(String userId) {
    try {
      return _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
        try {
          final List<Cow> cows = snapshot.docs
              .map((doc) => Cow.fromFirestore(doc.id, doc.data()))
              .toList();

          AppLogger.info('👁️ Stream atualizada: ${cows.length} vacas');
          return Right(cows);
        } catch (e) {
          AppLogger.error(
              'Erro ao processar stream de vacas', e, StackTrace.current,);
          return Left(Failure.generic(
              message: 'Erro ao processar dados: ${e.toString()}',),);
        }
      });
    } catch (e) {
      AppLogger.error('Erro ao criar stream de vacas', e, StackTrace.current);
      return Stream.value(Left(
          Failure.generic(message: 'Erro ao criar stream: ${e.toString()}'),),);
    }
  }
}

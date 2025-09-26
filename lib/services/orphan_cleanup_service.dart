import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';

/// Serviço responsável por identificar e limpar dados órfãos no banco de dados
class OrphanCleanupService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Executa uma limpeza completa de todos os dados órfãos
  static Future<OrphanCleanupResult> performFullCleanup() async {
    try {
      AppLogger.info('🧹 Iniciando limpeza completa de dados órfãos');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = OrphanCleanupResult();

      // 1. Limpar registros de produção órfãos
      final prodOrphans = await _cleanOrphanProductionRecords(user.uid);
      result.productionRecordsDeleted = prodOrphans;

      // 2. Limpar alertas órfãos
      final alertOrphans = await _cleanOrphanAlerts(user.uid);
      result.alertsDeleted = alertOrphans;

      // 3. Limpar alertas individuais órfãos
      final individualOrphans = await _cleanOrphanIndividualAlerts(user.uid);
      result.individualAlertsDeleted = individualOrphans;

      // 4. Limpar atividades órfãs (se necessário)
      final activityOrphans = await _cleanOrphanActivities(user.uid);
      result.activitiesDeleted = activityOrphans;

      // 5. Limpar backups órfãos
      final backupOrphans = await _cleanOrphanBackups(user.uid);
      result.backupsDeleted = backupOrphans;

      result.totalOrphansDeleted = result.productionRecordsDeleted +
          result.alertsDeleted +
          result.individualAlertsDeleted +
          result.activitiesDeleted +
          result.backupsDeleted;

      AppLogger.info(
          '✅ Limpeza concluída: ${result.totalOrphansDeleted} registros órfãos removidos',);

      return result;
    } catch (e) {
      AppLogger.error('❌ Erro na limpeza de órfãos', e);
      rethrow;
    }
  }

  /// Limpa registros de produção que referenciam vacas inexistentes
  static Future<int> _cleanOrphanProductionRecords(String userId) async {
    try {
      AppLogger.info('🔍 Verificando registros de produção órfãos');

      // Buscar todas as vacas existentes do usuário na coleção GLOBAL
      final vacasSnapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .get();

      final existingVacaIds = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      AppLogger.info(
          '🐄 Total de vacas encontradas: ${existingVacaIds.length}',);

      // Buscar todos os registros de produção do usuário na SUBCOLEÇÃO
      final producaoSnapshot = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('registros_producao')
          .get();

      int orphansDeleted = 0;
      final batch = _firestore.batch();

      for (final doc in producaoSnapshot.docs) {
        final data = doc.data();
        final vacaId = data['vaca_id'] as String?; // Campo correto é vaca_id

        // Se o registro referencia uma vaca que não existe mais
        if (vacaId != null && !existingVacaIds.contains(vacaId)) {
          batch.delete(doc.reference);
          orphansDeleted++;
          AppLogger.warning(
              '🗑️ Registro órfão encontrado: ${doc.id} -> vaca inexistente: $vacaId',);
        }
      }

      if (orphansDeleted > 0) {
        await batch.commit();
        AppLogger.info(
            '✅ Removidos $orphansDeleted registros de produção órfãos',);
      }

      return orphansDeleted;
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar registros de produção órfãos', e);
      return 0;
    }
  }

  /// Limpa alertas de produção que referenciam vacas inexistentes
  static Future<int> _cleanOrphanAlerts(String userId) async {
    try {
      AppLogger.info('🔍 Verificando alertas de produção órfãos');

      // Buscar todas as vacas existentes do usuário
      final vacasSnapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .get();

      final existingVacaIds = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      // Buscar todos os alertas (sem filtro por userId pois não têm esse campo)
      final alertsSnapshot =
          await _firestore.collection('alertas_producao').get();

      int orphansDeleted = 0;
      final batch = _firestore.batch();

      for (final doc in alertsSnapshot.docs) {
        final data = doc.data();
        final vacaId = data['vacaId'] as String?;

        // Se o alerta referencia uma vaca que não existe mais
        if (vacaId != null && !existingVacaIds.contains(vacaId)) {
          batch.delete(doc.reference);
          orphansDeleted++;
          AppLogger.warning(
              '🗑️ Alerta órfão encontrado: ${doc.id} -> vaca inexistente: $vacaId',);
        }
      }

      if (orphansDeleted > 0) {
        await batch.commit();
        AppLogger.info('✅ Removidos $orphansDeleted alertas órfãos');
      }

      return orphansDeleted;
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar alertas órfãos', e);
      return 0;
    }
  }

  /// Limpa alertas individuais que referenciam vacas inexistentes
  static Future<int> _cleanOrphanIndividualAlerts(String userId) async {
    try {
      AppLogger.info('🔍 Verificando alertas individuais órfãos');

      // Buscar todas as vacas existentes do usuário
      final vacasSnapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: userId)
          .get();

      final existingVacaIds = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      // Buscar alertas individuais que são documentos com ID = vacaId
      int orphansDeleted = 0;
      final batch = _firestore.batch();

      // Verificar cada vaca ID se tem alerta individual órfão
      final individualAlertsSnapshot =
          await _firestore.collection('alertas_individuais').get();

      for (final doc in individualAlertsSnapshot.docs) {
        final vacaId = doc.id; // O ID do documento é o ID da vaca

        if (!existingVacaIds.contains(vacaId)) {
          batch.delete(doc.reference);
          orphansDeleted++;
          AppLogger.warning('🗑️ Alerta individual órfão encontrado: $vacaId');
        }
      }

      if (orphansDeleted > 0) {
        await batch.commit();
        AppLogger.info(
            '✅ Removidos $orphansDeleted alertas individuais órfãos',);
      }

      return orphansDeleted;
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar alertas individuais órfãos', e);
      return 0;
    }
  }

  /// Limpa atividades órfãs (se houver referências a vacas)
  static Future<int> _cleanOrphanActivities(String userId) async {
    try {
      AppLogger.info('🔍 Verificando atividades órfãs');

      // Como as atividades são armazenadas no AtividadesRepository (em memória),
      // não há limpeza necessária aqui, mas podemos verificar dados persistidos
      // se no futuro as atividades forem salvas no Firestore

      return 0;
    } catch (e) {
      AppLogger.error('❌ Erro ao verificar atividades', e);
      return 0;
    }
  }

  /// Limpa metadados de backup órfãos
  static Future<int> _cleanOrphanBackups(String userId) async {
    try {
      AppLogger.info('🔍 Verificando backups órfãos');

      // Por agora, pular limpeza de backups para evitar problema de índice
      // Isso será tratado pelo BackupService que tem sua própria lógica de limpeza
      AppLogger.info('� Limpeza de backups delegada ao BackupService');

      return 0;
    } catch (e) {
      AppLogger.error('❌ Erro ao limpar backups órfãos', e);
      return 0;
    }
  }

  /// Executa apenas verificação sem deletar (modo dry-run)
  static Future<OrphanCleanupResult> checkOrphansOnly() async {
    try {
      AppLogger.info('🔍 Verificando órfãos (modo consulta apenas)');

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final result = OrphanCleanupResult();

      // Buscar todas as vacas existentes
      final vacasSnapshot = await _firestore
          .collection('vacas')
          .where('userId', isEqualTo: user.uid)
          .get();

      final existingVacaIds = vacasSnapshot.docs.map((doc) => doc.id).toSet();

      // Contar registros órfãos (sem deletar)
      final producaoSnapshot = await _firestore
          .collection('registros_producao')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (final doc in producaoSnapshot.docs) {
        final data = doc.data();
        final vacaId = data['vacaId'] as String?;

        if (vacaId != null && !existingVacaIds.contains(vacaId)) {
          result.productionRecordsDeleted++;
        }
      }

      AppLogger.info(
          '📊 Encontrados ${result.productionRecordsDeleted} registros órfãos',);

      return result;
    } catch (e) {
      AppLogger.error('❌ Erro na verificação de órfãos', e);
      rethrow;
    }
  }

  /// Limpa órfãos de uma vaca específica que foi deletada
  static Future<void> cleanupAfterCowDeletion(
      String cowId, String userId,) async {
    try {
      AppLogger.info('🧹 Limpando dados órfãos da vaca: $cowId');

      final batch = _firestore.batch();

      // Limpar registros de produção na subcoleção correta
      final producaoQuery = await _firestore
          .collection('usuarios')
          .doc(userId)
          .collection('registros_producao')
          .where('vaca_id', isEqualTo: cowId)
          .get();

      for (final doc in producaoQuery.docs) {
        batch.delete(doc.reference);
      }

      // Limpar alertas
      final alertsQuery = await _firestore
          .collection('alertas_producao')
          .where('vacaId', isEqualTo: cowId)
          .get();

      for (final doc in alertsQuery.docs) {
        batch.delete(doc.reference);
      }

      // Limpar alerta individual
      final individualAlertRef =
          _firestore.collection('alertas_individuais').doc(cowId);

      batch.delete(individualAlertRef);

      await batch.commit();

      AppLogger.info('✅ Limpeza da vaca $cowId concluída');
    } catch (e) {
      AppLogger.error('❌ Erro na limpeza da vaca $cowId', e);
    }
  }
}

/// Resultado da operação de limpeza
class OrphanCleanupResult {
  int productionRecordsDeleted = 0;
  int alertsDeleted = 0;
  int individualAlertsDeleted = 0;
  int activitiesDeleted = 0;
  int backupsDeleted = 0;
  int totalOrphansDeleted = 0;

  @override
  String toString() {
    return '''
🧹 Resultado da Limpeza:
• Registros de produção: $productionRecordsDeleted
• Alertas: $alertsDeleted  
• Alertas individuais: $individualAlertsDeleted
• Atividades: $activitiesDeleted
• Backups: $backupsDeleted
📊 Total: $totalOrphansDeleted órfãos removidos
    ''';
  }
}

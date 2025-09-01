import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fazer backup completo dos dados
  Future<bool> createBackup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Coletar todos os dados
      final backupData = await _collectAllData(user.uid);
      
      // Criar arquivo de backup
      final backupJson = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'version': '1.0',
        'data': backupData,
      });

      // Salvar no Firebase Storage
      final fileName = 'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final ref = _storage.ref().child('backups/${user.uid}/$fileName');
      
      await ref.putString(backupJson);
      
      // Salvar referência do backup no Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .add({
        'fileName': fileName,
        'timestamp': FieldValue.serverTimestamp(),
        'size': backupJson.length,
        'status': 'completed',
      });

      return true;
    } catch (e) {
      print('Erro ao criar backup: $e');
      return false;
    }
  }

  // Coletar todos os dados do usuário
  Future<Map<String, dynamic>> _collectAllData(String userId) async {
    final data = <String, dynamic>{};

    // Coletar vacas
    final vacasSnapshot = await _firestore
        .collection('vacas')
        .where('userId', isEqualTo: userId)
        .get();
    data['vacas'] = vacasSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();

    // Coletar registros de produção
    final producaoSnapshot = await _firestore
        .collection('registros_producao')
        .where('userId', isEqualTo: userId)
        .get();
    data['registros_producao'] = producaoSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();

    // Coletar atividades
    final atividadesSnapshot = await _firestore
        .collection('atividades')
        .where('userId', isEqualTo: userId)
        .get();
    data['atividades'] = atividadesSnapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();

    // Coletar configurações do usuário
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        data['user_settings'] = userDoc.data();
      }
    } catch (e) {
      print('Erro ao coletar configurações: $e');
    }

    return data;
  }

  // Listar backups disponíveis
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final backupsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      return backupsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Erro ao listar backups: $e');
      return [];
    }
  }

  // Restaurar backup
  Future<bool> restoreBackup(String backupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Buscar informações do backup
      final backupDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!backupDoc.exists) {
        throw Exception('Backup não encontrado');
      }

      final fileName = backupDoc.data()!['fileName'] as String;
      
      // Baixar arquivo do Firebase Storage
      final ref = _storage.ref().child('backups/${user.uid}/$fileName');
      final backupData = await ref.getData();
      
      if (backupData == null) {
        throw Exception('Erro ao baixar backup');
      }

      final backupJson = jsonDecode(String.fromCharCodes(backupData));
      final data = backupJson['data'] as Map<String, dynamic>;

      // Limpar dados existentes e restaurar
      await _clearUserData(user.uid);
      await _restoreUserData(user.uid, data);

      return true;
    } catch (e) {
      print('Erro ao restaurar backup: $e');
      return false;
    }
  }

  // Limpar dados existentes do usuário
  Future<void> _clearUserData(String userId) async {
    final batch = _firestore.batch();

    // Limpar vacas
    final vacasSnapshot = await _firestore
        .collection('vacas')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in vacasSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Limpar registros de produção
    final producaoSnapshot = await _firestore
        .collection('registros_producao')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in producaoSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Limpar atividades
    final atividadesSnapshot = await _firestore
        .collection('atividades')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in atividadesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // Restaurar dados do usuário
  Future<void> _restoreUserData(String userId, Map<String, dynamic> data) async {
    final batch = _firestore.batch();

    // Restaurar vacas
    if (data['vacas'] != null) {
      for (final vaca in data['vacas'] as List) {
        final docData = Map<String, dynamic>.from(vaca);
        docData.remove('id'); // Remove o ID antigo
        docData['userId'] = userId; // Garante o userId correto
        
        final ref = _firestore.collection('vacas').doc();
        batch.set(ref, docData);
      }
    }

    // Restaurar registros de produção
    if (data['registros_producao'] != null) {
      for (final registro in data['registros_producao'] as List) {
        final docData = Map<String, dynamic>.from(registro);
        docData.remove('id');
        docData['userId'] = userId;
        
        final ref = _firestore.collection('registros_producao').doc();
        batch.set(ref, docData);
      }
    }

    // Restaurar atividades
    if (data['atividades'] != null) {
      for (final atividade in data['atividades'] as List) {
        final docData = Map<String, dynamic>.from(atividade);
        docData.remove('id');
        docData['userId'] = userId;
        
        final ref = _firestore.collection('atividades').doc();
        batch.set(ref, docData);
      }
    }

    // Restaurar configurações do usuário
    if (data['user_settings'] != null) {
      final userRef = _firestore.collection('users').doc(userId);
      batch.set(userRef, data['user_settings'] as Map<String, dynamic>, 
               SetOptions(merge: true));
    }

    await batch.commit();
  }

  // Exportar dados para arquivo local
  Future<bool> exportToFile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuário não autenticado');

      // Coletar dados
      final backupData = await _collectAllData(user.uid);
      
      // Criar JSON
      final exportJson = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        'appName': 'Leite+',
        'version': '1.0',
        'data': backupData,
      });

      // Salvar arquivo local
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'leite_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(exportJson);

      // Compartilhar arquivo
      await Share.shareXFiles([XFile(file.path)], 
          text: 'Backup dos dados do Leite+');

      return true;
    } catch (e) {
      print('Erro ao exportar: $e');
      return false;
    }
  }

  // Backup automático (executar periodicamente)
  Future<bool> autoBackup() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verificar se já existe backup recente (últimas 24h)
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      final recentBackups = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .get();

      if (recentBackups.docs.isNotEmpty) {
        print('Backup recente já existe');
        return true;
      }

      // Criar novo backup
      return await createBackup();
    } catch (e) {
      print('Erro no backup automático: $e');
      return false;
    }
  }

  // Limpar backups antigos (manter apenas últimos 5)
  Future<void> cleanOldBackups() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final backupsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .orderBy('timestamp', descending: true)
          .get();

      if (backupsSnapshot.docs.length > 5) {
        final toDelete = backupsSnapshot.docs.skip(5);
        
        for (final doc in toDelete) {
          // Deletar do Storage
          final fileName = doc.data()['fileName'] as String;
          try {
            await _storage.ref().child('backups/${user.uid}/$fileName').delete();
          } catch (e) {
            print('Erro ao deletar arquivo: $e');
          }
          
          // Deletar do Firestore
          await doc.reference.delete();
        }
      }
    } catch (e) {
      print('Erro ao limpar backups antigos: $e');
    }
  }
}

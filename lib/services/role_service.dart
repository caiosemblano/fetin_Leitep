import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRole {
  final bool isAdmin;
  final String role;

  UserRole({this.isAdmin = false, this.role = 'user'});

  factory UserRole.fromFirestore(dynamic data) {
    if (data == null) return UserRole();

    // Se for uma string JSON, converter para Map
    if (data is String) {
      try {
        final Map<String, dynamic> jsonData = jsonDecode(data);
        return UserRole(
          isAdmin: jsonData['isAdmin'] ?? false,
          role: jsonData['role'] ?? 'user',
        );
      } catch (e) {
        print('Erro ao fazer parse do JSON: $e');
        return UserRole();
      }
    }

    // Se já for um Map, usar diretamente
    if (data is Map<String, dynamic>) {
      return UserRole(
        isAdmin: data['isAdmin'] ?? false,
        role: data['role'] ?? 'user',
      );
    }

    return UserRole();
  }

  Map<String, dynamic> toMap() {
    return {'isAdmin': isAdmin, 'role': role};
  }
}

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final RoleService instance = RoleService._internal();
  factory RoleService() => instance;
  RoleService._internal();

  Future<UserRole> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return UserRole();

    try {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (!doc.exists) return UserRole();

      return UserRole.fromFirestore(doc.data()?['role_info']);
    } catch (e) {
      print('Erro ao buscar função do usuário: $e');
      return UserRole();
    }
  }

  Stream<UserRole> getUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(UserRole());

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => UserRole.fromFirestore(doc.data()?['role_info']));
  }

  Future<void> setUserRole(
    String userId, {
    bool isAdmin = false,
    String role = 'user',
  }) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'role_info': {'isAdmin': isAdmin, 'role': role},
      });
    } catch (e) {
      print('Erro ao atualizar função do usuário: $e');
      rethrow;
    }
  }

  Future<bool> isUserAdmin() async {
    final role = await getUserRole();
    print('Verificando admin - isAdmin: ${role.isAdmin}, role: ${role.role}');
    return role.isAdmin;
  }
}

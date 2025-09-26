import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('usuarios');

  Future<void> saveUserData(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    await _usersCollection.doc(userId).set(userData);
  }
}

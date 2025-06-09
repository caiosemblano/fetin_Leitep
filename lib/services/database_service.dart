import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> saveUserData(String userId, Map<String, dynamic> userData) async {
    await _dbRef.child('users').child(userId).set(userData);
  }
}

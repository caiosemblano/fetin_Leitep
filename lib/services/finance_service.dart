import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modelo para uma transação financeira.
class FinancialTransaction {
  final String id;
  final String description;
  final double amount;
  final String type; // 'receita' ou 'despesa'
  final DateTime date;

  FinancialTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FinancialTransaction(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      type: data['type'] ?? 'despesa',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Serviço para gerenciar as operações financeiras no Firestore.
class FinanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retorna um stream com a lista de transações do usuário.
  Stream<List<FinancialTransaction>> getTransactionsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('transacoes')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FinancialTransaction.fromFirestore(doc))
              .toList(),
        );
  }

  /// Adiciona uma nova transação.
  Future<void> addTransaction({
    required String description,
    required double amount,
    required String type,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado para adicionar transação.');
    }

    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('transacoes')
        .add({
          'description': description,
          'amount': amount,
          'type': type,
          'date': Timestamp.fromDate(date),
        });
  }

  /// Atualiza uma transação existente.
  Future<void> updateTransaction({
    required String transactionId,
    required String description,
    required double amount,
    required String type,
    required DateTime date,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado para atualizar transação.');
    }

    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('transacoes')
        .doc(transactionId)
        .update({
          'description': description,
          'amount': amount,
          'type': type,
          'date': Timestamp.fromDate(date),
        });
  }

  /// Deleta uma transação.
  Future<void> deleteTransaction(String transactionId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado para deletar transação.');
    }

    await _db
        .collection('usuarios')
        .doc(user.uid)
        .collection('transacoes')
        .doc(transactionId)
        .delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para uma vaca
class Cow {
  const Cow({
    required this.id,
    required this.nome,
    required this.raca,
    required this.idade,
    required this.peso,
    this.mae,
    this.pai,
    this.lactacao = false,
    this.status = 'ativa',
    this.tipo = 'leiteira',
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de dados do Firestore
  factory Cow.fromFirestore(String id, Map<String, dynamic> data) {
    return Cow(
      id: id,
      nome: data['nome'] ?? '',
      raca: data['raca'] ?? '',
      idade: data['idade'] ?? 0,
      peso: (data['peso'] ?? 0).toDouble(),
      mae: data['mae'],
      pai: data['pai'],
      lactacao: data['lactacao'] ?? false,
      status: data['status'] ?? 'ativa',
      tipo: data['tipo'] ?? 'leiteira',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String nome;
  final String raca;
  final int idade;
  final double peso;
  final String? mae;
  final String? pai;
  final bool lactacao;
  final String status;
  final String tipo;
  final String userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'raca': raca,
      'idade': idade,
      'peso': peso,
      'mae': mae,
      'pai': pai,
      'lactacao': lactacao,
      'status': status,
      'tipo': tipo,
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Cria uma cópia com campos atualizados
  Cow copyWith({
    String? id,
    String? nome,
    String? raca,
    int? idade,
    double? peso,
    String? mae,
    String? pai,
    bool? lactacao,
    String? status,
    String? tipo,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cow(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      raca: raca ?? this.raca,
      idade: idade ?? this.idade,
      peso: peso ?? this.peso,
      mae: mae ?? this.mae,
      pai: pai ?? this.pai,
      lactacao: lactacao ?? this.lactacao,
      status: status ?? this.status,
      tipo: tipo ?? this.tipo,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Propriedades calculadas
  bool get isLactating => lactacao;
  bool get isActive => status == 'ativa';
  String get displayName => nome.isNotEmpty ? nome : 'Vaca #$id';

  /// Validações
  bool get isValid {
    return nome.isNotEmpty &&
        raca.isNotEmpty &&
        idade > 0 &&
        peso > 0 &&
        userId.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cow &&
        other.id == id &&
        other.nome == nome &&
        other.raca == raca &&
        other.idade == idade &&
        other.peso == peso &&
        other.mae == mae &&
        other.pai == pai &&
        other.lactacao == lactacao &&
        other.status == status &&
        other.tipo == tipo &&
        other.userId == userId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      nome,
      raca,
      idade,
      peso,
      mae,
      pai,
      lactacao,
      status,
      tipo,
      userId,
      createdAt,
      updatedAt,
    );
  }
}

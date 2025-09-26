import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de dados para registro de produção
class ProductionRecord {
  const ProductionRecord({
    required this.id,
    required this.cowId,
    required this.userId,
    required this.quantidade,
    this.tipo = 'leite',
    this.periodo = 'manhã',
    this.observacao,
    required this.dataRegistro,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de dados do Firestore
  factory ProductionRecord.fromFirestore(String id, Map<String, dynamic> data) {
    return ProductionRecord(
      id: id,
      cowId: data['vaca_id'] ?? data['cowId'] ?? '',
      userId: data['userId'] ?? '',
      quantidade: (data['quantidade'] ?? 0).toDouble(),
      tipo: data['tipo'] ?? 'leite',
      periodo: data['periodo'] ?? 'manhã',
      observacao: data['observacao'],
      dataRegistro: (data['data_registro'] as Timestamp?)?.toDate() ??
          (data['dataRegistro'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  final String id;
  final String cowId;
  final String userId;
  final double quantidade;
  final String tipo;
  final String periodo;
  final String? observacao;
  final DateTime dataRegistro;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'vaca_id': cowId,
      'cowId': cowId, // Manter ambos para compatibilidade
      'userId': userId,
      'quantidade': quantidade,
      'tipo': tipo,
      'periodo': periodo,
      'observacao': observacao,
      'data_registro': Timestamp.fromDate(dataRegistro),
      'dataRegistro': Timestamp.fromDate(dataRegistro), // Compatibilidade
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Cria uma cópia com campos atualizados
  ProductionRecord copyWith({
    String? id,
    String? cowId,
    String? userId,
    double? quantidade,
    String? tipo,
    String? periodo,
    String? observacao,
    DateTime? dataRegistro,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductionRecord(
      id: id ?? this.id,
      cowId: cowId ?? this.cowId,
      userId: userId ?? this.userId,
      quantidade: quantidade ?? this.quantidade,
      tipo: tipo ?? this.tipo,
      periodo: periodo ?? this.periodo,
      observacao: observacao ?? this.observacao,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Propriedades calculadas
  bool get isValidQuantity => quantidade > 0;
  String get displayDate =>
      '${dataRegistro.day}/${dataRegistro.month}/${dataRegistro.year}';
  String get displayTime =>
      '${dataRegistro.hour.toString().padLeft(2, '0')}:${dataRegistro.minute.toString().padLeft(2, '0')}';

  /// Validações
  bool get isValid {
    return cowId.isNotEmpty && userId.isNotEmpty && quantidade > 0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductionRecord &&
        other.id == id &&
        other.cowId == cowId &&
        other.userId == userId &&
        other.quantidade == quantidade &&
        other.tipo == tipo &&
        other.periodo == periodo &&
        other.observacao == observacao &&
        other.dataRegistro == dataRegistro &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      cowId,
      userId,
      quantidade,
      tipo,
      periodo,
      observacao,
      dataRegistro,
      createdAt,
      updatedAt,
    );
  }
}

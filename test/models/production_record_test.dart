import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pleite_fetin/models/production_record.dart';

void main() {
  group('ProductionRecord Model Tests', () {
    late Map<String, dynamic> validProductionData;
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15, 10, 30));
    final testDateTime = DateTime(2024, 1, 15, 6, 0);
    
    setUp(() {
      validProductionData = {
        'vaca_id': 'cow-123',
        'cowId': 'cow-123',
        'userId': 'user-456',
        'quantidade': 15.5,
        'tipo': 'leite',
        'periodo': 'manhã',
        'observacao': 'Produção normal',
        'data_registro': Timestamp.fromDate(testDateTime),
        'dataRegistro': Timestamp.fromDate(testDateTime),
        'createdAt': testTimestamp,
        'updatedAt': testTimestamp,
      };
    });

    group('ProductionRecord.fromFirestore', () {
      test('deve criar ProductionRecord a partir de dados válidos do Firestore', () {
        // Act
        final record = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(record.id, equals('record-1'));
        expect(record.cowId, equals('cow-123'));
        expect(record.userId, equals('user-456'));
        expect(record.quantidade, equals(15.5));
        expect(record.tipo, equals('leite'));
        expect(record.periodo, equals('manhã'));
        expect(record.observacao, equals('Produção normal'));
        expect(record.dataRegistro, equals(testDateTime));
        expect(record.createdAt, equals(testTimestamp.toDate()));
        expect(record.updatedAt, equals(testTimestamp.toDate()));
      });

      test('deve usar valores padrão para campos opcionais', () {
        // Arrange
        final minimalData = <String, dynamic>{
          'cowId': 'cow-789',
          'userId': 'user-456',
          'quantidade': 12.0,
        };
        
        // Act
        final record = ProductionRecord.fromFirestore('record-2', minimalData);
        
        // Assert
        expect(record.cowId, equals('cow-789'));
        expect(record.userId, equals('user-456'));
        expect(record.quantidade, equals(12.0));
        expect(record.tipo, equals('leite'));
        expect(record.periodo, equals('manhã'));
        expect(record.observacao, isNull);
        expect(record.dataRegistro, isA<DateTime>());
        expect(record.createdAt, isA<DateTime>());
        expect(record.updatedAt, isA<DateTime>());
      });

      test('deve priorizar vaca_id sobre cowId', () {
        // Arrange
        final dataWithBothIds = {
          'vaca_id': 'preferred-id',
          'cowId': 'fallback-id',
          'userId': 'user-456',
          'quantidade': 10.0,
        };
        
        // Act
        final record = ProductionRecord.fromFirestore('record-3', dataWithBothIds);
        
        // Assert
        expect(record.cowId, equals('preferred-id'));
      });

      test('deve usar cowId quando vaca_id não está disponível', () {
        // Arrange
        final dataWithCowIdOnly = {
          'cowId': 'fallback-id',
          'userId': 'user-456',
          'quantidade': 10.0,
        };
        
        // Act
        final record = ProductionRecord.fromFirestore('record-4', dataWithCowIdOnly);
        
        // Assert
        expect(record.cowId, equals('fallback-id'));
      });

      test('deve priorizar data_registro sobre dataRegistro', () {
        // Arrange
        final preferredDate = DateTime(2024, 2, 1);
        final fallbackDate = DateTime(2024, 1, 1);
        final dataWithBothDates = {
          'cowId': 'cow-123',
          'userId': 'user-456',
          'quantidade': 10.0,
          'data_registro': Timestamp.fromDate(preferredDate),
          'dataRegistro': Timestamp.fromDate(fallbackDate),
        };
        
        // Act
        final record = ProductionRecord.fromFirestore('record-5', dataWithBothDates);
        
        // Assert
        expect(record.dataRegistro, equals(preferredDate));
      });

      test('deve converter quantidade corretamente para double', () {
        // Arrange
        final dataWithIntQuantity = {
          ...validProductionData,
          'quantidade': 20, // int ao invés de double
        };
        
        // Act
        final record = ProductionRecord.fromFirestore('record-6', dataWithIntQuantity);
        
        // Assert
        expect(record.quantidade, equals(20.0));
        expect(record.quantidade, isA<double>());
      });

      test('deve lidar com dados inválidos graciosamente', () {
        // Arrange
        final invalidData = <String, dynamic>{};
        
        // Act
        final record = ProductionRecord.fromFirestore('record-7', invalidData);
        
        // Assert
        expect(record.id, equals('record-7'));
        expect(record.cowId, equals(''));
        expect(record.userId, equals(''));
        expect(record.quantidade, equals(0.0));
        expect(record.tipo, equals('leite'));
        expect(record.periodo, equals('manhã'));
        expect(record.dataRegistro, isA<DateTime>());
      });
    });

    group('toFirestore', () {
      test('deve converter ProductionRecord para Map do Firestore', () {
        // Arrange
        final record = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Act
        final firestoreMap = record.toFirestore();
        
        // Assert
        expect(firestoreMap['vaca_id'], equals('cow-123'));
        expect(firestoreMap['cowId'], equals('cow-123'));
        expect(firestoreMap['userId'], equals('user-456'));
        expect(firestoreMap['quantidade'], equals(15.5));
        expect(firestoreMap['tipo'], equals('leite'));
        expect(firestoreMap['periodo'], equals('manhã'));
        expect(firestoreMap['observacao'], equals('Produção normal'));
        expect(firestoreMap['data_registro'], isA<Timestamp>());
        expect(firestoreMap['dataRegistro'], isA<Timestamp>());
        expect(firestoreMap['createdAt'], isA<Timestamp>());
        expect(firestoreMap['updatedAt'], isA<Timestamp>());
      });

      test('deve incluir campos nulos no Map', () {
        // Arrange
        final recordWithNulls = ProductionRecord(
          id: 'record-8',
          cowId: 'cow-123',
          userId: 'user-456',
          quantidade: 10.0,
          observacao: null,
          dataRegistro: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        // Act
        final firestoreMap = recordWithNulls.toFirestore();
        
        // Assert
        expect(firestoreMap.containsKey('observacao'), isTrue);
        expect(firestoreMap['observacao'], isNull);
      });
    });

    group('copyWith', () {
      test('deve criar uma nova instância com campos atualizados', () {
        // Arrange
        final originalRecord = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Act
        final updatedRecord = originalRecord.copyWith(
          quantidade: 20.0,
          tipo: 'queijo',
          periodo: 'tarde',
          observacao: 'Observação atualizada',
        );
        
        // Assert
        expect(updatedRecord.id, equals(originalRecord.id));
        expect(updatedRecord.quantidade, equals(20.0));
        expect(updatedRecord.tipo, equals('queijo'));
        expect(updatedRecord.periodo, equals('tarde'));
        expect(updatedRecord.observacao, equals('Observação atualizada'));
        expect(updatedRecord.cowId, equals(originalRecord.cowId)); // não alterado
        expect(updatedRecord.userId, equals(originalRecord.userId)); // não alterado
      });

      test('deve manter os valores originais quando nenhum campo é fornecido', () {
        // Arrange
        final originalRecord = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Act
        final copiedRecord = originalRecord.copyWith();
        
        // Assert
        expect(copiedRecord.id, equals(originalRecord.id));
        expect(copiedRecord.cowId, equals(originalRecord.cowId));
        expect(copiedRecord.userId, equals(originalRecord.userId));
        expect(copiedRecord.quantidade, equals(originalRecord.quantidade));
        expect(copiedRecord.tipo, equals(originalRecord.tipo));
        expect(copiedRecord.periodo, equals(originalRecord.periodo));
      });
    });

    group('Propriedades calculadas', () {
      test('isValidQuantity deve retornar true para quantidade positiva', () {
        // Arrange
        final validRecord = ProductionRecord.fromFirestore('record-1', validProductionData);
        final invalidRecord = ProductionRecord.fromFirestore('record-2', {...validProductionData, 'quantidade': 0.0});
        
        // Assert
        expect(validRecord.isValidQuantity, isTrue);
        expect(invalidRecord.isValidQuantity, isFalse);
      });

      test('displayDate deve retornar data formatada corretamente', () {
        // Arrange
        final record = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(record.displayDate, equals('15/1/2024'));
      });

      test('displayTime deve retornar hora formatada corretamente', () {
        // Arrange
        final record = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(record.displayTime, equals('06:00'));
      });
    });

    group('Validações', () {
      test('isValid deve retornar true para registro válido', () {
        // Arrange
        final validRecord = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(validRecord.isValid, isTrue);
      });

      test('isValid deve retornar false para registro inválido', () {
        // Arrange
        final invalidRecord = ProductionRecord.fromFirestore('record-2', {
          'cowId': '', // vazio
          'userId': 'user-456',
          'quantidade': 0.0, // zero
        });
        
        // Assert
        expect(invalidRecord.isValid, isFalse);
      });

      test('isValid deve verificar todos os campos obrigatórios', () {
        // Test cowId vazio
        final recordWithEmptyCowId = ProductionRecord.fromFirestore('r1', {
          ...validProductionData,
          'vaca_id': '',
          'cowId': '',
        });
        expect(recordWithEmptyCowId.isValid, isFalse);

        // Test userId vazio  
        final recordWithEmptyUserId = ProductionRecord.fromFirestore('r2', {...validProductionData, 'userId': ''});
        expect(recordWithEmptyUserId.isValid, isFalse);

        // Test quantidade zero
        final recordWithZeroQuantity = ProductionRecord.fromFirestore('r3', {...validProductionData, 'quantidade': 0.0});
        expect(recordWithZeroQuantity.isValid, isFalse);

        // Test quantidade negativa
        final recordWithNegativeQuantity = ProductionRecord.fromFirestore('r4', {...validProductionData, 'quantidade': -5.0});
        expect(recordWithNegativeQuantity.isValid, isFalse);
      });
    });

    group('Equality & HashCode', () {
      test('dois registros idênticos devem ser iguais', () {
        // Arrange
        final record1 = ProductionRecord.fromFirestore('record-1', validProductionData);
        final record2 = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(record1, equals(record2));
        expect(record1.hashCode, equals(record2.hashCode));
      });

      test('dois registros diferentes devem ser diferentes', () {
        // Arrange
        final record1 = ProductionRecord.fromFirestore('record-1', validProductionData);
        final record2 = ProductionRecord.fromFirestore('record-2', {...validProductionData, 'quantidade': 25.0});
        
        // Assert
        expect(record1, isNot(equals(record2)));
      });

      test('mesma instância deve ser igual a si mesma', () {
        // Arrange
        final record = ProductionRecord.fromFirestore('record-1', validProductionData);
        
        // Assert
        expect(record, equals(record));
        expect(identical(record, record), isTrue);
      });
    });
  });
}
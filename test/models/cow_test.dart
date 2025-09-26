import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pleite_fetin/models/cow.dart';

void main() {
  group('Cow Model Tests', () {
    late Map<String, dynamic> validCowData;
    final testTimestamp = Timestamp.fromDate(DateTime(2024, 1, 15));
    
    setUp(() {
      validCowData = {
        'nome': 'Mimosa',
        'raca': 'Holandesa',
        'idade': 3,
        'peso': 450.5,
        'mae': 'Bezerrada',
        'pai': 'Touro Grande',
        'lactacao': true,
        'status': 'ativa',
        'tipo': 'leiteira',
        'userId': 'user123',
        'createdAt': testTimestamp,
        'updatedAt': testTimestamp,
      };
    });

    group('Cow.fromFirestore', () {
      test('deve criar Cow a partir de dados válidos do Firestore', () {
        // Act
        final cow = Cow.fromFirestore('test-cow-1', validCowData);
        
        // Assert
        expect(cow.id, equals('test-cow-1'));
        expect(cow.nome, equals('Mimosa'));
        expect(cow.raca, equals('Holandesa'));
        expect(cow.idade, equals(3));
        expect(cow.peso, equals(450.5));
        expect(cow.mae, equals('Bezerrada'));
        expect(cow.pai, equals('Touro Grande'));
        expect(cow.lactacao, isTrue);
        expect(cow.status, equals('ativa'));
        expect(cow.tipo, equals('leiteira'));
        expect(cow.userId, equals('user123'));
        expect(cow.createdAt, equals(testTimestamp.toDate()));
        expect(cow.updatedAt, equals(testTimestamp.toDate()));
      });

      test('deve usar valores padrão para campos opcionais', () {
        // Arrange
        final minimalData = <String, dynamic>{
          'nome': 'Vaca Simples',
          'raca': 'Girolando',
          'idade': 2,
          'peso': 350.0,
          'userId': 'user123',
        };
        
        // Act
        final cow = Cow.fromFirestore('test-cow-2', minimalData);
        
        // Assert
        expect(cow.nome, equals('Vaca Simples'));
        expect(cow.raca, equals('Girolando'));
        expect(cow.mae, isNull);
        expect(cow.pai, isNull);
        expect(cow.lactacao, isFalse);
        expect(cow.status, equals('ativa'));
        expect(cow.tipo, equals('leiteira'));
        expect(cow.createdAt, isA<DateTime>());
        expect(cow.updatedAt, isA<DateTime>());
      });

      test('deve lidar com dados inválidos graciosamente', () {
        // Arrange
        final invalidData = <String, dynamic>{};
        
        // Act
        final cow = Cow.fromFirestore('test-cow-3', invalidData);
        
        // Assert
        expect(cow.id, equals('test-cow-3'));
        expect(cow.nome, equals(''));
        expect(cow.raca, equals(''));
        expect(cow.idade, equals(0));
        expect(cow.peso, equals(0.0));
        expect(cow.userId, equals(''));
      });
    });

    group('toFirestore', () {
      test('deve converter Cow para Map do Firestore', () {
        // Arrange
        final cow = Cow.fromFirestore('test-cow-1', validCowData);
        
        // Act
        final firestoreMap = cow.toFirestore();
        
        // Assert
        expect(firestoreMap['nome'], equals('Mimosa'));
        expect(firestoreMap['raca'], equals('Holandesa'));
        expect(firestoreMap['idade'], equals(3));
        expect(firestoreMap['peso'], equals(450.5));
        expect(firestoreMap['lactacao'], isTrue);
        expect(firestoreMap['status'], equals('ativa'));
        expect(firestoreMap['tipo'], equals('leiteira'));
        expect(firestoreMap['userId'], equals('user123'));
        expect(firestoreMap['createdAt'], isA<Timestamp>());
        expect(firestoreMap['updatedAt'], isA<Timestamp>());
      });
    });

    group('copyWith', () {
      test('deve criar uma nova instância com campos atualizados', () {
        // Arrange
        final originalCow = Cow.fromFirestore('test-cow-1', validCowData);
        
        // Act
        final updatedCow = originalCow.copyWith(
          nome: 'Mimosa Atualizada',
          idade: 4,
          lactacao: false,
        );
        
        // Assert
        expect(updatedCow.nome, equals('Mimosa Atualizada'));
        expect(updatedCow.idade, equals(4));
        expect(updatedCow.lactacao, isFalse);
        expect(updatedCow.raca, equals(originalCow.raca));
      });
    });

    group('Propriedades calculadas', () {
      test('isLactating deve retornar o valor correto', () {
        // Arrange
        final lactatingCow = Cow.fromFirestore('cow-1', {...validCowData, 'lactacao': true});
        final nonLactatingCow = Cow.fromFirestore('cow-2', {...validCowData, 'lactacao': false});
        
        // Assert
        expect(lactatingCow.isLactating, isTrue);
        expect(nonLactatingCow.isLactating, isFalse);
      });

      test('isActive deve retornar true para status ativa', () {
        // Arrange
        final activeCow = Cow.fromFirestore('cow-1', {...validCowData, 'status': 'ativa'});
        final inactiveCow = Cow.fromFirestore('cow-2', {...validCowData, 'status': 'vendida'});
        
        // Assert
        expect(activeCow.isActive, isTrue);
        expect(inactiveCow.isActive, isFalse);
      });

      test('displayName deve retornar nome se disponível', () {
        // Arrange
        final namedCow = Cow.fromFirestore('cow-1', validCowData);
        final unnamedCow = Cow.fromFirestore('cow-2', {...validCowData, 'nome': ''});
        
        // Assert
        expect(namedCow.displayName, equals('Mimosa'));
        expect(unnamedCow.displayName, equals('Vaca #cow-2'));
      });
    });

    group('Validações', () {
      test('isValid deve retornar true para vaca válida', () {
        // Arrange
        final validCow = Cow.fromFirestore('test-cow-1', validCowData);
        
        // Assert
        expect(validCow.isValid, isTrue);
      });

      test('isValid deve retornar false para vaca inválida', () {
        // Arrange
        final invalidCow = Cow.fromFirestore('test-cow-2', {
          'nome': '',
          'raca': 'Holandesa',
          'idade': 0,
          'peso': 0.0,
          'userId': '',
        });
        
        // Assert
        expect(invalidCow.isValid, isFalse);
      });
    });

    group('Equality & HashCode', () {
      test('duas vacas idênticas devem ser iguais', () {
        // Arrange
        final cow1 = Cow.fromFirestore('test-cow-1', validCowData);
        final cow2 = Cow.fromFirestore('test-cow-1', validCowData);
        
        // Assert
        expect(cow1, equals(cow2));
        expect(cow1.hashCode, equals(cow2.hashCode));
      });

      test('duas vacas diferentes devem ser diferentes', () {
        // Arrange
        final cow1 = Cow.fromFirestore('test-cow-1', validCowData);
        final cow2 = Cow.fromFirestore('test-cow-2', {...validCowData, 'nome': 'Outra Vaca'});
        
        // Assert
        expect(cow1, isNot(equals(cow2)));
      });
    });
  });
}
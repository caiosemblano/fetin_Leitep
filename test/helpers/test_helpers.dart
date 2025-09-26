/// Configuração base para testes unitários
/// Fornece utilitários simples para testes
library;

import 'package:flutter/material.dart';

/// Configuração base para testes de widgets
class TestBase {
  /// Cria widget testável com MaterialApp wrapper
  static Widget createTestableWidget({
    required Widget child,
    ThemeData? theme,
    Locale? locale,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      locale: locale ?? const Locale('pt', 'BR'),
      home: child,
    );
  }

  /// Scaffold wrapper para testes de páginas
  static Widget createScaffoldWrapper({
    required Widget child,
    String title = 'Test',
  }) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: child,
    );
  }
}

/// Constantes para testes
class TestConstants {
  static const String testUserId = 'test-user-123';
  static const String testCowId = 'test-cow-456';
  static const String testRecordId = 'test-record-789';
}
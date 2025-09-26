# 🐄 pLeite FETIN - Guia do Desenvolvedor

## 🚀 Início Rápido

### Pré-requisitos
- Flutter SDK (3.16+)
- Dart SDK (3.2+)
- Android Studio / VS Code
- Firebase CLI
- Git

### Setup do Projeto

1. **Clone o repositório**
   ```bash
   git clone <repository-url>
   cd pLeite_fetin
   ```

2. **Configuração inicial automatizada**
   ```bash
   make setup
   ```
   
   Ou manualmente:
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Configurar Firebase**
   - Copie os arquivos de configuração Firebase
   - Configure `google-services.json` (Android)
   - Configure `GoogleService-Info.plist` (iOS)

## 🛠️ Comandos de Desenvolvimento

### Usando Makefile (Recomendado)

```bash
# Desenvolvimento
make dev              # Executar app em modo debug
make clean           # Limpar projeto
make get             # Instalar dependências

# Qualidade de código
make format          # Formatar código
make analyze         # Análise estática
make test            # Executar testes
make check           # Análise completa + testes

# Build
make build-apk       # Gerar APK release
make build-bundle    # Gerar App Bundle
make build-web       # Build para web

# Utilitários
make doctor          # Flutter doctor
make deps            # Ver dependências
make outdated        # Dependências desatualizadas
```

### Comandos Flutter Diretos

```bash
# Desenvolvimento
flutter run --debug
flutter run --profile
flutter run --release

# Testes
flutter test --coverage
flutter test test/specific_test.dart

# Build
flutter build apk --release
flutter build appbundle --release
flutter build web --release

# Análise
flutter analyze
dart format --set-exit-if-changed .
```

## 📁 Estrutura do Projeto

```
lib/
├── main.dart                 # Entry point
├── core/                    # Core functionality
│   ├── constants/          # App constants
│   │   ├── app_constants.dart
│   │   ├── firebase_constants.dart
│   │   └── ui_constants.dart
│   ├── config/            # Environment configs
│   │   └── app_config.dart
│   ├── errors/            # Error handling
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   └── utils/             # Utilities
│       └── app_logger.dart
├── models/                 # Data models
│   ├── cow.dart
│   ├── production_record.dart
│   └── user_subscription.dart
├── repositories/          # Data access layer
│   ├── cow_repository.dart
│   ├── production_repository.dart
│   └── impl/
│       ├── firebase_cow_repository.dart
│       └── firebase_production_repository.dart
├── controllers/           # Business logic
├── services/              # App services
├── screens/               # UI screens
└── widgets/               # Reusable widgets
```

## 🧪 Testes

### Executar Testes

```bash
# Todos os testes
make test

# Testes específicos
flutter test test/models/cow_test.dart
flutter test test/repositories/

# Com cobertura
flutter test --coverage
```

### Estrutura de Testes

```
test/
├── helpers/
│   └── test_helpers.dart    # Test utilities
├── models/                  # Model tests
├── repositories/            # Repository tests
├── services/               # Service tests
└── widgets/                # Widget tests
```

### Escrevendo Testes

```dart
import 'package:flutter_test/flutter_test.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('Feature Tests', () {
    setUp(() {
      // Setup comum
    });
    
    test('should do something', () {
      // Arrange
      final data = TestBuilders.buildCowData();
      
      // Act
      final result = doSomething(data);
      
      // Assert
      expect(result, isNotNull);
    });
  });
}
```

## 🎨 Padrões de Código

### Naming Conventions

```dart
// Classes - PascalCase
class CowRepository {}

// Variables/Methods - camelCase
String cowName;
void calculateTotal() {}

// Constants - camelCase
static const maxCowsPerUser = 100;

// Files - snake_case
cow_repository.dart
firebase_cow_repository.dart
```

### Code Organization

```dart
// Import order
import 'dart:async';           // Dart imports
import 'dart:io';

import 'package:flutter/material.dart';  // Flutter imports

import 'package:third_party/lib.dart';   // Third party

import '../models/cow.dart';              // Relative imports
import '../services/database_service.dart';
```

### Widget Structure

```dart
class ExampleWidget extends StatelessWidget {
  const ExampleWidget({
    super.key,
    required this.title,
    this.subtitle,
  });
  
  final String title;
  final String? subtitle;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title),
        if (subtitle != null) Text(subtitle!),
      ],
    );
  }
}
```

## 🔧 Configurações do VS Code

### Extensões Recomendadas
- Dart & Flutter (dart-code)
- GitLens
- TODO Tree
- Material Icon Theme

### Tasks Disponíveis
- `Flutter: Get Dependencies`
- `Flutter: Clean`
- `Flutter: Analyze`
- `Flutter: Test`
- `Flutter: Format`
- `Flutter: Full Check`

### Debug Configurations
- Flutter Debug
- Flutter Debug (Profile)
- Flutter Debug (Release)
- Flutter Test
- Flutter Web Debug

## 🔥 Firebase

### Collections Structure

```
users/
├── {userId}/
│   ├── profile: UserProfile
│   ├── subscription: UserSubscription
│   └── preferences: UserPreferences

cows/
└── {cowId}: Cow

productions/
└── {productionId}: ProductionRecord
```

### Security Rules
```javascript
// Example rule
match /cows/{cowId} {
  allow read, write: if request.auth != null 
    && request.auth.uid == resource.data.userId;
}
```

### Environment Configuration

```dart
// lib/core/config/app_config.dart
const config = AppConfig.dev(
  firebaseConfig: FirebaseConfig(
    projectId: 'dev-project',
    useEmulators: true,
  ),
);
```

## 📊 Performance

### Best Practices Implemented

1. **Caching**
   - In-memory cache for frequent data
   - TTL-based invalidation
   - Local storage persistence

2. **UI Optimization**
   - Skeleton loading
   - Lazy loading lists
   - Image optimization
   - Efficient rebuilds

3. **Database**
   - Optimized queries
   - Composite indexes
   - Pagination
   - Batch operations

### Monitoring

```dart
// Performance logging
AppLogger.performance.info(
  'Operation completed',
  extra: {'duration': duration.inMilliseconds},
);
```

## 🐛 Debug & Troubleshooting

### Common Issues

1. **Build failures**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Firebase connection**
   ```bash
   # Check configurations
   firebase projects:list
   firebase use <project-id>
   ```

3. **Dependencies conflicts**
   ```bash
   flutter pub deps
   flutter pub upgrade
   ```

### Debugging Tools

```dart
// Debug logging
AppLogger.debug.info('Debug info: $data');

// Network debugging
AppLogger.network.info('API Call', extra: {
  'url': url,
  'method': method,
  'duration': duration,
});
```

## 📈 Continuous Integration

### GitHub Actions (Example)

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: make check
```

## 🚀 Deployment

### Release Process

1. **Version bump**
   ```bash
   # Update pubspec.yaml version
   flutter pub get
   ```

2. **Build release**
   ```bash
   make build-apk
   make build-bundle
   ```

3. **Deploy Firebase**
   ```bash
   firebase deploy
   ```

### Environment Management

```bash
# Development
flutter run --flavor development

# Staging  
flutter run --flavor staging

# Production
flutter run --flavor production
```

## 📚 Resources

### Documentation
- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Guide](https://dart.dev/guides)

### Architecture
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter Architecture Patterns](https://flutter.dev/docs/development/data-and-backend/state-mgmt/options)

---

## 🤝 Contributing

1. Fork o projeto
2. Crie uma feature branch (`git checkout -b feature/amazing-feature`)
3. Commit suas mudanças (`git commit -m 'Add amazing feature'`)
4. Push para a branch (`git push origin feature/amazing-feature`)
5. Abra um Pull Request

### Code Review Checklist

- [ ] Código segue padrões estabelecidos
- [ ] Testes adicionados/atualizados
- [ ] Documentação atualizada
- [ ] Performance considerada
- [ ] Segurança validada
- [ ] Acessibilidade verificada
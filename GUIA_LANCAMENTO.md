# 🚀 Guia de Configuração para Lançamento - Leite+

## 📱 1. Alterando o Nome do App

### Android
Edite o arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:label="Leite+"  <!-- Nome que aparece no telefone -->
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher">
```

### iOS
Edite o arquivo `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>Leite+</string>
<key>CFBundleName</key>
<string>Leite+</string>
```

## 🎨 2. Alterando o Ícone do App

### Método Recomendado: Flutter Launcher Icons

1. **Instale o pacote** (já incluído no pubspec.yaml):
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.14.1
```

2. **Configure no pubspec.yaml**:
```yaml
flutter_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icons/app_icon.png"
  min_sdk_android: 21
  web:
    generate: true
    image_path: "assets/icons/app_icon.png"
    background_color: "#4A7C59"
    theme_color: "#4A7C59"
  windows:
    generate: true
    image_path: "assets/icons/app_icon.png"
    icon_size: 48
```

3. **Crie o ícone**:
   - Tamanho: 1024x1024 pixels
   - Formato: PNG com fundo transparente
   - Local: `assets/icons/app_icon.png`

4. **Execute o comando**:
```bash
flutter pub get
dart run flutter_launcher_icons
```

## 📝 3. Configurações Importantes para Produção

### Android - `android/app/build.gradle.kts`

```kotlin
android {
    namespace = "com.fazenda.leitemais"  // Mude para seu pacote único
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.fazenda.leitemais"  // ID único no Play Store
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = 1  // Incrementar a cada versão
        versionName = "1.0.0"  // Versão visível ao usuário
    }

    signingConfigs {
        release {
            keyAlias = keystoreProperties['keyAlias']
            keyPassword = keystoreProperties['keyPassword']
            storeFile = keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword = keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.release
            shrinkResources = true
            minifyEnabled = true
        }
    }
}
```

### iOS - `ios/Runner/Info.plist`

```xml
<key>CFBundleIdentifier</key>
<string>com.fazenda.leitemais</string>
<key>CFBundleVersion</key>
<string>1</string>
<key>CFBundleShortVersionString</key>
<string>1.0.0</string>
```

## 🔐 4. Assinatura do App (Para Play Store)

### Criar Keystore (Android)

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Configurar `android/key.properties`:

```properties
storePassword=SUA_SENHA_STORE
keyPassword=SUA_SENHA_KEY
keyAlias=upload
storeFile=C:/caminho/para/upload-keystore.jks
```

## 📦 5. Builds para Produção

### Android APK/AAB
```bash
# APK para teste
flutter build apk --release

# AAB para Play Store
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release --web-renderer html
```

## 🎯 6. Configurações Específicas do Leite+

### Cores do App (já configuradas):
- **Primária**: #4A7C59 (Verde oliva suave)
- **Secundária**: #6B8E5A (Verde mais claro)
- **Background**: #FAFAFA (Cinza muito claro)

### Permissões Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## ✅ 7. Checklist Pré-Lançamento

- [ ] Nome do app alterado
- [ ] Ícone personalizado criado
- [ ] Versão e build number configurados
- [ ] Keystore criado e configurado
- [ ] Permissões verificadas
- [ ] Firebase configurado para produção
- [ ] Teste em dispositivos reais
- [ ] Build de release funcionando
- [ ] Screens/capturas de tela para loja

## 🚀 8. Próximos Passos

1. **Google Play Console**: Criar conta de desenvolvedor
2. **App Store Connect**: Conta de desenvolvedor Apple
3. **Política de Privacidade**: Criar documento
4. **Termos de Uso**: Documento legal
5. **Descrição da Loja**: Texto atrativo
6. **Screenshots**: Capturas das telas principais

---

**Nota**: Este guia cobre as configurações básicas. Para lançamento real, considere também aspectos legais, política de privacidade, e testes extensivos.
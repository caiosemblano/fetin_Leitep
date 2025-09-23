// import removido: 'package:fetin/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fetin/screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Certifique-se que este arquivo foi gerado// Arquivo gerado automaticamente
import 'package:provider/provider.dart';
import 'screens/atividades_repository.dart';
import 'services/notification_service.dart';
import 'services/production_analysis_service.dart';
import 'services/animal_growth_service.dart';
import 'services/persistent_auth_service.dart';
import 'services/backup_service.dart';
import 'services/user_service.dart';
import 'services/theme_service.dart';
import 'utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar notificações
  await NotificationService.initialize();
  await NotificationService.requestPermissions();

  // Agendar análise automática de produção
  await ProductionAnalysisService.scheduleAutomaticAnalysis();

  // Agendar verificação automática de crescimento de animais
  await AnimalGrowthService.scheduleGrowthCheck();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AtividadesRepository()),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        StreamProvider<UserSubscription>(
          create: (_) => UserService().getSubscriptionStream(),
          initialData: UserSubscription(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leite+',
      theme: themeService.lightTheme,
      darkTheme: themeService.darkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(), // Widget que verifica autenticação
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final BackupService _backupService = BackupService();
  bool _isCheckingAuth = true;
  bool _isLoggedIn = false;
  Timer? _logoutTimer;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
    _checkAuthStatus();
    _startLogoutTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoutTimer?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    // Escutar mudanças no estado de autenticação do Firebase
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      _handleAuthStateChange(user);
    });
  }

  Future<void> _handleAuthStateChange(User? user) async {
    try {
      if (user == null) {
        // Usuário deslogado
        setState(() {
          _isLoggedIn = false;
          _isCheckingAuth = false;
        });
      } else {
        // Verificar se deve manter logado
        final shouldKeep = await PersistentAuthService.shouldKeepLoggedIn();
        setState(() {
          _isLoggedIn = shouldKeep;
          _isCheckingAuth = false;
        });

        if (_isLoggedIn) {
          await PersistentAuthService.updateLastActivity();
          // Executar backup automático (sem bloquear a UI)
          _backupService
              .autoBackup()
              .then((success) {
                if (success) {
                  AppLogger.info('Backup automático criado com sucesso');
                }
              })
              .catchError((error) {
                AppLogger.error('Erro no backup automático: $error');
              });
        }
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingAuth = false;
      });
    }
  }

  void _startLogoutTimer() {
    _logoutTimer?.cancel();
    // _logoutTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
    //   _checkAutoLogout();
    // });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App voltou do background - apenas atualizar atividade
        PersistentAuthService.updateLastActivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App foi para background - atualizar última atividade
        PersistentAuthService.updateLastActivity();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _checkAuthStatus() async {
    try {
      final shouldKeep = await PersistentAuthService.shouldKeepLoggedIn();
      final currentUser = FirebaseAuth.instance.currentUser;

      setState(() {
        _isLoggedIn = shouldKeep && currentUser != null;
        _isCheckingAuth = false;
      });

      if (_isLoggedIn) {
        // Atualizar última atividade
        await PersistentAuthService.updateLastActivity();
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingAuth = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando autenticação...'),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}

// import removido: 'package:fetin/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fetin/screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Certifique-se que este arquivo foi gerado// Arquivo gerado automaticamente
import 'package:provider/provider.dart';
import 'screens/atividades_repository.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AtividadesRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Leite+',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
          primary: Colors.blue[800], // Cor primária mais escura
          secondary: Colors.blue[600],
          surface: Colors.white,
          // background: Colors.white, // Removido por ser deprecated
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue, // Cor para item selecionado
          unselectedItemColor: Colors.grey, // Cor para itens não selecionados
          elevation: 10,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
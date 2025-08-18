import 'package:fetin/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:fetin/screens/auth/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Certifique-se que este arquivo foi gerado// Arquivo gerado automaticamente

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fetin App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // Inicia com a tela de login
      home: const LoginScreen(),
      routes: {
        '/home': (context) =>
            const MyHomePage(title: 'Fetin Home'), // Corrigi para HomeScreen ao invés de MyHomePage
      },
    );
  }
}

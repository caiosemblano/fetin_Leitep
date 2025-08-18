import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Adicionado
import 'package:fetin/services/auth_service.dart';
import 'package:fetin/widgets/auth/auth_header.dart'; // Adicionado
import 'package:fetin/widgets/auth/auth_text_field.dart'; // Adicionado
import 'package:fetin/widgets/auth/auth_button.dart'; // Adicionado
import 'package:fetin/screens/auth/register_screen.dart'; // Adicionado
import 'package:fetin/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String error = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Preencha e-mail e senha');
      return;
    }

    User? user = await _auth.signIn(email, password);
    if (!mounted) return;
    if (user != null) {
      // Login bem-sucedido
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() => error = 'Falha no login. Verifique suas credenciais.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Entre na sua conta',
                subtitle: 'Coloque seu e-mail e senha para fazer login',
              ),
              
              AuthTextField(
                hintText: 'login (e-mail)',
                controller: emailController,
              ),
              const SizedBox(height: 24),
              
              AuthTextField(
                hintText: 'senha',
                obscureText: true,
                controller: passwordController,
              ),
              const SizedBox(height: 47),
              
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              
              AuthButton(
                text: 'Continuar',
                onPressed: _login,
              ),
              const SizedBox(height: 24),
              
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text(
                  'Não tem uma conta? Registre-se',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
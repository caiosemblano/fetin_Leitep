import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Adicionado para ServerValue
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/auth/auth_header.dart';
import '../../widgets/auth/auth_button.dart';
import '../../widgets/auth/auth_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final DatabaseService _db = DatabaseService();
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  String error = '';

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() => error = 'Preencha todos os campos');
      return;
    }
    if (senha.length < 6) {
      setState(() => error = 'A senha deve ter no mínimo 6 caracteres');
      return;
    }

    try {
      final User? user = await _auth.signUp(email, senha);
      if (user != null) {
        await _db.saveUserData(user.uid, {
          'nome': nome,
          'email': email,
          'createdAt': ServerValue.timestamp,
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        unawaited(Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        ),);
      } else {
        setState(() => error = 'Erro desconhecido ao cadastrar.');
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Erro ao cadastrar';
      if (e.code == 'email-already-in-use') {
        msg = 'Este e-mail já está em uso.';
      } else if (e.code == 'invalid-email') {
        msg = 'E-mail inválido.';
      } else if (e.code == 'weak-password') {
        msg = 'A senha deve ter no mínimo 6 caracteres.';
      }
      setState(() => error = msg);
    } catch (e) {
      setState(() => error = 'Erro ao cadastrar: ${e.toString()}');
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
                title: 'Crie sua conta',
                subtitle: 'Insira seus dados e se cadastre',
              ),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(color: Colors.red),
                ),
              AuthTextField(
                hintText: 'Nome',
                controller: nomeController,
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              AuthTextField(
                hintText: 'Email@dominio.com',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),
              AuthTextField(
                hintText: 'Senha',
                obscureText: true,
                controller: senhaController,
              ),
              const SizedBox(height: 24),
              AuthButton(
                text: 'Registre-se',
                onPressed: registrar,
              ),
              const SizedBox(height: 47),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Já possui uma conta?',
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

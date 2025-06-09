import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Adicionado para ServerValue
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:fetin/services/auth_service.dart';
import 'package:fetin/services/database_service.dart';
import 'package:fetin/widgets/auth/auth_header.dart';
import 'package:fetin/widgets/auth/auth_button.dart';
import 'package:fetin/widgets/auth/auth_text_field.dart';
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
  final cpfController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  String error = '';

  // Máscara para CPF (movida para dentro da classe)
  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  // Função de validação de CPF (movida para dentro da classe)
  bool isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (cpf.length != 11) return false;
    if (RegExp(r'^(\d)\1*$').hasMatch(cpf)) return false;

    List<int> numbers = cpf.split('').map(int.parse).toList();

    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += numbers[i] * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    if (numbers[9] != firstDigit) return false;

    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += numbers[i] * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;

    return numbers[10] == secondDigit;
  }

  @override
  void dispose() {
    nomeController.dispose();
    cpfController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> registrar() async {
    final nome = nomeController.text.trim();
    final cpf = cpfController.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || cpf.isEmpty || email.isEmpty || senha.isEmpty) {
      setState(() => error = 'Preencha todos os campos');
      return;
    }

    if (!isValidCPF(cpf)) {
      setState(() => error = 'CPF inválido');
      return;
    }

    try {
      User? user = await _auth.signUp(email, senha);
      if (user != null) {
        await _db.saveUserData(user.uid, {
          'nome': nome,
          'cpf': cpf,
          'email': email,
          'createdAt': ServerValue.timestamp,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cadastro realizado com sucesso!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
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

              AuthTextField(
                hintText: 'CPF',
                controller: cpfController,
                keyboardType: TextInputType.number,
                inputFormatters: [cpfFormatter],
              ),
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
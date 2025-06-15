import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../widgets/auth/auth_common.dart';
import '../widgets/auth/auth_text_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {  
  final nomeController = TextEditingController();
  final cpfController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void dispose() {
    nomeController.dispose();
    cpfController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  void registrar() {
    final nome = nomeController.text.trim();
    final cpf = cpfController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (nome.isEmpty || cpf.isEmpty || email.isEmpty || senha.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    if (!isValidCPF(cpf)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CPF inválido')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cadastro realizado com sucesso!')),
    );
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const AuthHeader(
                title: 'Crie sua conta',
                subtitle: 'Insira seus dados e se cadastre',
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
                hintText: 'E-mail',
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
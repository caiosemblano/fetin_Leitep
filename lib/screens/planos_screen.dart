import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';

class PlanosScreen extends StatelessWidget {
  const PlanosScreen({super.key});

  // Função de simulação de upgrade
  Future<void> _simulateUpgrade(BuildContext context, String newPlan) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set(
        {
          'subscription': {'plan': newPlan, 'status': 'active'},
        },
        SetOptions(merge: true),
      );

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Upgrade para o plano $newPlan realizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upgrade: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscription = Provider.of<UserSubscription>(context);
    final currentPlan = subscription.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meu Plano',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildPlanoCard(
              context: context,
              title: 'Básico',
              price: 'Grátis',
              features: [
                'Até 5 vacas cadastradas',
                'Controle básico de produção',
                'Relatórios simples',
                'Funcionalidades limitadas',
              ],
              isCurrent: currentPlan == 'basic',
              onSelect: () => _simulateUpgrade(context, 'basic'),
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildPlanoCard(
              context: context,
              title: 'Intermediário',
              price: r'R$ 59,90/mês',
              features: [
                'Até 50 vacas cadastradas',
                'Controle completo de produção',
                'Controle financeiro detalhado',
                'Alertas de reprodução e saúde',
                'Relatórios avançados',
                'Backup automático',
              ],
              isCurrent: currentPlan == 'intermediario',
              onSelect: () => _simulateUpgrade(context, 'intermediario'),
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildPlanoCard(
              context: context,
              title: 'Premium',
              price: r'R$ 109,90/mês',
              features: [
                'Vacas ilimitadas',
                'Todas as funcionalidades',
                'Análises preditivas avançadas',
                'Relatórios personalizados',
                'Integração com sistemas externos',
                'Suporte prioritário 24/7',
                'Consultoria especializada',
              ],
              isCurrent: currentPlan == 'premium',
              onSelect: () => _simulateUpgrade(context, 'premium'),
              color: Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanoCard({
    required BuildContext context,
    required String title,
    required String price,
    required List<String> features,
    required bool isCurrent,
    required VoidCallback onSelect,
    required Color color,
  }) {
    return Card(
      elevation: isCurrent ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent ? BorderSide(color: color, width: 3) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Divider(height: 24),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(feature),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.check),
                      label: const Text('Seu Plano Atual'),
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: color,
                        side: BorderSide(color: color),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: onSelect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Selecionar Plano'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

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
        title: const Text('Meu Plano'),
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
                'Controle de produção e rebanho',
                'Histórico de coletas',
                'Registro simples de gastos',
              ],
              isCurrent: currentPlan == 'basic',
              onSelect: () => _simulateUpgrade(context, 'basic'),
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            _buildPlanoCard(
              context: context,
              title: 'Intermediário',
              price: 'R\$ 29,90/mês',
              features: [
                'Tudo do plano Básico',
                'Controle financeiro detalhado',
                'Alertas de reprodução e saúde',
                'Relatórios simplificados',
              ],
              isCurrent: currentPlan == 'intermediario',
              onSelect: () => _simulateUpgrade(context, 'intermediario'),
              color: Colors.teal,
            ),
            const SizedBox(height: 16),
            _buildPlanoCard(
              context: context,
              title: 'Premium',
              price: 'R\$ 59,90/mês',
              features: [
                'Tudo do plano Intermediário',
                'Relatórios avançados',
                'Integração com softwares contábeis',
                'Suporte prioritário',
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
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
                    Expanded(child: Text(feature)),
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

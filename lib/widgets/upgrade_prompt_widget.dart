import 'package:flutter/material.dart';
import '../screens/planos_screen.dart';

class UpgradePromptWidget extends StatelessWidget {
  const UpgradePromptWidget({
    super.key,
    required this.featureName,
    required this.description,
    required this.requiredPlan,
  });
  final String featureName;
  final String description;
  final String requiredPlan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 60, color: Colors.amber[700]),
              const SizedBox(height: 16),
              Text(
                featureName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PlanosScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.star),
                label: Text('Fazer Upgrade para o Plano $requiredPlan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
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

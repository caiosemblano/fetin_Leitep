import 'package:flutter/material.dart';
import '../services/cache_service.dart';

class PerformanceReportWidget extends StatelessWidget {
  const PerformanceReportWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.speed, color: Colors.green),
        title: const Text('Relatório de Performance'),
        subtitle: const Text('Estatísticas do cache e otimizações'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCacheStats(context),
                const SizedBox(height: 16),
                _buildOptimizationsList(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheStats(BuildContext context) {
    final stats = CacheService.getStats();
    final hitRate = (stats['hitRate'] * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Estatísticas do Cache',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '🎯 Taxa de Acerto',
                '$hitRate%',
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '📦 Itens Válidos',
                '${stats['valid']}',
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '📋 Total de Itens',
                '${stats['total']}',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '⏱️ Expirados',
                '${stats['expired']}',
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context, String title, String value, Color color,) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationsList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🚀 Otimizações Implementadas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const _OptimizationItem(
          icon: Icons.memory,
          title: 'Cache Inteligente',
          description: 'Reduz consultas ao Firestore com TTL automático',
          benefit: 'Até 80% menos requests',
        ),
        const _OptimizationItem(
          icon: Icons.animation,
          title: 'Navegação Fluida',
          description: 'PageView com animações suaves',
          benefit: 'Transições de 300ms',
        ),
        const _OptimizationItem(
          icon: Icons.search,
          title: 'Busca com Debounce',
          description: 'Evita múltiplas filtragens durante digitação',
          benefit: 'Delay de 300ms',
        ),
        const _OptimizationItem(
          icon: Icons.view_comfortable,
          title: 'Loading Skeleton',
          description: 'Feedback visual durante carregamento',
          benefit: 'Melhor UX percebida',
        ),
        const _OptimizationItem(
          icon: Icons.refresh,
          title: 'Pull-to-Refresh',
          description: 'Atualização manual dos dados quando necessário',
          benefit: 'Controle do usuário',
        ),
      ],
    );
  }
}

class _OptimizationItem extends StatelessWidget {
  const _OptimizationItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.benefit,
  });
  final IconData icon;
  final String title;
  final String description;
  final String benefit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '✨ $benefit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

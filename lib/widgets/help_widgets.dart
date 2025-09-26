import 'package:flutter/material.dart';

class QuickHelpDialog extends StatelessWidget {
  final String feature;

  const QuickHelpDialog({
    super.key,
    required this.feature,
  });

  @override
  Widget build(BuildContext context) {
    final helpContent = _getHelpContent(feature);

    return AlertDialog(
      title: Row(
        children: [
          Icon(helpContent['icon'] as IconData, color: Colors.green),
          const SizedBox(width: 8),
          Text(helpContent['title'] as String),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              helpContent['description'] as String,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dicas:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...(helpContent['tips'] as List<String>).map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Colors.amber,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Entendi'),
        ),
      ],
    );
  }

  Map<String, dynamic> _getHelpContent(String feature) {
    switch (feature.toLowerCase()) {
      case 'dashboard':
        return {
          'icon': Icons.dashboard,
          'title': 'Dashboard',
          'description':
              'O Dashboard é sua central de controle, mostrando um resumo geral da sua fazenda com gráficos interativos e indicadores importantes.',
          'tips': [
            'Os gráficos são interativos - toque para ver detalhes',
            'Use o seletor de período para analisar diferentes épocas',
            'Cores verde/amarelo/vermelho indicam status da produção',
            'Dados são atualizados automaticamente a cada 5 minutos',
          ],
        };

      case 'vacas':
        return {
          'icon': Icons.pets,
          'title': 'Gestão de Vacas',
          'description':
              'Aqui você gerencia todo seu rebanho, podendo cadastrar, editar e acompanhar cada animal individualmente.',
          'tips': [
            'Use a busca para encontrar vacas rapidamente',
            'Mantenha os dados atualizados para análises precisas',
            'O status de lactação afeta os cálculos de produção',
            'Cores dos cards indicam performance de cada vaca',
          ],
        };

      case 'producao':
        return {
          'icon': Icons.water_drop,
          'title': 'Registro de Produção',
          'description':
              'Registre diariamente a produção de leite de cada vaca. Estes dados alimentam todos os relatórios e análises.',
          'tips': [
            'Registre a produção sempre no mesmo horário',
            'Valores muito diferentes do normal geram alertas',
            'Use vírgula para decimais (ex: 15,5 litros)',
            'Registros podem ser editados posteriormente',
          ],
        };

      case 'alertas':
        return {
          'icon': Icons.notifications,
          'title': 'Sistema de Alertas',
          'description':
              'O sistema monitora automaticamente sua fazenda e envia notificações quando detecta situações que precisam de atenção.',
          'tips': [
            'Configure os tipos de alerta nas Configurações',
            'Alertas não visualizados ficam destacados',
            'Use a análise manual para verificar problemas',
            'Alertas ajudam a prevenir perdas de produção',
          ],
        };

      case 'relatorios':
        return {
          'icon': Icons.analytics,
          'title': 'Relatórios',
          'description':
              'Análise completa da sua fazenda com gráficos detalhados e possibilidade de exportação dos dados.',
          'tips': [
            'Selecione períodos específicos para análise',
            'Gráficos são interativos e zoomáveis',
            'Exporte dados para planilhas externas',
            'Compare performance entre diferentes períodos',
          ],
        };

      case 'financeiro':
        return {
          'icon': Icons.attach_money,
          'title': 'Gestão Financeira',
          'description':
              'Controle suas receitas e despesas, mantendo o controle financeiro da fazenda com relatórios detalhados.',
          'tips': [
            'Categorize transações para melhor organização',
            'Registre todas as despesas, mesmo pequenas',
            'Use as previsões para planejamento futuro',
            'Exporte dados para seu contador',
          ],
        };

      case 'configuracoes':
        return {
          'icon': Icons.settings,
          'title': 'Configurações',
          'description':
              'Personalize o app de acordo com suas necessidades, configurando alertas, backup e preferências gerais.',
          'tips': [
            'Configure backup automático para segurança',
            'Ajuste alertas conforme sua rotina',
            'Ative notificações push para não perder informações',
            'Configure limites de acordo com seu rebanho',
          ],
        };

      case 'planos':
        return {
          'icon': Icons.star,
          'title': 'Planos Premium',
          'description':
              'Desbloqueie recursos avançados como relatórios detalhados, gestão financeira completa e análises preditivas.',
          'tips': [
            'Plano Básico: funcionalidades essenciais gratuitas',
            'Plano Intermediário: relatórios avançados',
            'Plano Premium: recursos completos + suporte prioritário',
            'Teste grátis disponível para todos os planos',
          ],
        };

      case 'backup':
        return {
          'icon': Icons.cloud_upload,
          'title': 'Backup e Segurança',
          'description':
              'Seus dados são automaticamente salvos na nuvem para máxima segurança e disponibilidade.',
          'tips': [
            'Backup automático diário dos seus dados',
            'Restauração rápida em caso de problemas',
            'Dados criptografados para sua segurança',
            'Acesse seus dados de qualquer dispositivo',
          ],
        };

      default:
        return {
          'icon': Icons.help,
          'title': 'Ajuda Geral',
          'description':
              'O pLeite é um sistema completo para gestão de fazendas leiteiras, desenvolvido especialmente para produtores rurais.',
          'tips': [
            'Explore todas as funcionalidades gradualmente',
            'Use os tutoriais em vídeo para aprender',
            'Entre em contato com suporte quando necessário',
            'Mantenha o app sempre atualizado',
          ],
        };
    }
  }

  /// Método estático para mostrar ajuda rápida
  static void show(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => QuickHelpDialog(feature: feature),
    );
  }
}

/// Widget de botão de ajuda contextual
class ContextualHelpButton extends StatelessWidget {
  final String feature;
  final double size;

  const ContextualHelpButton({
    super.key,
    required this.feature,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.help_outline,
        size: size,
        color: Colors.green[600],
      ),
      onPressed: () => QuickHelpDialog.show(context, feature),
      tooltip: 'Ajuda sobre $feature',
    );
  }
}

/// Widget de tooltip de ajuda
class HelpTooltip extends StatelessWidget {
  final Widget child;
  final String helpText;
  final String? feature;

  const HelpTooltip({
    super.key,
    required this.child,
    required this.helpText,
    this.feature,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: feature != null
          ? () => QuickHelpDialog.show(context, feature!)
          : null,
      child: Tooltip(
        message: helpText,
        child: child,
      ),
    );
  }
}
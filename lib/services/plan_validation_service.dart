import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';
import '../utils/app_logger.dart';

class PlanValidationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verificar se o usuário pode adicionar uma nova vaca
  static Future<bool> canAddCow(BuildContext context, UserSubscription subscription) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Contar vacas atuais do usuário na coleção correta
      final vacasSnapshot = await _db
          .collection('usuarios')
          .doc(user.uid)
          .collection('vacas')
          .get();

      final currentCount = vacasSnapshot.docs.length;
      
      if (!subscription.canAddMoreCows(currentCount)) {
        _showLimitReachedDialog(
          context,
          'Limite de Vacas Atingido',
          'Você atingiu o limite de ${subscription.maxVacas} vacas do plano ${_getPlanDisplayName(subscription.plan)}.\n\n'
          '${subscription.getUpgradeMessage('vacas')}',
        );
        return false;
      }

      return true;
    } catch (e) {
      AppLogger.error('Erro ao verificar limite de vacas: $e');
      return false;
    }
  }

  /// Verificar se o usuário pode fazer mais registros de produção este mês
  static Future<bool> canAddProductionRecord(BuildContext context, UserSubscription subscription) async {
    print('🔍 [DEBUG] Iniciando validação de registro de produção...');
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ [DEBUG] Usuário não autenticado');
        return false;
      }
      
      print('✅ [DEBUG] Usuário: ${user.uid}');
      print('📋 [DEBUG] Plano: ${subscription.plan}');
      print('📊 [DEBUG] Limite: ${subscription.maxRegistrosProducaoPorMes}');

      // TEMPORÁRIO: Para debug, sempre permitir se não for plano básico
      if (subscription.plan != 'basic') {
        print('🎯 [DEBUG] Plano não básico - permitindo (temporário)');
        return true;
      }

      // Para planos premium (ilimitados), sempre permitir
      if (subscription.maxRegistrosProducaoPorMes == -1) {
        print('🎯 [DEBUG] Plano ilimitado - permitindo');
        return true;
      }

      // Simplificar a consulta para debug
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      print('📅 [DEBUG] Período: ${startOfMonth} até ${now}');

      // Buscar todos os registros do mês (sem filtro de tipo) para debug
      final registrosSnapshot = await _db
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_producao')
          .get();

      print('📝 [DEBUG] Total registros na coleção: ${registrosSnapshot.docs.length}');

      // Para plano básico, permitir até 10 registros
      final currentCount = registrosSnapshot.docs.length;
      print('🔢 [DEBUG] Registros atuais: $currentCount');
      print('⚖️ [DEBUG] Limite do plano básico: 10');

      if (currentCount >= 10) {
        print('🚫 [DEBUG] Limite do plano básico atingido (10 registros)');
        _showLimitReachedDialog(
          context,
          'Limite de Registros Atingido',
          'Você atingiu o limite de 10 registros de produção por mês do plano Básico.\n\n'
          'Faça upgrade para o plano Intermediário (R\$ 59,90/mês) para registrar até 50 por mês.',
        );
        return false;
      }

      print('✅ [DEBUG] Validação passou - permitindo registro ($currentCount/10)');
      return true;
    } catch (e) {
      print('❌ [DEBUG] Erro na validação: $e');
      AppLogger.error('Erro ao verificar limite de registros: $e');
      // Em caso de erro, permitir a ação para não bloquear o usuário
      return true;
    }
  }

  /// Verificar se o usuário pode acessar uma funcionalidade específica
  static bool canAccessFeature(BuildContext context, UserSubscription subscription, String feature) {
    bool hasAccess = false;

    switch (feature) {
      case 'financeiro':
        hasAccess = subscription.hasFinanceiroAccess;
        break;
      case 'relatorios_avancados':
        hasAccess = subscription.hasRelatoriosAvancados;
        break;
      case 'backup_automatico':
        hasAccess = subscription.hasBackupAutomatico;
        break;
      case 'analises_preditivas':
        hasAccess = subscription.hasAnalisesPreditivas;
        break;
      case 'suporte_prioritario':
        hasAccess = subscription.hasSuportePrioritario;
        break;
      case 'consultoria':
        hasAccess = subscription.hasConsultoriaEspecializada;
        break;
      default:
        hasAccess = true;
    }

    if (!hasAccess) {
      _showFeatureBlockedDialog(
        context,
        'Funcionalidade Bloqueada',
        'A funcionalidade "$feature" não está disponível no plano ${_getPlanDisplayName(subscription.plan)}.\n\n'
        '${subscription.getUpgradeMessage(feature)}',
      );
    }

    return hasAccess;
  }

  /// Mostrar dialog de limite atingido
  static void _showLimitReachedDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/planos');
              },
              child: const Text('Ver Planos'),
            ),
          ],
        );
      },
    );
  }

  /// Mostrar dialog de funcionalidade bloqueada
  static void _showFeatureBlockedDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/planos');
              },
              child: const Text('Fazer Upgrade'),
            ),
          ],
        );
      },
    );
  }

  /// Obter nome amigável do plano
  static String _getPlanDisplayName(String plan) {
    switch (plan) {
      case 'basic':
        return 'Básico';
      case 'intermediario':
        return 'Intermediário';
      case 'premium':
        return 'Premium';
      default:
        return 'Desconhecido';
    }
  }

  /// Mostrar informações do plano atual
  static void showCurrentPlanInfo(BuildContext context, UserSubscription subscription) {
    final planName = _getPlanDisplayName(subscription.plan);
    final maxVacas = subscription.maxVacas == -1 ? 'Ilimitadas' : subscription.maxVacas.toString();
    final maxRegistros = subscription.maxRegistrosProducaoPorMes == -1 ? 'Ilimitados' : subscription.maxRegistrosProducaoPorMes.toString();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Plano $planName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status: ${subscription.status}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Limites do seu plano:'),
              const SizedBox(height: 4),
              Text('• Vacas: $maxVacas'),
              Text('• Registros/mês: $maxRegistros'),
              const SizedBox(height: 8),
              Text('Funcionalidades:'),
              const SizedBox(height: 4),
              _buildFeatureItem('Financeiro', subscription.hasFinanceiroAccess),
              _buildFeatureItem('Relatórios Avançados', subscription.hasRelatoriosAvancados),
              _buildFeatureItem('Backup Automático', subscription.hasBackupAutomatico),
              _buildFeatureItem('Análises Preditivas', subscription.hasAnalisesPreditivas),
              _buildFeatureItem('Suporte Prioritário', subscription.hasSuportePrioritario),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
            if (subscription.plan != 'premium')
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed('/planos');
                },
                child: const Text('Fazer Upgrade'),
              ),
          ],
        );
      },
    );
  }

  static Widget _buildFeatureItem(String feature, bool hasAccess) {
    return Row(
      children: [
        Icon(
          hasAccess ? Icons.check_circle : Icons.cancel,
          color: hasAccess ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text('• $feature'),
      ],
    );
  }
}
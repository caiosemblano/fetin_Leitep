import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';

class ProductionAnalysisService {
  static const int _daysToAnalyze = 7; // Analisar últimos 7 dias
  static const double _decreaseThreshold = 0.15; // 15% de queda
  static const double _minProductionThreshold =
      5.0; // Mínimo de 5L para considerar
  static const double _lowProductionThreshold =
      8.0; // Abaixo de 8L é considerado baixo
  static const int _minDaysForAnalysis =
      2; // Mínimo de 2 dias para análise (reduzido)

  /// Configura notificações específicas para uma vaca
  static Future<void> setIndividualCowAlert({
    required String vacaId,
    required String vacaNome,
    required double minProduction,
    required bool enabled,
    String? customMessage,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_individuais')
          .doc(vacaId)
          .set({
        'vacaId': vacaId,
        'vacaNome': vacaNome,
        'limiteMinimo': minProduction,
        'ativo': enabled,
        'mensagemCustomizada': customMessage,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true),);

      AppLogger.info('Alerta individual configurado para $vacaNome');
    } catch (e) {
      AppLogger.error('Erro ao configurar alerta individual', e);
    }
  }

  /// Verifica alertas individuais configurados
  static Future<void> _checkIndividualAlerts(
      CowProductionAnalysis analysis,) async {
    try {
      final alertDoc = await FirebaseFirestore.instance
          .collection('alertas_individuais')
          .doc(analysis.vacaId)
          .get();

      if (alertDoc.exists) {
        final alertData = alertDoc.data()!;
        final ativo = alertData['ativo'] as bool? ?? false;
        final limiteMinimo = (alertData['limiteMinimo'] as num?)?.toDouble() ??
            _lowProductionThreshold;
        final mensagemCustomizada = alertData['mensagemCustomizada'] as String?;

        if (ativo && analysis.recentAverage < limiteMinimo) {
          final String titulo = '🔔 Alerta: ${analysis.vacaNome}';
          final String corpo = mensagemCustomizada ??
              '${analysis.vacaNome} está abaixo do limite configurado (${analysis.recentAverage.toStringAsFixed(1)}L < ${limiteMinimo.toStringAsFixed(1)}L)';

          await NotificationService.showInstantNotification(
            id: analysis.vacaId.hashCode +
                10000, // ID único para alertas individuais
            title: titulo,
            body: corpo,
            payload: 'individual_alert_${analysis.vacaId}',
          );

          // Salvar histórico do alerta individual
          await FirebaseFirestore.instance
              .collection('historico_alertas_individuais')
              .add({
            'vacaId': analysis.vacaId,
            'vacaNome': analysis.vacaNome,
            'producaoAtual': analysis.recentAverage,
            'limiteConfigurado': limiteMinimo,
            'mensagem': corpo,
            'dataAlerta': FieldValue.serverTimestamp(),
          });

          AppLogger.info('Alerta individual enviado para ${analysis.vacaNome}');
        }
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar alertas individuais', e);
    }
  }

  /// Analisa a produção de todas as vacas e envia notificações se necessário
  static Future<void> analyzeAllCowsProduction() async {
    try {
      AppLogger.info('Iniciando análise de produção de todas as vacas');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.warning('Usuário não autenticado para análise');
        return;
      }

      // Buscar todas as vacas do usuário (primeiro na subcoleção)
      var vacasSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('vacas')
          .get();

      // Se não encontrou vacas na subcoleção, buscar na coleção global
      if (vacasSnapshot.docs.isEmpty) {
        vacasSnapshot = await FirebaseFirestore.instance
            .collection('vacas')
            .where('userId', isEqualTo: user.uid)
            .get();
      }

      AppLogger.info(
          'Encontradas ${vacasSnapshot.docs.length} vacas para análise',);

      final List<CowProductionAnalysis> analyses = [];
      final List<String> vacasComQueda = [];
      final List<String> vacasComBaixaProducao = [];
      int vacasAnalisadas = 0;

      for (final vacaDoc in vacasSnapshot.docs) {
        final vacaData = vacaDoc.data();
        final vacaId = vacaDoc.id;
        final vacaNome = vacaData['nome'] ?? 'Vaca sem nome';

        AppLogger.info('🐄 Analisando vaca: $vacaNome (ID: $vacaId)');

        final analysis = await _analyzeCowProduction(vacaId, vacaNome);
        if (analysis != null) {
          analyses.add(analysis);
          vacasAnalisadas++;

          AppLogger.info('✅ Análise completada para $vacaNome: $analysis');

          // Verificar alertas individuais configurados
          await _checkIndividualAlerts(analysis);

          // Verificar tipos de problemas
          if (analysis.hasSignificantDecrease) {
            vacasComQueda.add(vacaNome);
            AppLogger.info('⚠️ Queda significativa detectada em $vacaNome');
          }

          if (analysis.recentAverage < _lowProductionThreshold &&
              analysis.recentAverage >= _minProductionThreshold) {
            vacasComBaixaProducao.add(vacaNome);
            AppLogger.info('📉 Baixa produção detectada em $vacaNome');
          }
        } else {
          AppLogger.warning('❌ Análise falhou para $vacaNome');
        }
      }

      // Só enviar resumo se houver vacas para analisar
      if (vacasAnalisadas > 0) {
        await _sendAnalysisSummary(
            analyses, vacasComQueda, vacasComBaixaProducao, vacasAnalisadas,);
      } else {
        AppLogger.info('Nenhuma vaca ativa encontrada para análise');
      }

      AppLogger.info(
          'Análise de produção concluída: $vacasAnalisadas vacas analisadas',);
    } catch (e) {
      AppLogger.error('Erro na análise de produção', e);
    }
  }

  /// Analisa a produção de uma vaca específica
  static Future<CowProductionAnalysis?> _analyzeCowProduction(
      String vacaId, String vacaNome,) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.warning('Usuário não autenticado para análise de produção');
        return null;
      }

      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: _daysToAnalyze));

      // Buscar registros de produção dos últimos dias na estrutura correta
      // Simplificado para evitar índices compostos complexos
      final producaoSnapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('registros_producao')
          .where('vaca_id', isEqualTo: vacaId)
          .where('tipo', isEqualTo: 'Leite')
          .get();

      // Filtrar registros dos últimos dias no cliente para evitar índices complexos
      final relevantDocs = producaoSnapshot.docs.where((doc) {
        final data = doc.data();
        final timestamp = (data['data'] as Timestamp?)?.toDate();
        if (timestamp != null && timestamp.isAfter(startDate)) {
          AppLogger.info(
              '📅 Registro relevante para $vacaNome: ${timestamp.toString()}, Quantidade: ${data['quantidade']}',);
          return true;
        }
        return false;
      }).toList();

      if (relevantDocs.isEmpty) {
        AppLogger.warning(
            'Nenhum registro de produção encontrado para $vacaNome nos últimos $_daysToAnalyze dias',);
        return null;
      }

      AppLogger.info(
          'Encontrados ${relevantDocs.length} registros relevantes de produção para $vacaNome',);

      // Agrupar por dia e calcular médias
      final dailyProduction = <String, List<double>>{};

      for (final doc in relevantDocs) {
        final data = doc.data();
        final timestamp = (data['data'] as Timestamp).toDate();
        final quantidade = (data['quantidade'] as num?)?.toDouble() ?? 0.0;

        final dayKey =
            '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

        AppLogger.info('📊 Processando registro: $dayKey -> ${quantidade}L');

        dailyProduction.putIfAbsent(dayKey, () => []);
        dailyProduction[dayKey]!.add(quantidade);
      }

      AppLogger.info(
          '🗓️ Dias únicos encontrados para $vacaNome: ${dailyProduction.length}',);
      dailyProduction.forEach((day, quantities) {
        AppLogger.info('   $day: ${quantities.join(", ")}L');
      });

      // Calcular médias diárias
      final dailyAverages = <DateTime, double>{};
      for (final entry in dailyProduction.entries) {
        final date = DateTime.parse(entry.key);
        final average =
            entry.value.reduce((a, b) => a + b) / entry.value.length;
        dailyAverages[date] = average;
        AppLogger.info(
            '📈 Média para ${entry.key}: ${average.toStringAsFixed(2)}L',);
      }

      // Se não temos dias suficientes para análise temporal, fazer análise simples
      if (dailyAverages.length < _minDaysForAnalysis) {
        AppLogger.info(
            'Fazendo análise simples de $vacaNome com ${relevantDocs.length} registros',);

        // Análise simples: verificar apenas se a produção está muito baixa
        final totalProducao = relevantDocs.fold(
            0.0,
            (total, doc) =>
                total + ((doc.data()['quantidade'] as num?)?.toDouble() ?? 0.0),);
        final mediaSimples = totalProducao / relevantDocs.length;

        final lastRecord = relevantDocs.last.data();
        final lastDate = (lastRecord['data'] as Timestamp).toDate();

        return CowProductionAnalysis(
          vacaId: vacaId,
          vacaNome: vacaNome,
          recentAverage: mediaSimples,
          olderAverage: mediaSimples, // Mesma média para análise simples
          daysAnalyzed: 1, // Análise simples
          lastProductionDate: lastDate,
        );
      }

      // Dividir em duas metades para comparação
      final sortedDates = dailyAverages.keys.toList()..sort();
      final halfPoint = (sortedDates.length / 2).floor();

      final recentDates = sortedDates.sublist(halfPoint);
      final olderDates = sortedDates.sublist(0, halfPoint);

      final recentAverage = recentDates
              .map((date) => dailyAverages[date]!)
              .reduce((a, b) => a + b) /
          recentDates.length;

      final olderAverage = olderDates
              .map((date) => dailyAverages[date]!)
              .reduce((a, b) => a + b) /
          olderDates.length;

      final analysis = CowProductionAnalysis(
        vacaId: vacaId,
        vacaNome: vacaNome,
        recentAverage: recentAverage,
        olderAverage: olderAverage,
        daysAnalyzed: sortedDates.length,
        lastProductionDate: sortedDates.last,
      );

      // Verificar se há queda significativa
      await _checkForProductionAlert(analysis);

      return analysis;
    } catch (e) {
      AppLogger.error('Erro ao analisar produção de $vacaNome', e);
      return null;
    }
  }

  /// Verifica se deve enviar alerta de queda de produção
  static Future<void> _checkForProductionAlert(
      CowProductionAnalysis analysis,) async {
    // Calcular percentual de queda
    if (analysis.olderAverage <= _minProductionThreshold) {
      AppLogger.info(
          'Produção base muito baixa para ${analysis.vacaNome}, ignorando análise',);
      return;
    }

    final decreasePercentage =
        (analysis.olderAverage - analysis.recentAverage) /
            analysis.olderAverage;

    if (decreasePercentage >= _decreaseThreshold) {
      final decreasePercent = (decreasePercentage * 100).round();

      AppLogger.warning(
          'Queda de produção detectada para ${analysis.vacaNome}: $decreasePercent%',);

      // Enviar notificação
      await NotificationService.showInstantNotification(
        id: analysis.vacaId.hashCode,
        title: '⚠️ Alerta: Queda de Produção',
        body:
            '${analysis.vacaNome}: Produção caiu $decreasePercent% nos últimos dias (${analysis.recentAverage.toStringAsFixed(1)}L vs ${analysis.olderAverage.toStringAsFixed(1)}L)',
        payload: 'production_alert_${analysis.vacaId}',
      );

      // Salvar alerta no Firestore
      await _saveProductionAlert(analysis, decreasePercentage);
    } else {
      AppLogger.info(
          'Produção de ${analysis.vacaNome} está normal (variação: ${(decreasePercentage * 100).toStringAsFixed(1)}%)',);
    }
  }

  /// Salva o alerta no Firestore para histórico
  static Future<void> _saveProductionAlert(
      CowProductionAnalysis analysis, double decreasePercentage,) async {
    try {
      await FirebaseFirestore.instance.collection('alertas_producao').add({
        'vacaId': analysis.vacaId,
        'vacaNome': analysis.vacaNome,
        'dataAlerta': FieldValue.serverTimestamp(),
        'producaoRecente': analysis.recentAverage,
        'producaoAnterior': analysis.olderAverage,
        'percentualQueda': decreasePercentage * 100,
        'diasAnalisados': analysis.daysAnalyzed,
        'dataUltimaProducao': Timestamp.fromDate(analysis.lastProductionDate),
        'status': 'pendente', // pendente, visualizado, resolvido
      });

      AppLogger.info('Alerta de produção salvo para ${analysis.vacaNome}');
    } catch (e) {
      AppLogger.error('Erro ao salvar alerta de produção', e);
    }
  }

  /// Busca alertas pendentes
  static Future<List<Map<String, dynamic>>> getPendingAlerts() async {
    try {
      // Consulta simplificada para evitar índices complexos
      final snapshot = await FirebaseFirestore.instance
          .collection('alertas_producao')
          .where('status', isEqualTo: 'pendente')
          .get();

      // Ordenar no cliente para evitar índice composto
      final alerts = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              },)
          .toList();

      // Ordenar por dataAlerta localmente
      alerts.sort((a, b) {
        final dataA = a['dataAlerta'] as Timestamp?;
        final dataB = b['dataAlerta'] as Timestamp?;
        if (dataA == null || dataB == null) return 0;
        return dataB.compareTo(dataA); // Descending order
      });

      return alerts;
    } catch (e) {
      AppLogger.error('Erro ao buscar alertas pendentes', e);
      return [];
    }
  }

  /// Marca um alerta como visualizado
  static Future<void> markAlertAsViewed(String alertId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_producao')
          .doc(alertId)
          .update({'status': 'visualizado'});
    } catch (e) {
      AppLogger.error('Erro ao marcar alerta como visualizado', e);
    }
  }

  /// Programa análise automática (chamada diariamente)
  static Future<void> scheduleAutomaticAnalysis() async {
    try {
      // Agendar notificação para análise diária às 8h
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final scheduledTime =
          DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);

      await NotificationService.scheduleNotification(
        id: 9999, // ID fixo para análise automática
        title: '🔍 Análise Diária de Produção',
        body: 'Executando análise automática das vacas...',
        scheduledDate: scheduledTime,
        payload: 'auto_analysis',
      );

      AppLogger.info(
          'Análise automática agendada para ${scheduledTime.toString()}',);
    } catch (e) {
      AppLogger.error('Erro ao agendar análise automática', e);
    }
  }

  /// Envia resumo da análise com estatísticas e alertas
  static Future<void> _sendAnalysisSummary(
    List<CowProductionAnalysis> analyses,
    List<String> vacasComQueda,
    List<String> vacasComBaixaProducao,
    int vacasAnalisadas,
  ) async {
    try {
      String titulo = '📊 Relatório Diário de Produção';
      String corpo = '';

      if (vacasComQueda.isNotEmpty) {
        // Alertas críticos de queda
        titulo = '🚨 Alertas de Produção Detectados';
        corpo = '${vacasComQueda.length} vaca(s) com queda significativa:\n';
        for (int i = 0; i < vacasComQueda.length && i < 3; i++) {
          corpo += '• ${vacasComQueda[i]}\n';
        }
        if (vacasComQueda.length > 3) {
          corpo += '... e mais ${vacasComQueda.length - 3} vaca(s)';
        }

        await NotificationService.showInstantNotification(
          id: 8888,
          title: titulo,
          body: corpo,
          payload: 'critical_production_alerts',
        );

        // Aguardar um pouco antes da próxima notificação
        await Future.delayed(const Duration(seconds: 2));
      }

      if (vacasComBaixaProducao.isNotEmpty) {
        // Alertas de baixa produção
        await NotificationService.showInstantNotification(
          id: 8887,
          title: '⚠️ Atenção: Baixa Produção',
          body:
              '${vacasComBaixaProducao.length} vaca(s) com produção abaixo do ideal (< 8L): ${vacasComBaixaProducao.take(3).join(", ")}${vacasComBaixaProducao.length > 3 ? "..." : ""}',
          payload: 'low_production_alert',
        );

        await Future.delayed(const Duration(seconds: 2));
      }

      // Resumo geral sempre
      final mediaGeral = analyses.isNotEmpty
          ? analyses.map((a) => a.recentAverage).reduce((a, b) => a + b) /
              analyses.length
          : 0.0;

      String resumoGeral = '';
      if (vacasComQueda.isEmpty && vacasComBaixaProducao.isEmpty) {
        resumoGeral = '✅ Todas as vacas com produção normal\n';
      }

      resumoGeral += '$vacasAnalisadas vacas analisadas\n';
      resumoGeral += 'Média geral: ${mediaGeral.toStringAsFixed(1)}L/dia';

      await NotificationService.showInstantNotification(
        id: 8889,
        title: '📈 Resumo da Análise',
        body: resumoGeral,
        payload: 'daily_summary',
      );

      AppLogger.info(
          'Resumo da análise enviado: ${vacasComQueda.length} alertas críticos, ${vacasComBaixaProducao.length} baixa produção',);
    } catch (e) {
      AppLogger.error('Erro ao enviar resumo da análise', e);
    }
  }
}

class CowProductionAnalysis {
  CowProductionAnalysis({
    required this.vacaId,
    required this.vacaNome,
    required this.recentAverage,
    required this.olderAverage,
    required this.daysAnalyzed,
    required this.lastProductionDate,
  });
  final String vacaId;
  final String vacaNome;
  final double recentAverage;
  final double olderAverage;
  final int daysAnalyzed;
  final DateTime lastProductionDate;

  double get decreasePercentage =>
      olderAverage > 0 ? (olderAverage - recentAverage) / olderAverage : 0.0;

  bool get hasSignificantDecrease => decreasePercentage >= 0.15;

  @override
  String toString() {
    return 'CowProductionAnalysis(vacaNome: $vacaNome, recent: ${recentAverage.toStringAsFixed(1)}L, older: ${olderAverage.toStringAsFixed(1)}L, decrease: ${(decreasePercentage * 100).toStringAsFixed(1)}%)';
  }
}

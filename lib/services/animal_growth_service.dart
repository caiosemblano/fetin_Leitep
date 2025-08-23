import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_logger.dart';
import '../services/notification_service.dart';

class AnimalGrowthService {
  static const int _mesesParaVacaMadura = 18; // 18 meses para se tornar vaca adulta

  /// Agendar verificação automática de crescimento para todos os animais
  static Future<void> scheduleGrowthCheck() async {
    try {
      AppLogger.info('Agendando verificação de crescimento de animais');
      
      // Reagendar para executar diariamente às 9h da manhã
      final amanha = DateTime.now().add(const Duration(days: 1));
      final proximaVerificacao = DateTime(amanha.year, amanha.month, amanha.day, 9, 0);
      
      await NotificationService.scheduleNotification(
        id: 888888, // ID fixo para verificação de crescimento
        title: '🐄 Verificação de Crescimento',
        body: 'Verificando animais que podem ter se tornado vacas adultas',
        scheduledDate: proximaVerificacao,
        payload: 'animal_growth_check',
      );
      
      AppLogger.info('Verificação de crescimento agendada para $proximaVerificacao');
    } catch (e) {
      AppLogger.error('Erro ao agendar verificação de crescimento', e);
    }
  }

  /// Verificar todos os animais e promover bezerros para vacas quando apropriado
  static Future<void> checkAndPromoteAnimals() async {
    try {
      AppLogger.info('Iniciando verificação de crescimento de animais');
      
      final snapshot = await FirebaseFirestore.instance.collection('vacas').get();
      int promovidos = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final animalId = doc.id;
        
        // Verificar se é um bezerro que pode ser promovido
        if (await _shouldPromoteToAdult(data)) {
          await _promoteToAdultCow(animalId, data);
          promovidos++;
        }
      }
      
      if (promovidos > 0) {
        await _sendGrowthSummaryNotification(promovidos);
      }
      
      AppLogger.info('Verificação de crescimento concluída: $promovidos animais promovidos');
      
      // Reagendar para próxima verificação
      await scheduleGrowthCheck();
      
    } catch (e) {
      AppLogger.error('Erro na verificação de crescimento', e);
    }
  }

  /// Verificar se um animal deve ser promovido para vaca adulta
  static Future<bool> _shouldPromoteToAdult(Map<String, dynamic> animalData) async {
    try {
      // Verificar se tem campo de tipo/categoria
      final tipo = animalData['tipo'] ?? animalData['categoria'] ?? 'vaca';
      
      // Se já é vaca adulta, não precisa promover
      if (tipo == 'vaca' || tipo == 'adulta') {
        return false;
      }
      
      // Verificar se é bezerro/novilha
      if (tipo != 'bezerro' && tipo != 'bezerra' && tipo != 'novilha') {
        return false;
      }
      
      // Verificar idade ou data de nascimento
      if (animalData.containsKey('dataNascimento')) {
        final dataNascimento = (animalData['dataNascimento'] as Timestamp).toDate();
        final idade = DateTime.now().difference(dataNascimento);
        return idade.inDays >= (_mesesParaVacaMadura * 30);
      } 
      else if (animalData.containsKey('idadeMeses')) {
        final idadeMeses = animalData['idadeMeses'] as int;
        return idadeMeses >= _mesesParaVacaMadura;
      }
      else if (animalData.containsKey('idade')) {
        // Se idade está em anos
        final idadeAnos = double.tryParse(animalData['idade'].toString()) ?? 0;
        return idadeAnos >= (_mesesParaVacaMadura / 12);
      }
      
      return false;
    } catch (e) {
      AppLogger.error('Erro ao verificar se animal deve ser promovido', e);
      return false;
    }
  }

  /// Promover bezerro para vaca adulta
  static Future<void> _promoteToAdultCow(String animalId, Map<String, dynamic> animalData) async {
    try {
      final updatedData = Map<String, dynamic>.from(animalData);
      
      // Atualizar tipo/categoria
      updatedData['tipo'] = 'vaca';
      updatedData['categoria'] = 'adulta';
      
      // Atualizar status para lactação se for fêmea
      if (!updatedData.containsKey('lactacao')) {
        updatedData['lactacao'] = false; // Começa sem lactação
      }
      
      // Atualizar peso se necessário (estimativa baseada na raça)
      if (updatedData.containsKey('raca')) {
        updatedData['peso'] = _estimateAdultWeight(updatedData['raca']);
      }
      
      // Atualizar idade se necessário
      if (updatedData.containsKey('dataNascimento')) {
        final dataNascimento = (updatedData['dataNascimento'] as Timestamp).toDate();
        final idadeAnos = DateTime.now().difference(dataNascimento).inDays / 365;
        updatedData['idade'] = idadeAnos.toStringAsFixed(1);
      }
      
      // Adicionar data de promoção
      updatedData['dataPromocao'] = Timestamp.now();
      
      // Salvar no Firebase
      await FirebaseFirestore.instance
          .collection('vacas')
          .doc(animalId)
          .update(updatedData);
      
      AppLogger.info('Animal ${animalData['nome']} promovido para vaca adulta');
      
      // Notificação individual
      await NotificationService.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: '🎉 Animal Cresceu!',
        body: '${animalData['nome']} agora é uma vaca adulta!',
        payload: 'animal_promoted_$animalId',
      );
      
    } catch (e) {
      AppLogger.error('Erro ao promover animal para vaca adulta', e);
    }
  }

  /// Estimar peso adulto baseado na raça
  static String _estimateAdultWeight(String raca) {
    switch (raca.toLowerCase()) {
      case 'holandesa':
        return '650'; // kg
      case 'jersey':
        return '450'; // kg
      case 'gir':
        return '500'; // kg
      default:
        return '550'; // kg (média)
    }
  }

  /// Enviar notificação resumo do crescimento
  static Future<void> _sendGrowthSummaryNotification(int promovidos) async {
    try {
      String titulo = promovidos == 1 
          ? '🐄 1 Animal Cresceu!'
          : '🐄 $promovidos Animais Cresceram!';
      
      String corpo = promovidos == 1
          ? 'Um bezerro se tornou vaca adulta hoje!'
          : '$promovidos bezerros se tornaram vacas adultas hoje!';
      
      await NotificationService.showInstantNotification(
        id: DateTime.now().millisecondsSinceEpoch,
        title: titulo,
        body: corpo,
        payload: 'growth_summary_$promovidos',
      );
      
    } catch (e) {
      AppLogger.error('Erro ao enviar notificação de resumo de crescimento', e);
    }
  }

  /// Adicionar um novo animal (bezerro) ao sistema
  static Future<void> addNewAnimal({
    required String nome,
    required String raca,
    required String tipo, // 'bezerro', 'bezerra', 'novilha'
    required DateTime dataNascimento,
    String? peso,
    String? mae,
    String? pai,
  }) async {
    try {
      final animalData = {
        'nome': nome,
        'raca': raca,
        'tipo': tipo,
        'categoria': 'jovem',
        'dataNascimento': Timestamp.fromDate(dataNascimento),
        'idade': _calculateAgeInYears(dataNascimento).toStringAsFixed(1),
        'idadeMeses': _calculateAgeInMonths(dataNascimento),
        'peso': peso ?? _estimateYoungWeight(raca, _calculateAgeInMonths(dataNascimento)),
        'lactacao': false,
        'dataAdicao': Timestamp.now(),
      };
      
      if (mae != null) animalData['mae'] = mae;
      if (pai != null) animalData['pai'] = pai;
      
      await FirebaseFirestore.instance.collection('vacas').add(animalData);
      
      AppLogger.info('Novo animal adicionado: $nome ($tipo)');
      
      // Verificar se já é elegível para promoção
      if (await _shouldPromoteToAdult(animalData)) {
        // Se já deveria ser adulto, promover imediatamente
        final snapshot = await FirebaseFirestore.instance
            .collection('vacas')
            .where('nome', isEqualTo: nome)
            .where('dataNascimento', isEqualTo: animalData['dataNascimento'])
            .limit(1)
            .get();
        
        if (snapshot.docs.isNotEmpty) {
          await _promoteToAdultCow(snapshot.docs.first.id, animalData);
        }
      }
      
    } catch (e) {
      AppLogger.error('Erro ao adicionar novo animal', e);
      rethrow;
    }
  }

  /// Calcular idade em anos
  static double _calculateAgeInYears(DateTime dataNascimento) {
    return DateTime.now().difference(dataNascimento).inDays / 365;
  }

  /// Calcular idade em meses
  static int _calculateAgeInMonths(DateTime dataNascimento) {
    final agora = DateTime.now();
    return (agora.year - dataNascimento.year) * 12 + (agora.month - dataNascimento.month);
  }

  /// Estimar peso de animal jovem baseado na raça e idade
  static String _estimateYoungWeight(String raca, int idadeMeses) {
    final pesoAdulto = int.parse(_estimateAdultWeight(raca));
    final proporcaoIdade = (idadeMeses / _mesesParaVacaMadura).clamp(0.0, 1.0);
    final pesoEstimado = (pesoAdulto * 0.3) + (pesoAdulto * 0.7 * proporcaoIdade);
    return pesoEstimado.round().toString();
  }

  /// Obter lista de animais jovens (bezerros/novilhas)
  static Future<List<Map<String, dynamic>>> getYoungAnimals() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('vacas')
          .where('tipo', whereIn: ['bezerro', 'bezerra', 'novilha'])
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      AppLogger.error('Erro ao buscar animais jovens', e);
      return [];
    }
  }

  /// Obter estatísticas de crescimento
  static Future<Map<String, int>> getGrowthStats() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('vacas').get();
      
      int bezerros = 0;
      int novilhas = 0;
      int vacasAdultas = 0;
      int prontosPraPromocao = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final tipo = data['tipo'] ?? 'vaca';
        
        switch (tipo) {
          case 'bezerro':
          case 'bezerra':
            bezerros++;
            if (await _shouldPromoteToAdult(data)) prontosPraPromocao++;
            break;
          case 'novilha':
            novilhas++;
            if (await _shouldPromoteToAdult(data)) prontosPraPromocao++;
            break;
          case 'vaca':
          case 'adulta':
            vacasAdultas++;
            break;
        }
      }
      
      return {
        'bezerros': bezerros,
        'novilhas': novilhas,
        'vacasAdultas': vacasAdultas,
        'prontosPraPromocao': prontosPraPromocao,
      };
    } catch (e) {
      AppLogger.error('Erro ao obter estatísticas de crescimento', e);
      return {
        'bezerros': 0,
        'novilhas': 0,
        'vacasAdultas': 0,
        'prontosPraPromocao': 0,
      };
    }
  }
}

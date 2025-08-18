import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  bool _notificacoesAtivadas = true;
  bool _lembreteOrdenha = true;
  bool _lembreteAtividades = true;
  TimeOfDay _horarioOrdenha1 = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _horarioOrdenha2 = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _horarioAtividades = const TimeOfDay(hour: 7, minute: 0);
  List<PendingNotificationRequest> _notificacoesPendentes = [];

  @override
  void initState() {
    super.initState();
    _loadPendingNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    final notifications = await NotificationService.getPendingNotifications();
    setState(() {
      _notificacoesPendentes = notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingNotifications,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Seção: Controle Geral
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Controle Geral',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Ativar Notificações'),
                    subtitle: const Text('Habilitar todas as notificações do app'),
                    value: _notificacoesAtivadas,
                    onChanged: (value) {
                      setState(() {
                        _notificacoesAtivadas = value;
                      });
                      if (!value) {
                        NotificationService.cancelAllNotifications();
                      } else {
                        _configurarNotificacoes();
                      }
                    },
                  ),
                  if (!_notificacoesAtivadas)
                    const Padding(
                      padding: EdgeInsets.only(left: 16, top: 8),
                      child: Text(
                        'Todas as notificações foram desativadas',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Seção: Lembretes de Ordenha
          if (_notificacoesAtivadas)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lembretes de Ordenha',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Ativar Lembretes'),
                      subtitle: const Text('Notificações nos horários de ordenha'),
                      value: _lembreteOrdenha,
                      onChanged: (value) {
                        setState(() {
                          _lembreteOrdenha = value;
                        });
                        if (value) {
                          NotificationService.scheduleOrderNotifications();
                        } else {
                          NotificationService.cancelNotification(NotificationService.ordeinha1Id);
                          NotificationService.cancelNotification(NotificationService.ordeinha2Id);
                        }
                      },
                    ),
                    if (_lembreteOrdenha) ...[
                      ListTile(
                        title: const Text('Primeira Ordenha'),
                        subtitle: Text(_horarioOrdenha1.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selecionarHorario(1),
                      ),
                      ListTile(
                        title: const Text('Segunda Ordenha'),
                        subtitle: Text(_horarioOrdenha2.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selecionarHorario(2),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Seção: Lembretes de Atividades
          if (_notificacoesAtivadas)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atividades do Dia',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Lembrete Diário'),
                      subtitle: const Text('Notificação das atividades programadas'),
                      value: _lembreteAtividades,
                      onChanged: (value) {
                        setState(() {
                          _lembreteAtividades = value;
                        });
                        if (value) {
                          NotificationService.scheduleDailyActivitiesReminder();
                        } else {
                          NotificationService.cancelNotification(NotificationService.atividadesDiaId);
                        }
                      },
                    ),
                    if (_lembreteAtividades)
                      ListTile(
                        title: const Text('Horário do Lembrete'),
                        subtitle: Text(_horarioAtividades.format(context)),
                        trailing: const Icon(Icons.access_time),
                        onTap: () => _selecionarHorario(3),
                      ),
                  ],
                ),
              ),
            ),

          // Seção: Notificações Ativas
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notificações Ativas',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_notificacoesPendentes.length}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_notificacoesPendentes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Nenhuma notificação agendada',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ..._notificacoesPendentes.map((notification) {
                      return ListTile(
                        leading: const Icon(Icons.notifications_active),
                        title: Text(notification.title ?? 'Sem título'),
                        subtitle: Text(notification.body ?? 'Sem descrição'),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            NotificationService.cancelNotification(notification.id);
                            _loadPendingNotifications();
                          },
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),

          // Seção: Ações Rápidas
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.notification_add, color: Colors.green),
                    title: const Text('Testar Notificação'),
                    subtitle: const Text('Enviar uma notificação de teste'),
                    onTap: _enviarNotificacaoTeste,
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.blue),
                    title: const Text('Configurar Todas'),
                    subtitle: const Text('Ativar todas as notificações padrão'),
                    onTap: _configurarNotificacoes,
                  ),
                  ListTile(
                    leading: const Icon(Icons.clear_all, color: Colors.red),
                    title: const Text('Cancelar Todas'),
                    subtitle: const Text('Remover todas as notificações'),
                    onTap: _cancelarTodasNotificacoes,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selecionarHorario(int tipo) async {
    TimeOfDay? novoHorario;
    
    switch (tipo) {
      case 1:
        novoHorario = await showTimePicker(
          context: context,
          initialTime: _horarioOrdenha1,
        );
        if (novoHorario != null) {
          setState(() => _horarioOrdenha1 = novoHorario!);
          _atualizarNotificacaoOrdenha();
        }
        break;
      case 2:
        novoHorario = await showTimePicker(
          context: context,
          initialTime: _horarioOrdenha2,
        );
        if (novoHorario != null) {
          setState(() => _horarioOrdenha2 = novoHorario!);
          _atualizarNotificacaoOrdenha();
        }
        break;
      case 3:
        novoHorario = await showTimePicker(
          context: context,
          initialTime: _horarioAtividades,
        );
        if (novoHorario != null) {
          setState(() => _horarioAtividades = novoHorario!);
          _atualizarNotificacaoAtividades();
        }
        break;
    }
  }

  void _atualizarNotificacaoOrdenha() {
    NotificationService.cancelNotification(NotificationService.ordeinha1Id);
    NotificationService.cancelNotification(NotificationService.ordeinha2Id);
    
    if (_lembreteOrdenha) {
      NotificationService.scheduleDaily(
        id: NotificationService.ordeinha1Id,
        title: '🐄 Hora da Ordenha!',
        body: 'Primeira ordenha do dia - ${_horarioOrdenha1.format(context)}',
        hour: _horarioOrdenha1.hour,
        minute: _horarioOrdenha1.minute,
        payload: 'ordenha_1',
      );
      
      NotificationService.scheduleDaily(
        id: NotificationService.ordeinha2Id,
        title: '🐄 Hora da Ordenha!',
        body: 'Segunda ordenha do dia - ${_horarioOrdenha2.format(context)}',
        hour: _horarioOrdenha2.hour,
        minute: _horarioOrdenha2.minute,
        payload: 'ordenha_2',
      );
    }
  }

  void _atualizarNotificacaoAtividades() {
    NotificationService.cancelNotification(NotificationService.atividadesDiaId);
    
    if (_lembreteAtividades) {
      NotificationService.scheduleDaily(
        id: NotificationService.atividadesDiaId,
        title: '📅 Atividades do Dia',
        body: 'Você tem atividades programadas para hoje. Confira!',
        hour: _horarioAtividades.hour,
        minute: _horarioAtividades.minute,
        payload: 'atividades_dia',
      );
    }
  }

  void _enviarNotificacaoTeste() {
    NotificationService.showInstantNotification(
      id: 999,
      title: '🧪 Notificação de Teste',
      body: 'Esta é uma notificação de teste do Leite+!',
      payload: 'teste',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação de teste enviada!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _configurarNotificacoes() {
    setState(() {
      _notificacoesAtivadas = true;
      _lembreteOrdenha = true;
      _lembreteAtividades = true;
    });
    
    NotificationService.scheduleOrderNotifications();
    NotificationService.scheduleDailyActivitiesReminder();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Todas as notificações foram configuradas!'),
        backgroundColor: Colors.green,
      ),
    );
    
    _loadPendingNotifications();
  }

  void _cancelarTodasNotificacoes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Notificações'),
        content: const Text('Tem certeza que deseja cancelar todas as notificações?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              NotificationService.cancelAllNotifications();
              setState(() {
                _notificacoesAtivadas = false;
                _lembreteOrdenha = false;
                _lembreteAtividades = false;
              });
              Navigator.pop(context);
              _loadPendingNotifications();
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas as notificações foram canceladas!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

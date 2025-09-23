import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/theme_service.dart';
import '../services/orphan_cleanup_service.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final BackupService _backupService = BackupService();
  bool _notificacoes = true;
  bool _modoEscuro = false;
  String _unidadeMedida = 'L';
  String _moeda = 'BRL';
  TimeOfDay _horarioOrdenha1 = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _horarioOrdenha2 = const TimeOfDay(hour: 18, minute: 0);

  @override
  void initState() {
    super.initState();
    _carregarConfiguracoes();
  }

  void _carregarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final themeService = Provider.of<ThemeService>(context, listen: false);
    setState(() {
      _notificacoes = prefs.getBool('notificacoes') ?? true;
      _modoEscuro = themeService.isDarkMode;
      _unidadeMedida = prefs.getString('unidade_medida') ?? 'L';
      _moeda = prefs.getString('moeda') ?? 'BRL';
    });
  }

  void _salvarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final themeService = Provider.of<ThemeService>(context, listen: false);
    await prefs.setBool('notificacoes', _notificacoes);
    await themeService.setTheme(_modoEscuro);
    await prefs.setString('unidade_medida', _unidadeMedida);
    await prefs.setString('moeda', _moeda);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Configurações salvas!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _salvarConfiguracoes,
          ),
        ],
      ),
      body: ListView(
        children: [
          // Seção: Notificações
          const ListTile(
            title: Text(
              'Notificações',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Ativar Notificações'),
            subtitle: const Text('Receber lembretes de ordenha e cuidados'),
            value: _notificacoes,
            onChanged: (value) {
              setState(() {
                _notificacoes = value;
              });
            },
          ),

          const Divider(),

          // Seção: Aparência
          const ListTile(
            title: Text(
              'Aparência',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Tema Escuro'),
            subtitle: const Text('Ativar modo noturno'),
            value: _modoEscuro,
            onChanged: (bool value) {
              setState(() {
                _modoEscuro = value;
              });
              _salvarConfiguracoes(); // Salva e aplica imediatamente
            },
          ),

          const Divider(),

          ListTile(
            title: const Text('Horário 1ª Ordenha'),
            subtitle: Text(_horarioOrdenha1.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selecionarHorario(true),
          ),

          ListTile(
            title: const Text('Horário 2ª Ordenha'),
            subtitle: Text(_horarioOrdenha2.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () => _selecionarHorario(false),
          ),

          const Divider(),

          const Divider(),

          // Seção: Unidades
          const ListTile(
            title: Text(
              'Unidades e Medidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Unidade de Volume'),
            subtitle: Text(_unidadeMedida),
            trailing: const Icon(Icons.straighten),
            onTap: _selecionarUnidadeMedida,
          ),

          ListTile(
            title: const Text('Moeda'),
            subtitle: Text(_moeda),
            trailing: const Icon(Icons.currency_exchange),
            onTap: _selecionarMoeda,
          ),

          const Divider(),

          // Seção: Dados
          const ListTile(
            title: Text(
              'Dados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            title: const Text('Backup dos Dados'),
            subtitle: const Text('Fazer backup no Firebase'),
            trailing: const Icon(Icons.backup),
            onTap: _fazerBackup,
          ),

          ListTile(
            title: const Text('Exportar Dados'),
            subtitle: const Text('Compartilhar arquivo de backup'),
            trailing: const Icon(Icons.share),
            onTap: _exportarDados,
          ),

          ListTile(
            title: const Text('Restaurar Dados'),
            subtitle: const Text('Restaurar do último backup'),
            trailing: const Icon(Icons.restore),
            onTap: _restaurarDados,
          ),

          ListTile(
            title: const Text('Limpeza Manual (Avançado)'),
            subtitle: const Text('Remoção manual de órfãos - raramente necessário'),
            trailing: const Icon(Icons.cleaning_services, color: Colors.orange),
            onTap: _limparOrfaos,
          ),

          ListTile(
            title: const Text('Verificar Órfãos (Avançado)'),
            subtitle: const Text('Apenas verificar integridade dos dados'),
            trailing: const Icon(Icons.search, color: Colors.blue),
            onTap: _verificarOrfaos,
          ),

          const Divider(),

          // Seção: Sobre
          const ListTile(
            title: Text(
              'Sobre',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const ListTile(
            title: Text('Versão do App'),
            subtitle: Text('1.0.0'),
            trailing: Icon(Icons.info),
          ),

          ListTile(
            title: const Text('Termos de Uso'),
            trailing: const Icon(Icons.description),
            onTap: () {
              // Navegar para termos de uso
            },
          ),

          ListTile(
            title: const Text('Política de Privacidade'),
            trailing: const Icon(Icons.privacy_tip),
            onTap: () {
              // Navegar para política de privacidade
            },
          ),
        ],
      ),
    );
  }

  void _selecionarHorario(bool isPrimeiro) async {
    final horario = await showTimePicker(
      context: context,
      initialTime: isPrimeiro ? _horarioOrdenha1 : _horarioOrdenha2,
    );

    if (horario != null) {
      setState(() {
        if (isPrimeiro) {
          _horarioOrdenha1 = horario;
        } else {
          _horarioOrdenha2 = horario;
        }
      });
    }
  }

  void _selecionarUnidadeMedida() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Unidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Litros (L)'),
              value: 'L',
              groupValue: _unidadeMedida,
              onChanged: (value) {
                setState(() {
                  _unidadeMedida = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Galões'),
              value: 'GAL',
              groupValue: _unidadeMedida,
              onChanged: (value) {
                setState(() {
                  _unidadeMedida = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _selecionarMoeda() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Moeda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Real (BRL)'),
              value: 'BRL',
              groupValue: _moeda,
              onChanged: (value) {
                setState(() {
                  _moeda = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dólar (USD)'),
              value: 'USD',
              groupValue: _moeda,
              onChanged: (value) {
                setState(() {
                  _moeda = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _fazerBackup() async {
    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Criando backup...'),
            ],
          ),
        ),
      );

      final success = await _backupService.createBackup();

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Backup criado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao criar backup'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _restaurarDados() async {
    try {
      // Buscar backups disponíveis
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Buscando backups...'),
            ],
          ),
        ),
      );

      final backups = await _backupService.getAvailableBackups();

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        if (backups.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhum backup encontrado'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        // Mostrar lista de backups
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Selecionar Backup'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: backups.length,
                itemBuilder: (context, index) {
                  final backup = backups[index];
                  final timestamp =
                      backup['timestamp']?.toDate() ?? DateTime.now();

                  return ListTile(
                    leading: const Icon(Icons.backup),
                    title: Text('Backup ${index + 1}'),
                    subtitle: Text(
                      '${timestamp.day}/${timestamp.month}/${timestamp.year} '
                      '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      _confirmarRestauracao(backup['id']);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _confirmarRestauracao(String backupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Restauração'),
        content: const Text(
          'Esta ação irá substituir todos os seus dados atuais pelos dados do backup selecionado. '
          'Esta operação não pode ser desfeita.\n\n'
          'Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executarRestauracao(backupId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Restaurar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _executarRestauracao(String backupId) async {
    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Restaurando dados...'),
            ],
          ),
        ),
      );

      final success = await _backupService.restoreBackup(backupId);

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dados restaurados com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao restaurar dados'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportarDados() async {
    try {
      // Mostrar indicador de carregamento
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Exportando dados...'),
            ],
          ),
        ),
      );

      final success = await _backupService.exportToFile();

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dados exportados e compartilhados!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Erro ao exportar dados'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _limparOrfaos() async {
    // Mostrar diálogo de confirmação
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧹 Limpeza Manual de Órfãos'),
        content: const Text(
          'NOTA: A limpeza automática já remove órfãos quando vacas são excluídas.\n\n'
          'Esta limpeza manual é apenas para casos especiais e irá:\n\n'
          '• Verificar registros de produção sem vaca\n'
          '• Remover alertas de vacas inexistentes\n'
          '• Limpar backups muito antigos\n\n'
          'Recomendado apenas se houver problemas de dados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
            ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Executar Limpeza'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('🧹 Limpando dados órfãos...'),
            ],
          ),
        ),
      );

      final result = await OrphanCleanupService.performFullCleanup();

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        // Mostrar resultado detalhado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Limpeza Concluída'),
            content: SingleChildScrollView(
              child: Text(result.toString()),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro na limpeza: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verificarOrfaos() async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('🔍 Verificando órfãos...'),
            ],
          ),
        ),
      );

      final result = await OrphanCleanupService.checkOrphansOnly();

      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading

        // Mostrar resultado da verificação
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🔍 Verificação de Órfãos'),
            content: Text(
              result.totalOrphansDeleted > 0
                  ? '⚠️ Encontrados ${result.productionRecordsDeleted} registros órfãos\n\n'
                    'Use "Limpeza Manual" para removê-los.'
                  : '✅ Nenhum dado órfão encontrado!\n\nSeus dados estão organizados.',
            ),
            actions: [
              if (result.totalOrphansDeleted > 0)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _limparOrfaos();
                  },
                  child: const Text('Limpar Agora'),
                ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Fechar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro na verificação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

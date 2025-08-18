import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
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
    setState(() {
      _notificacoes = prefs.getBool('notificacoes') ?? true;
      _modoEscuro = prefs.getBool('modo_escuro') ?? false;
      _unidadeMedida = prefs.getString('unidade_medida') ?? 'L';
      _moeda = prefs.getString('moeda') ?? 'BRL';
    });
  }

  void _salvarConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificacoes', _notificacoes);
    await prefs.setBool('modo_escuro', _modoEscuro);
    await prefs.setString('unidade_medida', _unidadeMedida);
    await prefs.setString('moeda', _moeda);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configurações salvas!')),
      );
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
            title: Text('Notificações', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

          // Seção: Aparência
          const ListTile(
            title: Text('Aparência', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Modo Escuro'),
            subtitle: const Text('Usar tema escuro na aplicação'),
            value: _modoEscuro,
            onChanged: (value) {
              setState(() {
                _modoEscuro = value;
              });
            },
          ),

          const Divider(),

          // Seção: Unidades
          const ListTile(
            title: Text('Unidades e Medidas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            title: Text('Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: const Text('Backup dos Dados'),
            subtitle: const Text('Fazer backup no Google Drive'),
            trailing: const Icon(Icons.backup),
            onTap: _fazerBackup,
          ),
          
          ListTile(
            title: const Text('Restaurar Dados'),
            subtitle: const Text('Restaurar do último backup'),
            trailing: const Icon(Icons.restore),
            onTap: _restaurarDados,
          ),

          const Divider(),

          // Seção: Sobre
          const ListTile(
            title: Text('Sobre', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

  void _fazerBackup() {
    // Implementar backup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup em desenvolvimento')),
    );
  }

  void _restaurarDados() {
    // Implementar restauração
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restauração em desenvolvimento')),
    );
  }
}

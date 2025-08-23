import 'package:flutter/material.dart';
import '../services/persistent_auth_service.dart';

class AuthSettingsScreen extends StatefulWidget {
  const AuthSettingsScreen({super.key});

  @override
  State<AuthSettingsScreen> createState() => _AuthSettingsScreenState();
}

class _AuthSettingsScreenState extends State<AuthSettingsScreen> {
  bool _autoLogout = true;
  int _timeoutMinutes = 30;
  Map<String, dynamic> _authStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await PersistentAuthService.getAutoLogoutSettings();
    final status = await PersistentAuthService.getAuthStatus();
    
    setState(() {
      _autoLogout = settings['enabled'];
      _timeoutMinutes = settings['timeoutMinutes'];
      _authStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await PersistentAuthService.toggleAutoLogout(_autoLogout);
    await PersistentAuthService.setCustomTimeout(_timeoutMinutes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Configurações salvas!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _clearAuthData() async {
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🗑️ Limpar Dados'),
        content: const Text(
          'Isso irá:\n'
          '• Remover dados de login salvos\n'
          '• Fazer logout imediatamente\n'
          '• Resetar todas as preferências\n\n'
          'Deseja continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await PersistentAuthService.logout();
      if (mounted) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 Configurações de Autenticação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Salvar configurações',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status atual
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Status Atual',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatusRow('👤 Usuário:', _authStatus['userEmail'] ?? 'Não logado'),
                  _buildStatusRow('🔒 Lembrar Login:', _authStatus['rememberMe'] ? 'Sim' : 'Não'),
                  _buildStatusRow('⏰ Logout Automático:', _authStatus['autoLogout'] ? 'Ativo' : 'Inativo'),
                  _buildStatusRow('⏱️ Timeout:', '${_authStatus['timeoutMinutes']} min'),
                  if (_authStatus['lastLogin'] != null)
                    _buildStatusRow('📅 Último Login:', _formatDateTime(_authStatus['lastLogin'])),
                  if (_authStatus['lastActivity'] != null)
                    _buildStatusRow('🕐 Última Atividade:', _formatDateTime(_authStatus['lastActivity'])),
                  _buildStatusRow('🔄 Auto-verificação:', _authStatus['autoLogout'] ? 'A cada 30s' : 'Desabilitado'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Configurações de segurança
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Configurações de Segurança',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  SwitchListTile(
                    title: const Text('🔒 Logout Automático'),
                    subtitle: const Text('Deslogar após período de inatividade'),
                    value: _autoLogout,
                    onChanged: (value) {
                      setState(() => _autoLogout = value);
                    },
                  ),
                  
                  if (_autoLogout) ...[
                    const Divider(),
                    const Text('⏰ Tempo para logout automático'),
                    const SizedBox(height: 8),
                    Slider(
                      value: _timeoutMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '$_timeoutMinutes min',
                      onChanged: (value) {
                        setState(() => _timeoutMinutes = value.round());
                      },
                    ),
                    Text(
                      '$_timeoutMinutes minutos - ${_getTimeoutDescription()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    _buildTimeoutPresets(),
                  ],
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Ações
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🛠️ Ações',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  
                  ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.blue),
                    title: const Text('Atualizar Status'),
                    subtitle: const Text('Recarregar informações atuais'),
                    onTap: _loadSettings,
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.orange),
                    title: const Text('Fazer Logout'),
                    subtitle: const Text('Sair da conta atual'),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await PersistentAuthService.logout();
                      if (mounted) {
                        navigator.popUntil((route) => route.isFirst);
                      }
                    },
                  ),
                  
                  ListTile(
                    leading: const Icon(Icons.delete_forever, color: Colors.red),
                    title: const Text('Limpar Todos os Dados'),
                    subtitle: const Text('Remover dados salvos e fazer logout'),
                    onTap: _clearAuthData,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutPresets() {
    final presets = [
      {'label': '5min', 'value': 5, 'icon': '🔴', 'desc': 'Máxima segurança'},
      {'label': '15min', 'value': 15, 'icon': '🟡', 'desc': 'Alta segurança'},
      {'label': '30min', 'value': 30, 'icon': '🟢', 'desc': 'Padrão'},
      {'label': '60min', 'value': 60, 'icon': '🔵', 'desc': 'Conveniência'},
    ];

    return Wrap(
      spacing: 8,
      children: presets.map((preset) {
        final isSelected = _timeoutMinutes == preset['value'];
        return FilterChip(
          label: Text('${preset['icon']} ${preset['label']}'),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _timeoutMinutes = preset['value'] as int);
            }
          },
        );
      }).toList(),
    );
  }

  String _getTimeoutDescription() {
    if (_timeoutMinutes <= 10) return 'Máxima segurança';
    if (_timeoutMinutes <= 30) return 'Alta segurança';
    if (_timeoutMinutes <= 60) return 'Segurança moderada';
    return 'Máxima conveniência';
  }

  String _formatDateTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Agora';
      if (difference.inMinutes < 60) return '${difference.inMinutes}min atrás';
      if (difference.inHours < 24) return '${difference.inHours}h atrás';
      return '${difference.inDays} dias atrás';
    } catch (e) {
      return 'Não disponível';
    }
  }
}

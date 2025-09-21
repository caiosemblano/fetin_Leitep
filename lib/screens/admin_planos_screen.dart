import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/admin_service.dart';
import '../services/role_service.dart';
import 'package:intl/intl.dart';

class AdminPlanosScreen extends StatefulWidget {
  const AdminPlanosScreen({super.key});

  @override
  State<AdminPlanosScreen> createState() => _AdminPlanosScreenState();
}

class _AdminPlanosScreenState extends State<AdminPlanosScreen> {
  final AdminService _adminService = AdminService();
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    bool isAdmin = await RoleService.instance.isUserAdmin();
    if (!isAdmin) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Acesso negado. Apenas administradores podem acessar esta tela.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await _adminService.getAllUsersWithPlans();
    setState(() {
      _users = users;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredUsers {
    if (_filterText.isEmpty) return _users;
    return _users.where((user) {
      final email = user['email'].toString().toLowerCase();
      final name = user['name'].toString().toLowerCase();
      final plan = user['plan'].toString().toLowerCase();
      final filter = _filterText.toLowerCase();
      return email.contains(filter) ||
          name.contains(filter) ||
          plan.contains(filter);
    }).toList();
  }

  Color _getPlanColor(String plan) {
    switch (plan.toLowerCase()) {
      case 'premium':
        return Colors.purple;
      case 'intermediate':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administração de Planos'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Filtrar usuários',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _filterText = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                ? const Center(child: Text('Nenhum usuário encontrado'))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      final createdAt = (user['createdAt'] as Timestamp)
                          .toDate();
                      final formattedDate = DateFormat(
                        'dd/MM/yyyy',
                      ).format(createdAt);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(user['email']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome: ${user['name']}'),
                              Text('Criado em: $formattedDate'),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(
                              user['plan'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getPlanColor(user['plan']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPlanLegend('Básico', Colors.green),
                    _buildPlanLegend('Intermediário', Colors.blue),
                    _buildPlanLegend('Premium', Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanLegend(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'atividades_screen.dart';
import 'vacas_screen.dart';
import 'registro_producao_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const AtividadesScreen(),
    const VacasScreen(),
    const RegistroProducaoScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        }
        final shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Sair do aplicativo'),
            content: const Text('Deseja realmente sair?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leite+'),
          automaticallyImplyLeading: false,
        ),
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Atividades',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets),
                label: 'Vacas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Registros',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.blue[800],
            unselectedItemColor: Colors.grey[600],
            backgroundColor: Colors.white,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
            onTap: _onItemTapped,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import '../dashboard_page/dashboard_page.dart';
import '../perfil_page/perfil_page.dart';

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPage(),
          OrcamentosPage(),
          PerfilPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(51),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.blue[700],
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            onTap: _onTabChanged,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_outlined),
                activeIcon: Icon(Icons.account_balance),
                label: 'Orçamentos',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

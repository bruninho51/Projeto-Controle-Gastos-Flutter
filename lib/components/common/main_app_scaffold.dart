import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import '../dashboard_page/dashboard_page.dart';
import '../perfil_page/perfil_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;
  bool _railExtended = true;

  // Fonte única de verdade para os itens de navegação
  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      label: 'Dashboard',
      page: DashboardPage(),
    ),
    NavigationItem(
      icon: Icons.account_balance_outlined,
      activeIcon: Icons.account_balance,
      label: 'Orçamentos',
      page: OrcamentosPage(),
    ),
    NavigationItem(
      icon: Icons.savings_outlined,
      activeIcon: Icons.savings,
      label: 'Investimentos',
      page: InvestimentosPage(),
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Perfil',
      page: PerfilPage(),
    ),
  ];

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = kIsWeb;
    final bool useRail = isWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (useRail) _buildNavigationRail(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _navigationItems.map((item) => item.page).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      backgroundColor: Colors.white,
      extended: _railExtended,
      minExtendedWidth: 230,
      leading: Column(
        children: [
          const SizedBox(height: 16),
          IconButton(
            icon: Icon(_railExtended ? Icons.chevron_left : Icons.chevron_right),
            onPressed: () => setState(() => _railExtended = !_railExtended),
          ),
        ],
      ),
      selectedIndex: _currentIndex,
      onDestinationSelected: _onTabChanged,
      labelType: _railExtended 
          ? NavigationRailLabelType.none 
          : NavigationRailLabelType.selected,
      destinations: _navigationItems.map((item) => 
        NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.activeIcon),
          label: Text(item.label, style: TextStyle(fontSize: 16),),
        ),
      ).toList(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
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
          items: _navigationItems.map((item) => 
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon),
              label: item.label,
            ),
          ).toList(),
        ),
      ),
    );
  }
}

// Classe auxiliar para armazenar os dados de navegação
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
  });
}
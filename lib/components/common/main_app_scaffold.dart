import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';
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
          if (useRail) _buildNavigationRail(context),
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


Widget _buildNavigationRail(BuildContext context) {
  final auth = Provider.of<AuthProvider>(context);

  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(2, 0),
        ),
      ],
    ),
    child: Column(
      children: [
        // Ícone do aplicativo no topo
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 32),
          child: _railExtended 
              ? Image.asset(
                'assets/icon.png',
                width: 120, // Ícone maior na web
                height: 120,
              )
              : Image.asset(
                'assets/icon.png',
                width: 60, // Ícone maior na web
                height: 60,
              )
        ),
        
        Expanded(
          child: NavigationRail(
            backgroundColor: Colors.transparent,
            extended: _railExtended,
            minExtendedWidth: 230,
            minWidth: 70,
            leading: Column(
              children: [
                FloatingActionButton(
                  elevation: 0,
                  backgroundColor: Colors.grey[100],
                  mini: true,
                  onPressed: () => setState(() => _railExtended = !_railExtended),
                  child: Icon(
                    _railExtended ? Icons.chevron_left : Icons.menu,
                    color: Colors.indigo[700],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
              _onTabChanged(index); // Chama sua função de callback
            },
            labelType: _railExtended 
                ? NavigationRailLabelType.none 
                : NavigationRailLabelType.selected,
            destinations: _navigationItems.map((item) => 
              NavigationRailDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: Colors.indigo[700]),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.activeIcon, color: Colors.indigo[700]),
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.indigo[700],
                    ),
                  ),
                ),
              ),
            ).toList(),
          ),
        ),
        
        // Botão Sair na parte inferior
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: InkWell(
            onTap: auth.logout,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: _railExtended 
                    ? MainAxisAlignment.start 
                    : MainAxisAlignment.center,
                children: [
                  Icon(Icons.exit_to_app, color: Colors.indigo[700]),
                  if (_railExtended) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Sair',
                      style: TextStyle(
                        color: Colors.indigo[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    ),
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
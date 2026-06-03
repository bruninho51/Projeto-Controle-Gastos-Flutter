import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/app_bottom_nav.dart';
import 'package:orcamentos_app/features/shared/navigation/app_navigation_items.dart';
import 'package:orcamentos_app/features/shared/components/app_navigation_rail.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';

class MainAppScaffold extends StatefulWidget {
  const MainAppScaffold({super.key});

  @override
  State<MainAppScaffold> createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _currentIndex = 0;
  bool _railExtended = true;

  @override
  Widget build(BuildContext context) {
    final bool useRail =
        kIsWeb && MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Row(
        children: [
          if (useRail)
            AppNavigationRail(
              currentIndex: _currentIndex,
              extended: _railExtended,
              onItemSelected: (i) => setState(() => _currentIndex = i),
              onToggleExtended: () =>
                  setState(() => _railExtended = !_railExtended),
              onLogout: Provider.of<AuthState>(context, listen: false).logout,
            ),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children:
                  kNavigationItems.map((item) => item.page).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: useRail
          ? null
          : AppBottomNav(
              currentIndex: _currentIndex,
              onItemSelected: (i) => setState(() => _currentIndex = i),
            ),
    );
  }
}

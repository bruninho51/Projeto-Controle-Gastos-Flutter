import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/app_bottom_nav.dart';
import 'package:orcamentos_app/features/shared/components/web_shell.dart';
import 'package:orcamentos_app/features/shared/navigation/app_navigation_items.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';

/// Tela principal com as abas. Na web, a navegação lateral é desenhada pelo
/// [WebShell]; aqui só aparece a barra inferior (mobile ou web estreita).
class MainAppScaffold extends StatelessWidget {
  const MainAppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationController>();
    final useRail = WebShell.usaRail(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: IndexedStack(
        index: nav.currentIndex,
        children: kNavigationItems.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: useRail
          ? null
          : AppBottomNav(
              currentIndex: nav.currentIndex,
              onItemSelected: nav.select,
            ),
    );
  }
}

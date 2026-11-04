import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/shared/components/app_navigation_rail.dart';
import 'package:orcamentos_app/features/shared/navigation/app_navigation_items.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';
import 'package:provider/provider.dart';

/// Largura mínima para exibir a barra lateral na web.
const double kLarguraMinimaRail = 800;

/// Envolve o [Navigator] do app com a barra lateral na web, para que ela
/// apareça em todas as telas depois do login.
class WebShell extends StatelessWidget {
  final Widget child;

  const WebShell({super.key, required this.child});

  /// Índice do item de perfil, usado pelo card do usuário na barra lateral.
  static int? get _profileIndex {
    final i = kNavigationItems.indexWhere((e) => e.label == 'Perfil');
    return i < 0 ? null : i;
  }

  /// `true` quando a barra lateral deve ser exibida para a largura dada.
  static bool usaRail(double largura) =>
      kIsWeb && largura > kLarguraMinimaRail;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final liberado = !auth.isLoading && auth.isLoggedIn && !auth.isLocked;

    if (!liberado || !usaRail(MediaQuery.sizeOf(context).width)) return child;

    final nav = context.watch<NavigationController>();

    return Row(
      children: [
        // Material: o rail usa InkWell e fica acima do Navigator/Scaffold.
        Material(
          type: MaterialType.transparency,
          child: AppNavigationRail(
            currentIndex: nav.currentIndex,
            extended: nav.railExtended,
            onItemSelected: nav.select,
            onToggleExtended: nav.toggleRail,
            onLogout: auth.logout,
            profileIndex: _profileIndex,
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

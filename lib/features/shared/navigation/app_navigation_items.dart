import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:orcamentos_app/features/shared/navigation/navigation_item.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page.dart';
import 'package:orcamentos_app/features/notifications/pages/notifications_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import 'package:orcamentos_app/components/perfil_page/perfil_page.dart';
import 'package:orcamentos_app/features/config/pages/configuracoes_page.dart';
import 'package:orcamentos_app/features/dashboard/pages/dashboard_page.dart';

final List<NavigationItem> kNavigationItems = [
  const NavigationItem(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label: 'Início',
    page: DashboardPage(),
  ),
  const NavigationItem(
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    label: 'Orçamentos',
    page: OrcamentosPage(),
  ),
  const NavigationItem(
    icon: Icons.savings_outlined,
    activeIcon: Icons.savings_rounded,
    label: 'Invest',
    page: InvestimentosPage(),
  ),

  if (!kIsWeb)
    const NavigationItem(
      icon: Icons.notifications_outlined,
      activeIcon: Icons.notifications_rounded,
      label: 'Bancos',
      page: NotificationsPage(),
    ),

  const NavigationItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Perfil',
    page: PerfilPage(),
  ),
  const NavigationItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: 'Ajustes',
    page: ConfiguracoesPage(),
  ),
];
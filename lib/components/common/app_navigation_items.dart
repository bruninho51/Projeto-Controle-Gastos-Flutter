import 'package:flutter/material.dart';

import 'package:orcamentos_app/components/common/navigation_item.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page.dart';
import 'package:orcamentos_app/components/notificacoes_page/notificacoes_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page.dart';
import 'package:orcamentos_app/components/perfil_page/perfil_page.dart';
import 'package:orcamentos_app/features/config/pages/configuracoes_page.dart';
import 'package:orcamentos_app/features/dashboard/pages/dashboard_page.dart';

const List<NavigationItem> kNavigationItems = [
  NavigationItem(
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard_rounded,
    label: 'Início',
    page: DashboardPage(),
  ),
  NavigationItem(
    icon: Icons.account_balance_wallet_outlined,
    activeIcon: Icons.account_balance_wallet_rounded,
    label: 'Orçamentos',
    page: OrcamentosPage(),
  ),
  NavigationItem(
    icon: Icons.savings_outlined,
    activeIcon: Icons.savings_rounded,
    label: 'Invest',
    page: InvestimentosPage(),
  ),
  NavigationItem(
    icon: Icons.notifications_outlined,
    activeIcon: Icons.notifications_rounded,
    label: 'Bancos',
    page: NotificacoesPage(),
  ),
  NavigationItem(
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: 'Perfil',
    page: PerfilPage(),
  ),
  NavigationItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings,
    label: 'Ajustes',
    page: ConfiguracoesPage(),
  ),
];

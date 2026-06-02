import 'package:flutter/material.dart';

import 'package:orcamentos_app/features/dashboard/models/dashboard_card_config.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/utils/formatters.dart';

List<DashboardCardConfig> buildCardConfigs(DashboardData data) => [
      DashboardCardConfig(
        title: 'Orçamentos Ativos',
        value: data.qtdOrcamentosAtivos.toString(),
        color: const Color(0xFF3949AB),
        icon: Icons.list_alt_rounded,
        isCount: true,
      ),
      DashboardCardConfig(
        title: 'Orçamentos Encerrados',
        value: data.qtdOrcamentosEncerrados.toString(),
        color: const Color(0xFF00897B),
        icon: Icons.check_circle_outline_rounded,
        isCount: true,
      ),
      DashboardCardConfig(
        title: 'Valor Total',
        value: formatarValorDynamic(data.valorInicialAtivos),
        color: const Color(0xFF1E88E5),
        icon: Icons.attach_money_rounded,
      ),
      DashboardCardConfig(
        title: 'Valor Livre',
        value: formatarValorDynamic(data.valorLivreAtivos),
        color: const Color(0xFF43A047),
        icon: Icons.account_balance_wallet_rounded,
      ),
      DashboardCardConfig(
        title: 'Valor Atual',
        value: formatarValorDynamic(data.valorAtualAtivos),
        color: const Color(0xFF5E35B1),
        icon: Icons.pie_chart_rounded,
      ),
      DashboardCardConfig(
        title: 'Gastos Fixos',
        value: formatarValorDynamic(data.gastosFixosAtivos),
        color: const Color(0xFFE53935),
        icon: Icons.receipt_long_rounded,
      ),
      DashboardCardConfig(
        title: 'Gastos Variáveis',
        value: formatarValorDynamic(data.gastosVariaveisAtivos),
        color: const Color(0xFFF4511E),
        icon: Icons.trending_up_rounded,
      ),
      DashboardCardConfig(
        title: 'Valor Poupado',
        value: formatarValorDynamic(data.valorPoupado),
        color: const Color(0xFF039BE5),
        icon: Icons.savings_rounded,
      ),
    ];

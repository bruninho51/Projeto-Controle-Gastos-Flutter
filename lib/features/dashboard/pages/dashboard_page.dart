import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/info_state_widget.dart';
import 'package:orcamentos_app/features/dashboard/components/dashboard_card_grid.dart';
import 'package:orcamentos_app/features/dashboard/components/dashboard_header.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/dashboard/services/dashboard_service.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = DashboardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          DashboardHeader(auth: auth, tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<DashboardData>(
                  future: _service.getDashboardData(auth.apiToken!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const OrcamentosLoading(
                        message: 'Carregando métricas...',
                      );
                    } else if (snapshot.hasError) {
                      return InfoStateWidget(
                        buttonForegroundColor: Colors.red,
                        buttonBackgroundColor: Colors.white,
                        icon: Icons.error,
                        iconColor: Colors.red,
                        message: snapshot.error is String
                            ? snapshot.error as String
                            : 'Erro desconhecido',
                        buttonText: 'Tentar novamente',
                        onPressed: () => setState(() {}),
                      );
                    } else if (!snapshot.hasData) {
                      return InfoStateWidget(
                        buttonForegroundColor: Colors.red,
                        buttonBackgroundColor: Colors.white,
                        icon: Icons.info_outline,
                        iconColor: Colors.amber[600]!,
                        message: 'Nenhum dado disponível',
                      );
                    }
                    return DashboardCardGrid(data: snapshot.data!);
                  },
                ),
                _buildComingSoon(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.construction_rounded,
              size: 52,
              color: Colors.amber[600],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Módulo em Desenvolvimento',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Em breve você poderá acompanhar seus investimentos aqui',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[450]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

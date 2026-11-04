import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/info_state_widget.dart';
import 'package:orcamentos_app/features/dashboard/components/dashboard_card_grid.dart';
import 'package:orcamentos_app/features/dashboard/components/dashboard_header.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/dashboard/services/dashboard_service.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/dashboard/components/web/dashboard_web_content.dart';
import 'package:orcamentos_app/features/dashboard/components/web/dashboard_web_header.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = DashboardService();
  late Future<DashboardData> _dados;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dados = _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<DashboardData> _carregar() => _service
      .getDashboardData(Provider.of<AuthState>(context, listen: false).apiToken!);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);
    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = kIsWeb && constraints.maxWidth >= 720;
      return _buildScaffold(auth, isWeb);
    });
  }

  Widget _buildScaffold(AuthState auth, bool isWeb) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          isWeb
              ? DashboardWebHeader(tabController: _tabController)
              : DashboardHeader(auth: auth, tabController: _tabController),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<DashboardData>(
                  future: _dados,
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
                        onPressed: () => setState(() => _dados = _carregar()),
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
                    void verOrcamentos() =>
                        context.read<NavigationController>().select(NavigationController.orcamentosIndex);
                    if (isWeb) {
                      return DashboardWebContent(
                        data: snapshot.data!,
                        onVerOrcamentos: verOrcamentos,
                      );
                    }
                    return DashboardCardGrid(
                      data: snapshot.data!,
                      onVerOrcamentos: verOrcamentos,
                    );
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

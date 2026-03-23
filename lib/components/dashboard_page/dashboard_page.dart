import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/utils/graphql.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/info_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  // ─── Cards ──────────────────────────────────────────────────────────────────
  List<_CardData> _buildCardDataList(Map<String, dynamic> data) => [
    _CardData(title: 'Orçamentos Ativos', value: data['qtdOrcamentosAtivos'].toString(), color: const Color(0xFF3949AB), icon: Icons.list_alt_rounded, isCount: true),
    _CardData(title: 'Orçamentos Encerrados', value: data['qtdOrcamentosEncerrados'].toString(), color: const Color(0xFF00897B), icon: Icons.check_circle_outline_rounded, isCount: true),
    _CardData(title: 'Valor Total', value: formatarValorDynamic(data['valorInicialAtivos']), color: const Color(0xFF1E88E5), icon: Icons.attach_money_rounded),
    _CardData(title: 'Valor Livre', value: formatarValorDynamic(data['valorLivreAtivos']), color: const Color(0xFF43A047), icon: Icons.account_balance_wallet_rounded),
    _CardData(title: 'Valor Atual', value: formatarValorDynamic(data['valorAtualAtivos']), color: const Color(0xFF5E35B1), icon: Icons.pie_chart_rounded),
    _CardData(title: 'Gastos Fixos', value: formatarValorDynamic(data['gastosFixosAtivos']), color: const Color(0xFFE53935), icon: Icons.receipt_long_rounded),
    _CardData(title: 'Gastos Variáveis', value: formatarValorDynamic(data['gastosVariaveisAtivos']), color: const Color(0xFFF4511E), icon: Icons.trending_up_rounded),
    _CardData(title: 'Valor Poupado', value: formatarValorDynamic(data['gastosFixosValorPoupado']), color: const Color(0xFF039BE5), icon: Icons.savings_rounded),
  ];

  Widget _buildDashboardCards(Map<String, dynamic> data) {
    final cards = _buildCardDataList(data);
    return LayoutBuilder(builder: (context, constraints) {
      final int cols = constraints.maxWidth > 1200 ? 4 : constraints.maxWidth > 800 ? 3 : 2;
      final double ratio = constraints.maxWidth > 800 ? 1.55 : 0.95;
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
                child: Text('${cards.length} métricas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500], letterSpacing: 0.3)),
              ),
              GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: ratio),
                itemCount: cards.length,
                itemBuilder: (_, i) => _DashboardCard(data: cards[i], index: i),
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // Header recebe o tabController diretamente — sem estado intermediário
          _DashboardHeader(
            auth: auth,
            tabController: _tabController,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchDashboardData(auth),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return OrcamentosLoading(message: 'Carregando métricas...');
                    } else if (snapshot.hasError) {
                      return InfoStateWidget(
                        buttonForegroundColor: Colors.red, buttonBackgroundColor: Colors.white,
                        icon: Icons.error, iconColor: Colors.red,
                        message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido',
                        buttonText: 'Tentar novamente',
                        onPressed: () => setState(() {}),
                      );
                    } else if (!snapshot.hasData) {
                      return InfoStateWidget(
                        buttonForegroundColor: Colors.red, buttonBackgroundColor: Colors.white,
                        icon: Icons.info_outline, iconColor: Colors.amber[600]!,
                        message: 'Nenhum dado disponível',
                      );
                    }
                    return _buildDashboardCards(snapshot.data!);
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
            decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
            child: Icon(Icons.construction_rounded, size: 52, color: Colors.amber[600]),
          ),
          const SizedBox(height: 20),
          Text('Módulo em Desenvolvimento',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Em breve você poderá acompanhar seus investimentos aqui',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey[450])),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── API ────────────────────────────────────────────────────────────────────
  Future<List<dynamic>> _fetchOrcamentos(String token) async {
    final client = await MyHttpClient.create();
    final r = await client.get('orcamentos',
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'});
    return r.statusCode >= 200 && r.statusCode <= 299 ? json.decode(r.body) : [];
  }

  Future<int> _fetchOrcamentosAtivos(String t) async =>
      (await _fetchOrcamentos(t)).where((o) => o['data_encerramento'] == null).length;

  Future<int> _fetchOrcamentosEncerrados(String t) async =>
      (await _fetchOrcamentos(t)).where((o) => o['data_encerramento'] != null).length;

  Future<Map<String, dynamic>> _fetchDashboardData(AuthProvider auth) async {
    final graphql = await MyGraphQLClient.create(token: auth.apiToken);
    final result = await graphql.query("""
      query {
        consolidadoOrcamentos(filter: { encerrado: false }) {
          valorTotal, valorLivre, valorAtual,
          gastosFixosComprometidos, gastosVariadosRealizados, valorPoupado
        }
      }
    """);
    final c = result['consolidadoOrcamentos'] as Map<String, dynamic>;
    return {
      'qtdOrcamentosAtivos': await _fetchOrcamentosAtivos(auth.apiToken),
      'qtdOrcamentosEncerrados': await _fetchOrcamentosEncerrados(auth.apiToken),
      'valorInicialAtivos': c['valorTotal'],
      'valorLivreAtivos': c['valorLivre'],
      'valorAtualAtivos': c['valorAtual'],
      'gastosFixosAtivos': c['gastosFixosComprometidos'],
      'gastosVariaveisAtivos': c['gastosVariadosRealizados'],
      'gastosFixosValorPoupado': c['valorPoupado'],
    };
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Header — recebe tabController diretamente
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardHeader extends StatelessWidget {
  final AuthProvider auth;
  final TabController tabController;

  const _DashboardHeader({required this.auth, required this.tabController});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                    Text('Visão geral dos seus orçamentos',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              _buildAvatar(),
            ],
          ),
          const SizedBox(height: 20),
          // Pill sincronizado diretamente com tabController.animation
          _PillSegmentedControl(
            labels: const ['Orçamentos', 'Investimentos'],
            icons: const [Icons.account_balance_wallet_rounded, Icons.trending_up_rounded],
            tabController: tabController,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (auth.user?.photoURL != null) {
      return ClipOval(
        child: Image.network(auth.user!.photoURL!, width: 38, height: 38, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback()),
      );
    }
    return _fallback();
  }

  Widget _fallback() => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Pill segmented control — usa tabController.animation diretamente
// O pill segue a animação em tempo real (swipe, clique, animateTo)
// ═══════════════════════════════════════════════════════════════════════════════
class _PillSegmentedControl extends StatefulWidget {
  final List<String> labels;
  final List<IconData> icons;
  final TabController tabController;

  const _PillSegmentedControl({
    required this.labels,
    required this.icons,
    required this.tabController,
  });

  @override
  State<_PillSegmentedControl> createState() => _PillSegmentedControlState();
}

class _PillSegmentedControlState extends State<_PillSegmentedControl> {
  // Posição atual do pill em "índices" (ex: 0.5 = meio entre aba 0 e 1)
  double _pillPosition = 0;
  // Índice da aba ativa (para colorir o texto)
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pillPosition = widget.tabController.index.toDouble();
    _activeIndex = widget.tabController.index;
    widget.tabController.animation!.addListener(_onAnimation);
  }

  void _onAnimation() {
    if (!mounted) return;
    final value = widget.tabController.animation!.value;
    setState(() {
      _pillPosition = value;
      // Considera ativo o índice mais próximo
      _activeIndex = value.round();
    });
  }

  @override
  void dispose() {
    widget.tabController.animation!.removeListener(_onAnimation);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final itemW = constraints.maxWidth / widget.labels.length;

      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            // ── Pill — posição calculada diretamente de _pillPosition ──────
            Positioned(
              left: _pillPosition * itemW + 3,
              top: 3,
              bottom: 3,
              width: itemW - 6,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),

            // ── Botões ────────────────────────────────────────────────────
            Positioned.fill(
              child: Row(
                children: List.generate(widget.labels.length, (i) {
                  final selected = _activeIndex == i;
                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.tabController.animateTo(i),
                        borderRadius: BorderRadius.circular(11),
                        splashColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.transparent,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.icons[i],
                                size: 15,
                                color: selected
                                    ? const Color(0xFF3949AB)
                                    : Colors.white.withOpacity(0.65),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.labels[i],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  color: selected
                                      ? const Color(0xFF3949AB)
                                      : Colors.white.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card data model
// ═══════════════════════════════════════════════════════════════════════════════
class _CardData {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final bool isCount;
  const _CardData({required this.title, required this.value, required this.color, required this.icon, this.isCount = false});
}

// ═══════════════════════════════════════════════════════════════════════════════
// Dashboard card
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardCard extends StatefulWidget {
  final _CardData data;
  final int index;
  const _DashboardCard({required this.data, required this.index});

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: Duration(milliseconds: 300 + (widget.index * 60).clamp(0, 500)));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final color = widget.data.color;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                color: _hovered ? color.withOpacity(0.18) : Colors.black.withOpacity(0.05),
                blurRadius: _hovered ? 20 : 8, offset: const Offset(0, 4),
              )],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                splashColor: color.withOpacity(0.08),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
                        child: Icon(widget.data.icon, color: color, size: 22),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.data.value,
                              style: TextStyle(fontSize: widget.data.isCount ? 28 : 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A1F36), letterSpacing: -0.5),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Text(widget.data.title,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[500], letterSpacing: 0.2),
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: 1, minHeight: 3,
                          backgroundColor: color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
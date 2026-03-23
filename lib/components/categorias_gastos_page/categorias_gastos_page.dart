import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class CategoriasDeGastoPage extends StatefulWidget {
  const CategoriasDeGastoPage({super.key});

  @override
  _CategoriasDeGastoPageState createState() => _CategoriasDeGastoPageState();
}

class _CategoriasDeGastoPageState extends State<CategoriasDeGastoPage>
    with SingleTickerProviderStateMixin {
  List<CategoriaGastoResponseDto> _categorias = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nomeCategoriaController = TextEditingController();
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  late ApiService apiService;

  final List<Color> _categoryColors = [
    const Color(0xFF3949AB),
    const Color(0xFF1E88E5),
    const Color(0xFF00897B),
    const Color(0xFF43A047),
    const Color(0xFFE53935),
    const Color(0xFF8E24AA),
    const Color(0xFFF4511E),
    const Color(0xFF039BE5),
    const Color(0xFF6D4C41),
    const Color(0xFF00ACC1),
  ];

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apiService = Provider.of<ApiService>(context, listen: false);
      _fetchCategorias();
    });
  }

  @override
  void dispose() {
    _nomeCategoriaController.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await apiService.getCategorias();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      OrcamentosSnackBar.error(context: context, message: 'Erro ao carregar categorias');
    }
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCtrl.repeat();
    await _fetchCategorias();
    _refreshCtrl.stop();
    _refreshCtrl.reset();
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _deleteCategoria(int categoriaId) async {
    try {
      await apiService.deleteCategoria(categoriaId);
      OrcamentosSnackBar.success(context: context, message: 'Categoria apagada com sucesso!');
      setState(() => _categorias.removeWhere((c) => c.id == categoriaId));
    } catch (e) {
      OrcamentosSnackBar.error(context: context, message: 'Erro ao apagar categoria');
    }
  }

  Future<void> _createCategoria(String nomeCategoria) async {
    try {
      await apiService.createCategoria(CategoriaGastoCreateDto(nome: nomeCategoria));
      OrcamentosSnackBar.success(context: context, message: 'Categoria criada com sucesso!');
      _fetchCategorias();
      Navigator.of(context).pop();
      _nomeCategoriaController.clear();
    } catch (e) {
      OrcamentosSnackBar.error(context: context, message: 'Erro ao criar categoria');
    }
  }

  void _showCreateCategoriaDialog() {
    _nomeCategoriaController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.indigo.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.add_circle_outline, color: Colors.indigo[700], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Nova Categoria',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.indigo[900])),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nomeCategoriaController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Ex: Alimentação, Transporte…',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: Icon(Icons.label_outline, color: Colors.indigo[400], size: 20),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'O nome não pode ser vazio!';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _createCategoria(_nomeCategoriaController.text);
                        }
                      },
                      child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header moderno ──────────────────────────────────────────────
          _CategoriasHeader(
            categoriasCount: _categorias.length,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onNovaCategoria: _showCreateCategoriaDialog,
            onBack: () => Navigator.of(context).pop(),
          ),

          // ── Corpo ───────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.indigo[700], strokeWidth: 2.5))
                : _categorias.isEmpty
                ? _buildEmptyState()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
            child: Icon(Icons.category_outlined, size: 52, color: Colors.indigo[300]),
          ),
          const SizedBox(height: 20),
          Text('Nenhuma categoria cadastrada',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 8),
          Text('Toque em "Nova Categoria" para começar',
              style: TextStyle(fontSize: 13, color: Colors.grey[450])),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  IconData _getIconForCategoria(String nome) {
    final n = nome.toLowerCase().trim();
    if (_containsAny(n, ['aliment', 'comida', 'restaur', 'lanche', 'refeição', 'mercado', 'supermercado'])) return Icons.restaurant_outlined;
    if (_containsAny(n, ['transport', 'carro', 'combustív', 'gasolina', 'uber', 'ônibus', 'metrô'])) return Icons.directions_car_outlined;
    if (_containsAny(n, ['saúde', 'saude', 'médico', 'medico', 'farmácia', 'farmacia', 'hospital'])) return Icons.health_and_safety_outlined;
    if (_containsAny(n, ['educação', 'educacao', 'escola', 'faculdade', 'curso', 'livro'])) return Icons.school_outlined;
    if (_containsAny(n, ['casa', 'aluguel', 'condomínio', 'moradia', 'água', 'luz', 'energia'])) return Icons.home_outlined;
    if (_containsAny(n, ['tecnologia', 'tech', 'celular', 'computador', 'eletrônico', 'software'])) return Icons.devices_outlined;
    if (_containsAny(n, ['lazer', 'entretenimento', 'cinema', 'streaming', 'hobby', 'academia'])) return Icons.sports_esports_outlined;
    if (_containsAny(n, ['roupa', 'vestuário', 'moda', 'calçado', 'acessório'])) return Icons.shopping_bag_outlined;
    if (_containsAny(n, ['investimento', 'poupança', 'reserva', 'financeiro', 'banco', 'cartão'])) return Icons.savings_outlined;
    if (_containsAny(n, ['viagem', 'voo', 'hotel', 'hospedagem', 'turismo'])) return Icons.flight_outlined;
    if (_containsAny(n, ['pet', 'animal', 'cachorro', 'gato', 'veterinário'])) return Icons.pets_outlined;
    if (_containsAny(n, ['presente', 'gift', 'doação', 'gorjeta'])) return Icons.card_giftcard_outlined;
    return Icons.category_outlined;
  }

  bool _containsAny(String text, List<String> keywords) => keywords.any((k) => text.contains(k));

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${_categorias.length} ${_categorias.length == 1 ? 'categoria' : 'categorias'}',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500], letterSpacing: 0.3),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final categoria = _categorias[index];
                final color = _categoryColors[index % _categoryColors.length];
                return _CategoriaCard(
                  categoria: categoria,
                  color: color,
                  icon: _getIconForCategoria(categoria.nome),
                  index: index,
                  onDelete: () => ConfirmationDialog.confirmAction(
                    context: context,
                    title: 'Excluir Categoria',
                    message: 'Deseja realmente excluir esta categoria?',
                    actionText: 'Excluir',
                    action: () => _deleteCategoria(categoria.id),
                  ),
                );
              },
              childCount: _categorias.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Header moderno — mesma linguagem visual da OrcamentosPage
// ═══════════════════════════════════════════════════════════════════════════════
class _CategoriasHeader extends StatelessWidget {
  final int categoriasCount;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onNovaCategoria;
  final VoidCallback onBack;

  const _CategoriasHeader({
    required this.categoriasCount,
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onNovaCategoria,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: voltar + título ────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canPop)
                _HeaderButton(
                  onTap: onBack,
                  tooltip: 'Voltar',
                  isSquare: true,
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                ),
              if (canPop) const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.category_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Categorias',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Organize seus tipos de gasto',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Linha 2: badge + botões ─────────────────────────────────────
          Row(
            children: [
              // Badge de contagem animado
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(categoriasCount),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PulseDot(),
                      const SizedBox(width: 7),
                      Text(
                        categoriasCount == 0
                            ? 'Nenhuma'
                            : '$categoriasCount ${categoriasCount == 1 ? 'categoria' : 'categorias'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Botão Nova Categoria
              _HeaderButton(
                onTap: onNovaCategoria,
                tooltip: 'Criar nova categoria',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Nova',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botão Refresh
              _HeaderButton(
                onTap: onRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(isRefreshing ? 1 : 0.9),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Botão glassmorphism ──────────────────────────────────────────────────────
class _HeaderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool isSquare;

  const _HeaderButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.isSquare = false,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSquare ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Bolinha verde pulsando ───────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFF69F0AE), const Color(0xFF00E676), _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69F0AE).withOpacity(0.5 * _anim.value),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card de categoria
// ═══════════════════════════════════════════════════════════════════════════════
class _CategoriaCard extends StatefulWidget {
  final CategoriaGastoResponseDto categoria;
  final Color color;
  final IconData icon;
  final int index;
  final VoidCallback onDelete;

  const _CategoriaCard({
    required this.categoria,
    required this.color,
    required this.icon,
    required this.index,
    required this.onDelete,
  });

  @override
  State<_CategoriaCard> createState() => _CategoriaCardState();
}

class _CategoriaCardState extends State<_CategoriaCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 60).clamp(0, 500)),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {},
              splashColor: widget.color.withOpacity(0.08),
              highlightColor: widget.color.withOpacity(0.04),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.categoria.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1F36),
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID #${widget.categoria.id}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red[300], size: 22),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(36, 36),
                      ),
                      onPressed: widget.onDelete,
                      tooltip: 'Excluir categoria',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
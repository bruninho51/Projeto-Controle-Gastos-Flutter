import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/components/common/pulse_dot.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/features/categories/services/categories_service.dart';
import 'package:orcamentos_app/features/categories/utils/category_icon_mapper.dart';
import 'package:orcamentos_app/features/categories/components/category_card.dart';
import 'package:orcamentos_app/features/categories/components/categories_empty_state.dart';
import 'package:orcamentos_app/features/categories/components/category_create_dialog.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage>
    with SingleTickerProviderStateMixin {
  List<CategoriaGastoResponseDto> _categorias = [];
  bool _isLoading = false;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;
  late CategoriesService _categoriesService;

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

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
      _categoriesService = CategoriesService(
        Provider.of<ApiService>(context, listen: false),
      );
      _fetchCategorias();
    });
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCategorias() async {
    setState(() => _isLoading = true);
    try {
      final categorias = await _categoriesService.getCategorias();
      setState(() {
        _categorias = categorias;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao carregar categorias');
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
      await _categoriesService.deleteCategoria(categoriaId);
      if (!mounted) return;
      OrcamentosSnackBar.success(
          context: context, message: 'Categoria apagada com sucesso!');
      setState(() => _categorias.removeWhere((c) => c.id == categoriaId));
    } catch (e) {
      if (!mounted) return;
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao apagar categoria');
    }
  }

  Future<void> _createCategoria(String nomeCategoria) async {
    try {
      await _categoriesService
          .createCategoria(CategoriaGastoCreateDto(nome: nomeCategoria));
      if (!mounted) return;
      OrcamentosSnackBar.success(
          context: context, message: 'Categoria criada com sucesso!');
      _fetchCategorias();
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao criar categoria');
    }
  }

  Widget _buildCategoryBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_categorias.length),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulseDot.positive(),
            const SizedBox(width: 7),
            Text(
              _categorias.isEmpty
                  ? 'Nenhuma'
                  : '${_categorias.length} ${_categorias.length == 1 ? 'categoria' : 'categorias'}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
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
          SharedAppBar(
            title: 'Categorias',
            subtitle: 'Organize seus tipos de gasto',
            mainIcon: Icons.category_rounded,
            gradientColors: _gradientColors,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            showAvatar: false,
            bottomContent: _buildCategoryBadge(),
            actionButtons: [
              SharedAppBar.headerButton(
                onTap: () => showCategoryCreateDialog(
                  context: context,
                  onConfirm: _createCategoria,
                ),
                tooltip: 'Criar nova categoria',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Nova',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SharedAppBar.headerButton(
                onTap: _handleRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: _refreshCtrl,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white
                        .withValues(alpha: _isRefreshing ? 1.0 : 0.9),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: OrcamentosLoading(
                        message: 'Carregando categorias...'))
                : _categorias.isEmpty
                    ? const CategoriesEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              '${_categorias.length} ${_categorias.length == 1 ? 'categoria' : 'categorias'}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                  letterSpacing: 0.3),
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
                return CategoryCard(
                  categoria: categoria,
                  color: color,
                  icon: CategoryIconMapper.getIcon(categoria.nome),
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

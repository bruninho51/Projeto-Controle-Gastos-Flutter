import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:orcamentos_app/features/categories/components/web/categories_web_content.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_page_toolbar.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/confirmation_dialog.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/pulse_dot.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/shared/patch_field.dart';
import 'package:orcamentos_app/features/categories/services/expense_categories_service.dart';
import 'package:orcamentos_app/features/categories/utils/category_icon_mapper.dart';
import 'package:orcamentos_app/features/categories/components/category_card.dart';
import 'package:orcamentos_app/features/categories/components/categories_empty_state.dart';
import 'package:orcamentos_app/features/categories/components/category_form_dialog.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';

class ExpenseCategoriesPage extends StatefulWidget {
  const ExpenseCategoriesPage({super.key});

  @override
  State<ExpenseCategoriesPage> createState() => _ExpenseCategoriesPageState();
}

class _ExpenseCategoriesPageState extends State<ExpenseCategoriesPage>
    with SingleTickerProviderStateMixin {
  List<CategoriaGastoResponseDto> _categorias = [];
  bool _isLoading = false;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;
  late ExpenseCategoriesService _categoriesService;
  TipoCategoriaGasto? _filtroTipo;
  String _busca = '';

  /// Quantidade de categorias exibidas na versão web (paginação local).
  static const int _tamanhoPagina = 11;
  int _limite = _tamanhoPagina;

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
      _categoriesService = ExpenseCategoriesService(
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

  List<CategoriaGastoResponseDto> get _categoriasFiltradas {
    final termo = _busca.trim().toLowerCase();
    return _categorias
        .where((c) =>
            (_filtroTipo == null || c.tipo == _filtroTipo) &&
            (termo.isEmpty || c.nome.toLowerCase().contains(termo)))
        .toList();
  }

  void _abrirNovaCategoria() => showCategoryFormDialog(
        context: context,
        onConfirm: _createCategoria,
      );

  void _editarCategoria(CategoriaGastoResponseDto categoria) =>
      showCategoryFormDialog(
        context: context,
        categoria: categoria,
        onConfirm: (nome, tipo) => _updateCategoria(categoria, nome, tipo),
      );

  void _excluirCategoria(CategoriaGastoResponseDto categoria) =>
      ConfirmationDialog.confirmAction(
        context: context,
        title: 'Excluir Categoria',
        message: 'Deseja realmente excluir esta categoria?',
        actionText: 'Excluir',
        action: () => _deleteCategoria(categoria.id),
      );

  Future<void> _createCategoria(String nome, TipoCategoriaGasto tipo) async {
    try {
      await _categoriesService
          .createCategoria(CategoriaGastoCreateDto(nome: nome, tipo: tipo));
      if (!mounted) return;
      Navigator.of(context).pop(); // pop PRIMEIRO
      OrcamentosSnackBar.success(
          context: context, message: 'Categoria criada com sucesso!');
      await _fetchCategorias(); // depois busca (já tem o guard mounted interno)
    } catch (e) {
      if (!mounted) return;
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao criar categoria');
    }
  }

  Future<void> _updateCategoria(
    CategoriaGastoResponseDto categoria,
    String nome,
    TipoCategoriaGasto tipo,
  ) async {
    final dto = CategoriaGastoUpdateDto(
      nome: nome != categoria.nome
          ? PatchField.value(nome)
          : const PatchField.absent(),
      tipo: tipo != categoria.tipo
          ? PatchField.value(tipo)
          : const PatchField.absent(),
    );

    if (dto.toJson().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    try {
      await _categoriesService.updateCategoria(categoria.id, dto);
      if (!mounted) return;
      Navigator.of(context).pop();
      OrcamentosSnackBar.success(
          context: context, message: 'Categoria atualizada com sucesso!');
      await _fetchCategorias();
    } on ApiException catch (e) {
      if (!mounted) return;
      OrcamentosSnackBar.error(
        context: context,
        message: e.statusCode == 409 && tipo != categoria.tipo
            ? 'Não é possível alterar o tipo de uma categoria que já possui gastos lançados.'
            : 'Erro ao atualizar categoria',
      );
    } catch (e) {
      if (!mounted) return;
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao atualizar categoria');
    }
  }

  Widget _buildCategoryBadge() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_categorias.length),
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5), // ligeiramente reduzido
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PulseDot.positive(),
            const SizedBox(width: 6),
            Flexible(
              // <-- envolve o Text com Flexible
              child: Text(
                _categorias.isEmpty
                    ? 'Nenhuma'
                    : '${_categorias.length} ${_categorias.length == 1 ? 'categoria' : 'categorias'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis, // segurança extra
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout de desktop apenas na web e com espaço suficiente.
  static const double _larguraMinimaWeb = 720;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = kIsWeb && constraints.maxWidth >= _larguraMinimaWeb;
      return isWeb ? _buildWeb() : _buildMobile();
    });
  }

  // ── Versão web ──────────────────────────────────────────────────────────────
  Widget _buildWeb() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          WebPageToolbar(
            titulo: 'Categorias',
            subtitulo: 'Organize seus tipos de gasto',
            breadcrumb: [
              WebCrumb('Orçamentos',
                  onTap: () => context
                      .read<NavigationController>()
                      .select(NavigationController.orcamentosIndex)),
              const WebCrumb('Categorias'),
            ],
            busca: _busca,
            placeholderBusca: 'Buscar categorias...',
            rotuloNovo: 'Nova categoria',
            mostrarFiltros: false,
            temFiltroAtivo: false,
            podeCriar: true,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onBuscar: (v) => setState(() {
              _busca = v;
              _limite = _tamanhoPagina;
            }),
            onFiltros: () {},
            onRefresh: _handleRefresh,
            onNovoGasto: _abrirNovaCategoria,
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        OrcamentosLoading(message: 'Carregando categorias...'))
                : _categorias.isEmpty
                    ? const CategoriesEmptyState()
                    : CategoriesWebContent(
                        todas: _categorias,
                        filtradas: _categoriasFiltradas,
                        tipo: _filtroTipo,
                        limite: _limite,
                        cores: _categoryColors,
                        onTipo: (t) => setState(() {
                          _filtroTipo = t;
                          _limite = _tamanhoPagina;
                        }),
                        onCarregarMais: () =>
                            setState(() => _limite += _tamanhoPagina),
                        onNova: _abrirNovaCategoria,
                        onEditar: _editarCategoria,
                        onExcluir: _excluirCategoria,
                      ),
          ),
        ],
      ),
    );
  }

  // ── Versão mobile ───────────────────────────────────────────────────────────
  Widget _buildMobile() {
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
                onTap: () => showCategoryFormDialog(
                  context: context,
                  onConfirm: _createCategoria,
                ),
                tooltip: 'Criar nova categoria',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 16),
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
                    child:
                        OrcamentosLoading(message: 'Carregando categorias...'))
                : _categorias.isEmpty
                    ? const CategoriesEmptyState()
                    : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    int contar(TipoCategoriaGasto? tipo) => tipo == null
        ? _categorias.length
        : _categorias.where((c) => c.tipo == tipo).length;

    Widget chip(String label, TipoCategoriaGasto? tipo, Color cor) {
      final selecionado = _filtroTipo == tipo;
      return ChoiceChip(
        label: Text('$label (${contar(tipo)})'),
        selected: selecionado,
        showCheckmark: false,
        selectedColor: cor.withValues(alpha: 0.15),
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selecionado ? cor : Colors.grey.shade300, width: 1),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selecionado ? cor : Colors.grey[600],
        ),
        onSelected: (_) => setState(() => _filtroTipo = tipo),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          chip('Todas', null, Colors.indigo),
          for (final tipo in TipoCategoriaGasto.values)
            chip(tipo.label, tipo, tipo.color),
        ],
      ),
    );
  }

  Widget _buildList() {
    final categorias = _categoriasFiltradas;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildFiltros()),
        if (categorias.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: CategoriesEmptyState(
              icon: _filtroTipo!.icon,
              title: 'Nenhuma categoria deste tipo',
              subtitle: 'Toque em "Nova" para criar uma de ${_filtroTipo!.label}',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final categoria = categorias[index];
                  final color = _categoryColors[index % _categoryColors.length];
                  return CategoryCard(
                    key: ValueKey(categoria.id),
                    categoria: categoria,
                    color: color,
                    icon: CategoryIconMapper.getIcon(categoria.nome),
                    index: index,
                    onEdit: () => showCategoryFormDialog(
                      context: context,
                      categoria: categoria,
                      onConfirm: (nome, tipo) =>
                          _updateCategoria(categoria, nome, tipo),
                    ),
                    onDelete: () => ConfirmationDialog.confirmAction(
                      context: context,
                      title: 'Excluir Categoria',
                      message: 'Deseja realmente excluir esta categoria?',
                      actionText: 'Excluir',
                      action: () => _deleteCategoria(categoria.id),
                    ),
                  );
                },
                childCount: categorias.length,
              ),
            ),
          ),
      ],
    );
  }
}

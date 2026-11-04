import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/categories/components/web/categories_web_card.dart';
import 'package:orcamentos_app/features/categories/utils/category_icon_mapper.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Corpo da versão web de categorias: abas por tipo, grade de cards e paginação.
class CategoriesWebContent extends StatelessWidget {
  /// Todas as categorias carregadas (base das contagens das abas).
  final List<CategoriaGastoResponseDto> todas;

  /// Categorias após busca e filtro de tipo, na ordem de exibição.
  final List<CategoriaGastoResponseDto> filtradas;
  final TipoCategoriaGasto? tipo;
  final int limite;
  final List<Color> cores;
  final ValueChanged<TipoCategoriaGasto?> onTipo;
  final VoidCallback onCarregarMais;
  final VoidCallback onNova;
  final ValueChanged<CategoriaGastoResponseDto> onEditar;
  final ValueChanged<CategoriaGastoResponseDto> onExcluir;

  const CategoriesWebContent({
    super.key,
    required this.todas,
    required this.filtradas,
    required this.tipo,
    required this.limite,
    required this.cores,
    required this.onTipo,
    required this.onCarregarMais,
    required this.onNova,
    required this.onEditar,
    required this.onExcluir,
  });

  static const double _alturaCard = 140;

  @override
  Widget build(BuildContext context) {
    final exibidas = filtradas.take(limite).toList();
    final restantes = filtradas.length - exibidas.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Abas(todas: todas, tipo: tipo, onTipo: onTipo),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            final colunas =
                c.maxWidth >= 1100 ? 3 : (c.maxWidth >= 700 ? 2 : 1);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: _alturaCard,
              ),
              itemCount: exibidas.length + 1,
              itemBuilder: (_, i) {
                if (i == exibidas.length) return _NovaCategoria(onTap: onNova);
                final c = exibidas[i];
                return CategoriesWebCard(
                  key: ValueKey(c.id),
                  categoria: c,
                  color: cores[i % cores.length],
                  icon: CategoryIconMapper.getIcon(c.nome),
                  onEdit: () => onEditar(c),
                  onDelete: () => onExcluir(c),
                );
              },
            );
          }),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  'Mostrando ${exibidas.length} de ${filtradas.length} '
                  '${filtradas.length == 1 ? 'categoria' : 'categorias'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                if (restantes > 0) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onCarregarMais,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kIndigo,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Carregar mais',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Abas extends StatelessWidget {
  final List<CategoriaGastoResponseDto> todas;
  final TipoCategoriaGasto? tipo;
  final ValueChanged<TipoCategoriaGasto?> onTipo;

  const _Abas({required this.todas, required this.tipo, required this.onTipo});

  @override
  Widget build(BuildContext context) {
    int contar(TipoCategoriaGasto? t) =>
        t == null ? todas.length : todas.where((c) => c.tipo == t).length;

    Widget aba(String rotulo, TipoCategoriaGasto? t) {
      final selecionada = tipo == t;
      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onTipo(t),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: selecionada ? kIndigo.withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: selecionada
                    ? kIndigo.withOpacity(0.5)
                    : Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rotulo,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selecionada ? FontWeight.w700 : FontWeight.w500,
                      color: selecionada ? kIndigo : kWebTexto)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selecionada ? Colors.white : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${contar(t)}',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selecionada ? kIndigo : Colors.grey[700])),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        aba('Todas', null),
        for (final t in TipoCategoriaGasto.values) aba(t.label, t),
      ],
    );
  }
}

/// Tile tracejado no fim da grade para criar uma categoria.
class _NovaCategoria extends StatelessWidget {
  final VoidCallback onTap;

  const _NovaCategoria({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: CustomPaint(
        painter: _BordaTracejada(kIndigo.withOpacity(0.35)),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 26, color: kIndigo),
              SizedBox(height: 8),
              Text('Nova categoria',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kIndigo)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BordaTracejada extends CustomPainter {
  final Color cor;

  _BordaTracejada(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final caminho = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(16)));
    for (final metrica in caminho.computeMetrics()) {
      var distancia = 0.0;
      while (distancia < metrica.length) {
        canvas.drawPath(metrica.extractPath(distancia, distancia + 8), paint);
        distancia += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_BordaTracejada old) => old.cor != cor;
}

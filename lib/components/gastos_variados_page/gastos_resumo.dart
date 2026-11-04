import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_variados_page/categoria_visual.dart';
import 'package:orcamentos_app/features/shared/components/web/web_categorias_card.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Estatísticas de uma lista de gastos, usadas nos cards e no painel lateral.
class GastosResumo {
  final double total;
  final int quantidade;
  final double mediaDiaria;
  final GastoVariadoResponseDto? menor;
  final GastoVariadoResponseDto? maior;
  final List<CategoriaTotal> porCategoria;

  const GastosResumo({
    required this.total,
    required this.quantidade,
    required this.mediaDiaria,
    required this.menor,
    required this.maior,
    required this.porCategoria,
  });

  static double valorDe(GastoVariadoResponseDto g) =>
      double.tryParse(g.valor) ?? 0;

  factory GastosResumo.de(List<GastoVariadoResponseDto> gastos) {
    if (gastos.isEmpty) {
      return const GastosResumo(
        total: 0,
        quantidade: 0,
        mediaDiaria: 0,
        menor: null,
        maior: null,
        porCategoria: [],
      );
    }

    final dfDia = DateFormat('yyyy-MM-dd');
    final dias = <String>{};
    final categorias = <String, CategoriaTotal>{};
    var total = 0.0;
    var menor = gastos.first;
    var maior = gastos.first;

    for (final g in gastos) {
      final v = valorDe(g);
      total += v;
      dias.add(dfDia.format(g.dataPgto));
      if (v < valorDe(menor)) menor = g;
      if (v > valorDe(maior)) maior = g;

      final nome = g.categoriaGasto.nome;
      final atual = categorias[nome];
      categorias[nome] =
          CategoriaTotal(nome, (atual?.total ?? 0) + v, corDoGasto(g));
    }

    final porCategoria = categorias.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return GastosResumo(
      total: total,
      quantidade: gastos.length,
      mediaDiaria: total / dias.length,
      menor: menor,
      maior: maior,
      porCategoria: porCategoria,
    );
  }
}

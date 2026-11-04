import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_status.dart';
import 'package:orcamentos_app/components/gastos_variados_page/categoria_visual.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/web/web_categorias_card.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Estatísticas de uma lista de gastos fixos, usadas nos cards e no painel lateral.
class GastosFixosResumo {
  final double previsto;
  final double pago;
  final double aPagar;
  final double vencido;

  /// Soma do previsto dos gastos de categorias do tipo patrimônio.
  final double patrimonioPrevisto;
  final int qtdPatrimonio;
  final int quantidade;
  final int qtdVencidos;
  final List<CategoriaTotal> porCategoria;

  const GastosFixosResumo({
    required this.previsto,
    required this.pago,
    required this.aPagar,
    required this.vencido,
    required this.patrimonioPrevisto,
    required this.qtdPatrimonio,
    required this.quantidade,
    required this.qtdVencidos,
    required this.porCategoria,
  });

  /// Fração já paga do previsto (0 a 1).
  double get progresso => previsto <= 0 ? 0 : (pago / previsto).clamp(0, 1);

  static double previstoDe(GastoFixoResponseDto g) =>
      double.tryParse(g.previsto) ?? 0;

  static double pagoDe(GastoFixoResponseDto g) =>
      double.tryParse(g.valor ?? '') ?? 0;

  factory GastosFixosResumo.de(List<GastoFixoResponseDto> gastos) {
    var previsto = 0.0, pago = 0.0, aPagar = 0.0, vencido = 0.0;
    var patrimonio = 0.0;
    var qtdVencidos = 0, qtdPatrimonio = 0;
    final categorias = <String, CategoriaTotal>{};

    for (final g in gastos) {
      final p = previstoDe(g);
      previsto += p;
      switch (statusDoGastoFixo(g)) {
        case 'PAGO':
          pago += pagoDe(g);
        case 'VENCIDO':
          aPagar += p;
          vencido += p;
          qtdVencidos++;
        default:
          aPagar += p;
      }

      if (g.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio) {
        patrimonio += p;
        qtdPatrimonio++;
      }

      final nome = g.categoriaGasto.nome;
      final cor = g.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio
          ? g.categoriaGasto.tipo.color
          : corDaCategoria(nome);
      final atual = categorias[nome];
      categorias[nome] = CategoriaTotal(nome, (atual?.total ?? 0) + p, cor);
    }

    final porCategoria = categorias.values.toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    return GastosFixosResumo(
      previsto: previsto,
      pago: pago,
      aPagar: aPagar,
      vencido: vencido,
      patrimonioPrevisto: patrimonio,
      qtdPatrimonio: qtdPatrimonio,
      quantidade: gastos.length,
      qtdVencidos: qtdVencidos,
      porCategoria: porCategoria,
    );
  }
}

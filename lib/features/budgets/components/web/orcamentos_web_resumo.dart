import 'package:orcamentos_app/shared/api_models.dart';

/// Quantidade de lançamentos de um orçamento.
class ContagemGastos {
  final int fixos;
  final int variados;

  const ContagemGastos(this.fixos, this.variados);
}

/// Totais da lista de orçamentos, usados nos cards e no painel lateral.
class OrcamentosResumo {
  final double orcado;
  final double utilizado;
  final double saldo;
  final double livre;
  final int quantidade;
  final int fixos;
  final int variados;

  const OrcamentosResumo({
    required this.orcado,
    required this.utilizado,
    required this.saldo,
    required this.livre,
    required this.quantidade,
    required this.fixos,
    required this.variados,
  });

  /// Fração do orçado já utilizada (0 a 1).
  double get percentualUtilizado =>
      orcado <= 0 ? 0 : (utilizado / orcado).clamp(0, 1);

  static double _num(String v) => double.tryParse(v) ?? 0;

  static double orcadoDe(OrcamentoResponseDto o) => _num(o.valorInicial);
  static double saldoDe(OrcamentoResponseDto o) => _num(o.valorAtual);
  static double livreDe(OrcamentoResponseDto o) => _num(o.valorLivre);

  /// Quanto do orçamento já foi gasto (nunca negativo).
  static double utilizadoDe(OrcamentoResponseDto o) =>
      (orcadoDe(o) - saldoDe(o)).clamp(0, double.infinity);

  factory OrcamentosResumo.de(
    List<OrcamentoResponseDto> orcamentos,
    Map<int, ContagemGastos> contagens,
  ) {
    var orcado = 0.0, utilizado = 0.0, saldo = 0.0, livre = 0.0;
    var fixos = 0, variados = 0;

    for (final o in orcamentos) {
      orcado += orcadoDe(o);
      utilizado += utilizadoDe(o);
      saldo += saldoDe(o);
      livre += livreDe(o);
      fixos += contagens[o.id]?.fixos ?? 0;
      variados += contagens[o.id]?.variados ?? 0;
    }

    return OrcamentosResumo(
      orcado: orcado,
      utilizado: utilizado,
      saldo: saldo,
      livre: livre,
      quantidade: orcamentos.length,
      fixos: fixos,
      variados: variados,
    );
  }
}

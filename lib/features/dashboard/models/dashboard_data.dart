import 'package:orcamentos_app/features/dashboard/models/dashboard_orcamento.dart';

class DashboardData {
  final int qtdOrcamentosAtivos;
  final int qtdOrcamentosEncerrados;
  final dynamic valorInicialAtivos;
  final dynamic valorLivreAtivos;
  final dynamic valorAtualAtivos;
  final dynamic gastosFixosAtivos;
  final dynamic gastosVariaveisAtivos;
  final dynamic valorPoupado;

  /// Orçamentos ativos, usados no comparativo da versão web.
  final List<DashboardOrcamento> orcamentosAtivos;

  const DashboardData({
    required this.qtdOrcamentosAtivos,
    required this.qtdOrcamentosEncerrados,
    required this.valorInicialAtivos,
    required this.valorLivreAtivos,
    required this.valorAtualAtivos,
    required this.gastosFixosAtivos,
    required this.gastosVariaveisAtivos,
    required this.valorPoupado,
    this.orcamentosAtivos = const [],
  });

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

  double get valorTotal => _num(valorInicialAtivos);
  double get valorLivre => _num(valorLivreAtivos);
  double get valorAtual => _num(valorAtualAtivos);
  double get fixos => _num(gastosFixosAtivos);
  double get variaveis => _num(gastosVariaveisAtivos);

  /// Já gasto: o que saiu do valor total.
  double get utilizado => (valorTotal - valorAtual).clamp(0, double.infinity);

  /// Reservado para gastos fixos ainda não pagos: valor atual menos o livre.
  double get comprometido => (valorAtual - valorLivre).clamp(0, double.infinity);

  int get qtdOrcamentos => qtdOrcamentosAtivos + qtdOrcamentosEncerrados;
}

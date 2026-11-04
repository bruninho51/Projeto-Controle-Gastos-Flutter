/// Orçamento ativo exibido no comparativo do dashboard.
class DashboardOrcamento {
  final String nome;
  final DateTime? dataCriacao;
  final double orcado;
  final double saldo;

  const DashboardOrcamento({
    required this.nome,
    required this.dataCriacao,
    required this.orcado,
    required this.saldo,
  });

  /// Quanto já foi gasto do orçamento (nunca negativo).
  double get utilizado => (orcado - saldo).clamp(0, double.infinity);

  factory DashboardOrcamento.fromJson(Map<String, dynamic> json) {
    double num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;
    return DashboardOrcamento(
      nome: (json['nome'] ?? '').toString(),
      dataCriacao: DateTime.tryParse((json['data_criacao'] ?? '').toString()),
      orcado: num(json['valor_inicial']),
      saldo: num(json['valor_atual']),
    );
  }
}

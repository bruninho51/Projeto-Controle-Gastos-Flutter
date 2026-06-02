class DashboardData {
  final int qtdOrcamentosAtivos;
  final int qtdOrcamentosEncerrados;
  final dynamic valorInicialAtivos;
  final dynamic valorLivreAtivos;
  final dynamic valorAtualAtivos;
  final dynamic gastosFixosAtivos;
  final dynamic gastosVariaveisAtivos;
  final dynamic valorPoupado;

  const DashboardData({
    required this.qtdOrcamentosAtivos,
    required this.qtdOrcamentosEncerrados,
    required this.valorInicialAtivos,
    required this.valorLivreAtivos,
    required this.valorAtualAtivos,
    required this.gastosFixosAtivos,
    required this.gastosVariaveisAtivos,
    required this.valorPoupado,
  });
}

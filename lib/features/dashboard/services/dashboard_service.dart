import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/dashboard/repositories/dashboard_repository.dart';

class DashboardService {
  final DashboardRepository _repository;

  DashboardService({DashboardRepository? repository})
      : _repository = repository ?? DashboardRepository();

  Future<DashboardData> getDashboardData(String token) async {
    // Inicia ambas as chamadas em paralelo antes de aguardar qualquer uma
    final orcamentosFuture = _repository.fetchOrcamentos(token);
    final consolidadoFuture = _repository.fetchConsolidado(token);

    final orcamentos = await orcamentosFuture;
    final consolidado = await consolidadoFuture;

    return DashboardData(
      qtdOrcamentosAtivos:
          orcamentos.where((o) => o['data_encerramento'] == null).length,
      qtdOrcamentosEncerrados:
          orcamentos.where((o) => o['data_encerramento'] != null).length,
      valorInicialAtivos: consolidado['valorTotal'],
      valorLivreAtivos: consolidado['valorLivre'],
      valorAtualAtivos: consolidado['valorAtual'],
      gastosFixosAtivos: consolidado['gastosFixosComprometidos'],
      gastosVariaveisAtivos: consolidado['gastosVariadosRealizados'],
      valorPoupado: consolidado['valorPoupado'],
    );
  }
}

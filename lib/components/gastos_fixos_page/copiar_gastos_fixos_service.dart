import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

/// Ajusta o vencimento de um gasto copiado, mantendo o dia: datas de meses
/// passados vão para o mês atual, datas do mês atual vão para o mês seguinte
/// e datas futuras ficam como estão (limitado ao último dia do mês).
DateTime? ajustarDataVencimento(DateTime? dataVencimento) {
  if (dataVencimento == null) return null;

  final agora = DateTime.now();

  int ano = dataVencimento.year;
  int mes = dataVencimento.month;

  if (ano < agora.year || (ano == agora.year && mes < agora.month)) {
    mes = agora.month;
    ano = agora.year;
  } else if (ano == agora.year && mes == agora.month) {
    mes++;

    if (mes > 12) {
      mes = 1;
      ano++;
    }
  }

  // último dia do mês alvo
  final ultimoDiaDoMes = DateTime(ano, mes + 1, 0).day;

  final dia = dataVencimento.day > ultimoDiaDoMes
      ? ultimoDiaDoMes
      : dataVencimento.day;

  return DateTime(ano, mes, dia);
}

/// Cria em [destinoId] uma cópia de cada gasto de [gastos].
///
/// Retorna quantos gastos falharam ao serem copiados.
Future<int> copiarGastosFixos(
  ApiService api,
  int destinoId,
  List<GastoFixoResponseDto> gastos,
) async {
  var erros = 0;
  for (final g in gastos) {
    try {
      await api.createGastoFixo(
        destinoId,
        GastoFixoCreateDto(
          descricao: g.descricao,
          previsto: g.previsto,
          categoriaId: g.categoriaId,
          observacoes: g.observacoes ?? '',
          dataVenc: ajustarDataVencimento(g.dataVenc),
        ),
      );
    } catch (_) {
      erros++;
    }
  }
  return erros;
}

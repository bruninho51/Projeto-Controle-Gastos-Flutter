import 'package:flutter/foundation.dart';
import 'package:orcamentos_app/features/notifications/regex_patterns/dao/padrao_regex_notificacao_dao.dart';
import 'package:orcamentos_app/features/notifications/regex_patterns/models/padrao_regex_notificacao.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

/// Centraliza toda a lógica de cache local + renovação via API dos padrões
/// de regex usados para extrair dados de notificações bancárias.
class PadraoRegexNotificacaoRepository {
  final ApiService api;
  final PadraoRegexNotificacaoDao dao;

  PadraoRegexNotificacaoRepository(this.api, {PadraoRegexNotificacaoDao? dao})
      : dao = dao ?? PadraoRegexNotificacaoDao();

  /// Retorna uma regex válida para a instituição/título informados, ou `null`
  /// se não houver cache local e a API estiver indisponível.
  Future<String?> getRegex(
    String instituicaoFinanceira,
    String tituloNotificacao,
    String corpoNotificacao,
  ) async {
    final local = await dao.findByInstituicaoETitulo(instituicaoFinanceira, tituloNotificacao);

    if (local == null) {
      return _buscarNovoPadrao(instituicaoFinanceira, tituloNotificacao, corpoNotificacao);
    }

    if (!local.expirado) {
      return local.regex;
    }

    return _renovarPadrao(local, corpoNotificacao);
  }

  /// Retorna todos os padrões salvos localmente.
  Future<List<PadraoRegexNotificacao>> getAllLocal() => dao.findAll();

  /// Remove um único padrão do cache local.
  Future<void> deletePadrao(int id) => dao.deleteById(id);

  /// Remove todos os padrões do cache local.
  Future<void> limparTudo() => dao.deleteAll();

  /// Baixa todos os padrões da API e substitui o cache local por eles.
  Future<List<PadraoRegexNotificacao>> sincronizar() async {
    final remotos = await api.getPadroesRegex();

    final locais = remotos
        .map((r) => PadraoRegexNotificacao(
              instituicaoFinanceira: r.instituicaoFinanceira,
              tituloNotificacao: r.tituloNotificacao,
              regex: r.regex,
              dataCriacao: r.dataCriacao,
              dataAtualizacao: r.dataAtualizacao,
              dataExpiracao: r.dataExpiracao,
            ))
        .toList();

    await dao.deleteAll();
    await dao.insertAll(locais);

    return dao.findAll();
  }

  Future<String?> _buscarNovoPadrao(
    String instituicaoFinanceira,
    String tituloNotificacao,
    String corpoNotificacao,
  ) async {
    try {
      final resp = await api.obterOuGerarPadraoRegex(
        PadraoRegexNotificacaoRequestDto(
          instituicaoFinanceira: instituicaoFinanceira,
          tituloNotificacao: tituloNotificacao,
          corpoNotificacao: corpoNotificacao,
        ),
      );

      await dao.insert(PadraoRegexNotificacao(
        instituicaoFinanceira: resp.instituicaoFinanceira,
        tituloNotificacao: resp.tituloNotificacao,
        regex: resp.regex,
        dataCriacao: resp.dataCriacao,
        dataAtualizacao: resp.dataAtualizacao,
        dataExpiracao: resp.dataExpiracao,
      ));

      return resp.regex;
    } catch (e) {
      debugPrint('PadraoRegexNotificacaoRepository: falha ao obter padrão novo — $e');
      return null;
    }
  }

  Future<String?> _renovarPadrao(
    PadraoRegexNotificacao local,
    String corpoNotificacao,
  ) async {
    try {
      final resp = await api.obterOuGerarPadraoRegex(
        PadraoRegexNotificacaoRequestDto(
          instituicaoFinanceira: local.instituicaoFinanceira,
          tituloNotificacao: local.tituloNotificacao,
          corpoNotificacao: corpoNotificacao,
        ),
      );

      await dao.updateRegex(
        id: local.id!,
        regex: resp.regex,
        dataAtualizacao: resp.dataAtualizacao,
        dataExpiracao: resp.dataExpiracao,
      );

      return resp.regex;
    } catch (e) {
      debugPrint(
        'PadraoRegexNotificacaoRepository: falha ao renovar padrão expirado, usando fallback — $e',
      );
      return local.regex;
    }
  }
}

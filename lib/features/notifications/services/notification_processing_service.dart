import 'package:flutter/foundation.dart';
import 'package:orcamentos_app/features/notifications/notifications_channel.dart';
import 'package:orcamentos_app/features/notifications/regex_patterns/repositories/padrao_regex_notificacao_repository.dart';

/// Processa notificações bancárias capturadas nativamente: obtém uma regex
/// válida (via cache local/API, através do [PadraoRegexNotificacaoRepository])
/// e a utiliza para extrair valor e descrição, persistindo o resultado de
/// volta no armazenamento nativo.
///
/// Não conhece regras de cache nem chama a API diretamente — toda essa
/// responsabilidade fica no repository.
class NotificationProcessingService {
  final PadraoRegexNotificacaoRepository regexRepository;

  NotificationProcessingService(this.regexRepository);

  /// Reprocessa notificações que ficaram sem extração (ex.: capturadas pelo
  /// nativo enquanto o app estava totalmente fechado, sem engine Flutter
  /// ativa para receber o evento em tempo real via [NotificationsChannel]).
  /// Deve ser chamado ao iniciar o app.
  Future<void> processarNotificacoesPendentes() async {
    try {
      final notificacoes = await NotificationsChannel.getAll();
      final pendentes = notificacoes.where((n) => n.naoProcessada);

      for (final n in pendentes) {
        await processarEvento({
          'id': n.id,
          'package': n.banco,
          'title': n.tituloNotificacao ?? '',
          'content': n.descricaoOriginal,
        });
      }
    } catch (e) {
      debugPrint('NotificationProcessingService: erro ao reprocessar pendentes — $e');
    }
  }

  Future<void> processarEvento(Map<dynamic, dynamic> evento) async {
    try {
      final id = (evento['id'] as num?)?.toInt();
      final instituicaoFinanceira = evento['package'] as String?;
      final tituloNotificacao = evento['title'] as String? ?? '';
      final corpoNotificacao = evento['content'] as String? ?? '';

      if (id == null || instituicaoFinanceira == null) return;

      final regex = await regexRepository.getRegex(
        instituicaoFinanceira,
        tituloNotificacao,
        corpoNotificacao,
      );

      if (regex == null) {
        debugPrint(
          'NotificationProcessingService: nenhuma regex disponível para '
          '$instituicaoFinanceira/$tituloNotificacao — notificação ignorada',
        );
        return;
      }

      final extraido = _extrair(regex, corpoNotificacao);
      if (extraido == null) {
        debugPrint(
          'NotificationProcessingService: regex "$regex" não deu match no '
          'corpo "$corpoNotificacao"',
        );
        return;
      }

      if (extraido.usouFallback) {
        debugPrint(
          'NotificationProcessingService: regex "$regex" não retornou grupo '
          '"estabelecimento" válido — usando corpo bruto como descrição',
        );
      }

      await NotificationsChannel.update(
        id: id,
        valor: extraido.valor,
        descricaoOriginal: extraido.descricao,
        descricaoNormalizada: extraido.descricao,
      );
    } catch (e) {
      debugPrint('NotificationProcessingService: erro ao processar notificação — $e');
    }
  }

  _DadosExtraidos? _extrair(String regexPattern, String corpoNotificacao) {
    final match = RegExp(regexPattern).firstMatch(corpoNotificacao);
    if (match == null) return null;

    String? valorBruto;
    String? descricao;
    try {
      valorBruto = match.namedGroup('valor');
    } catch (_) {}
    try {
      descricao = match.namedGroup('estabelecimento');
    } catch (_) {}

    final valor = _parseValor(valorBruto);
    if (valor == null) return null;

    final semEstabelecimento = descricao == null || descricao.trim().isEmpty;

    return _DadosExtraidos(
      valor: valor,
      descricao: semEstabelecimento ? corpoNotificacao : descricao.trim(),
      usouFallback: semEstabelecimento,
    );
  }

  double? _parseValor(String? bruto) {
    if (bruto == null || bruto.isEmpty) return null;
    final normalizado = bruto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado);
  }
}

class _DadosExtraidos {
  final double valor;
  final String descricao;
  final bool usouFallback;

  _DadosExtraidos({
    required this.valor,
    required this.descricao,
    required this.usouFallback,
  });
}

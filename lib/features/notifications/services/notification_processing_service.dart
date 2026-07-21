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

  /// Inicializa o processamento de notificações do aplicativo.
  ///
  /// Este método:
  /// - registra um listener para receber eventos enviados pela camada nativa
  ///   (Android) através do [NotificationsChannel];
  /// - processa notificações pendentes que possam ter sido recebidas enquanto
  ///   o aplicativo estava fechado ou antes da inicialização do serviço.
  ///
  /// Deve ser chamado apenas uma vez durante o ciclo de vida da aplicação,
  /// após a autenticação do usuário.
  Future<void> initialize() async {
    NotificationsChannel.listenToBridge(processarEvento);
    await processarNotificacoesPendentes();
  }

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

      String? regex;
      try {
        regex = await regexRepository.getRegex(
          instituicaoFinanceira,
          tituloNotificacao,
          corpoNotificacao,
        );
      } on RegexIndisponivelException catch (e) {
        debugPrint('NotificationProcessingService: $e');
        await NotificationsChannel.marcarErroProcessamento(id: id, erro: true);
        return;
      }

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

      await NotificationsChannel.update(
        id: id,
        valor: extraido.valor,
        descricaoOriginal: extraido.descricao,
        descricaoNormalizada: extraido.descricao,
      );

      if (extraido.usouFallback) {
        debugPrint(
          'NotificationProcessingService: regex "$regex" não retornou grupo '
          '"estabelecimento" válido — usando corpo bruto como descrição',
        );
        // update() acima zera erro_processamento; marcamos de novo aqui para
        // que o botão de reprocessar apareça — a descrição ficou com o corpo
        // bruto em vez do estabelecimento, então vale tentar de novo depois
        // (ex.: quando uma regex melhor estiver disponível na API).
        await NotificationsChannel.marcarErroProcessamento(id: id, erro: true);
      }
    } catch (e) {
      debugPrint('NotificationProcessingService: erro ao processar notificação — $e');
    }
  }

  ({double valor, String descricao, bool usouFallback})? _extrair(
    String regexPattern,
    String corpoNotificacao,
  ) {
    final match = RegExp(regexPattern).firstMatch(corpoNotificacao);
    if (match == null) return null;

    final valor = _parseValor(_namedGroupOrNull(match, 'valor'));
    if (valor == null) return null;

    final descricao = _namedGroupOrNull(match, 'estabelecimento')?.trim();
    final semEstabelecimento = descricao == null || descricao.isEmpty;

    return (
      valor: valor,
      descricao: semEstabelecimento ? corpoNotificacao : descricao,
      usouFallback: semEstabelecimento,
    );
  }

  /// Regex vindas da API podem não definir todos os grupos nomeados
  /// esperados — `namedGroup` lança nesse caso (grupo inexistente no
  /// padrão), diferente de retornar null (grupo existe mas não casou).
  String? _namedGroupOrNull(RegExpMatch match, String nome) {
    try {
      return match.namedGroup(nome);
    } catch (_) {
      return null;
    }
  }

  double? _parseValor(String? bruto) {
    if (bruto == null || bruto.isEmpty) return null;
    final normalizado = bruto.replaceAll('.', '').replaceAll(',', '.');
    return double.tryParse(normalizado);
  }
}

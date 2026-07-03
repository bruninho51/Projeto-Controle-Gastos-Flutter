class NotificacaoBancariaModel {
  final int id;
  final String banco;
  final String? nomeApp;
  final String descricaoOriginal;
  final String? descricaoNormalizada;
  final double valor;
  final String? tituloNotificacao;
  final int dataNotificacao;
  final int? gastoId;
  final int dataCriacao;

  NotificacaoBancariaModel({
    required this.id,
    required this.banco,
    this.nomeApp,
    required this.descricaoOriginal,
    this.descricaoNormalizada,
    required this.valor,
    this.tituloNotificacao,
    required this.dataNotificacao,
    this.gastoId,
    required this.dataCriacao,
  });

  bool get naoProcessada => valor == 0.0;

  factory NotificacaoBancariaModel.fromMap(Map<Object?, Object?> map) {
    return NotificacaoBancariaModel(
      id: (map['id'] as num).toInt(),
      banco: map['banco'] as String? ?? '',
      nomeApp: map['nome_app'] as String?,
      descricaoOriginal: map['descricao_original'] as String? ?? '',
      descricaoNormalizada: map['descricao_normalizada'] as String?,
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      tituloNotificacao: map['titulo_notificacao'] as String?,
      dataNotificacao: (map['data_notificacao'] as num?)?.toInt() ?? 0,
      gastoId: (map['gasto_id'] as num?)?.toInt(),
      dataCriacao: (map['data_criacao'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get dataNotificacaoDateTime =>
      DateTime.fromMillisecondsSinceEpoch(dataNotificacao);

  bool get vinculado => gastoId != null;

  String get nomeBanco {
    final app = nomeApp;
    if (app != null && app.isNotEmpty) return app;

    switch (banco) {
      case 'com.nu.production':
        return 'Nubank';
      case 'one.inter':
        return 'Inter';
      case 'com.itau':
        return 'Itaú';
      case 'com.bradesco':
        return 'Bradesco';
      case 'br.gov.caixa.tem':
        return 'Caixa Tem';
      case 'br.com.intermedium':
        return 'Intermedium';
      default:
        return banco;
    }
  }
}

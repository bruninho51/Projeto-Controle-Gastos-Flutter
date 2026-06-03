class NotificacaoBancariaModel {
  final int id;
  final String banco;
  final String descricaoOriginal;
  final String? descricaoNormalizada;
  final double valor;
  final int dataNotificacao;
  final int? gastoId;
  final int dataCriacao;

  NotificacaoBancariaModel({
    required this.id,
    required this.banco,
    required this.descricaoOriginal,
    this.descricaoNormalizada,
    required this.valor,
    required this.dataNotificacao,
    this.gastoId,
    required this.dataCriacao,
  });

  factory NotificacaoBancariaModel.fromMap(Map<Object?, Object?> map) {
    return NotificacaoBancariaModel(
      id: (map['id'] as num).toInt(),
      banco: map['banco'] as String? ?? '',
      descricaoOriginal: map['descricao_original'] as String? ?? '',
      descricaoNormalizada: map['descricao_normalizada'] as String?,
      valor: (map['valor'] as num?)?.toDouble() ?? 0.0,
      dataNotificacao: (map['data_notificacao'] as num?)?.toInt() ?? 0,
      gastoId: (map['gasto_id'] as num?)?.toInt(),
      dataCriacao: (map['data_criacao'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime get dataNotificacaoDateTime =>
      DateTime.fromMillisecondsSinceEpoch(dataNotificacao);

  bool get vinculado => gastoId != null;

  String get nomeBanco {
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

class PadraoRegexNotificacao {
  final int? id;
  final String instituicaoFinanceira;
  final String tituloNotificacao;
  final String regex;
  final DateTime dataCriacao;
  final DateTime dataAtualizacao;
  final DateTime dataExpiracao;

  PadraoRegexNotificacao({
    this.id,
    required this.instituicaoFinanceira,
    required this.tituloNotificacao,
    required this.regex,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.dataExpiracao,
  });

  bool get expirado => DateTime.now().isAfter(dataExpiracao);

  factory PadraoRegexNotificacao.fromMap(Map<String, Object?> map) {
    return PadraoRegexNotificacao(
      id: map['id'] as int?,
      instituicaoFinanceira: map['instituicao_financeira'] as String,
      tituloNotificacao: map['titulo_notificacao'] as String,
      regex: map['regex'] as String,
      dataCriacao: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      dataAtualizacao: DateTime.fromMillisecondsSinceEpoch(map['data_atualizacao'] as int),
      dataExpiracao: DateTime.fromMillisecondsSinceEpoch(map['data_expiracao'] as int),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'instituicao_financeira': instituicaoFinanceira,
      'titulo_notificacao': tituloNotificacao,
      'regex': regex,
      'data_criacao': dataCriacao.millisecondsSinceEpoch,
      'data_atualizacao': dataAtualizacao.millisecondsSinceEpoch,
      'data_expiracao': dataExpiracao.millisecondsSinceEpoch,
    };
  }
}

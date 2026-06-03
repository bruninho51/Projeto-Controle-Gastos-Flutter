class MapeamentoModel {
  final int id;
  final String descricaoOriginal;
  final String descricaoNormalizada;
  final int? gastoId;

  MapeamentoModel({
    required this.id,
    required this.descricaoOriginal,
    required this.descricaoNormalizada,
    this.gastoId,
  });

  factory MapeamentoModel.fromMap(Map<Object?, Object?> map) {
    return MapeamentoModel(
      id: (map['id'] as num).toInt(),
      descricaoOriginal: map['descricao_original'] as String? ?? '',
      descricaoNormalizada: map['descricao_normalizada'] as String? ?? '',
      gastoId: (map['gasto_id'] as num?)?.toInt(),
    );
  }
}

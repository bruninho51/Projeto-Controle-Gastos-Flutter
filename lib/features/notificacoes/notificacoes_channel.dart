import 'package:flutter/services.dart';

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

class NotificacoesChannel {
  static const _channel = MethodChannel('com.bapps.orcamentos/notificacoes');

  static Future<List<NotificacaoBancariaModel>> getAll() async {
    final raw = await _channel.invokeMethod<List<Object?>>('getAll');
    if (raw == null) return [];
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(NotificacaoBancariaModel.fromMap)
        .toList();
  }

  static Future<void> update({
    required int id,
    required double valor,
    required String descricaoNormalizada,
  }) async {
    await _channel.invokeMethod('update', {
      'id': id,
      'valor': valor,
      'descricao_normalizada': descricaoNormalizada,
    });
  }

  static Future<void> associarGasto({
    required int id,
    required int gastoId,
  }) async {
    await _channel.invokeMethod('associarGasto', {
      'id': id,
      'gasto_id': gastoId,
    });
  }

  static Future<void> salvarMapeamento({
    required String descricaoOriginal,
    required String descricaoNormalizada,
    int? gastoId,
  }) async {
    await _channel.invokeMethod('salvarMapeamento', {
      'descricao_original': descricaoOriginal,
      'descricao_normalizada': descricaoNormalizada,
      if (gastoId != null) 'gasto_id': gastoId,
    });
  }

  static Future<void> delete(int id) async {
    await _channel.invokeMethod('delete', {'id': id});
  }

  static Future<MapeamentoModel?> buscarMapeamento(String descricaoOriginal) async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>?>(
      'buscarMapeamento',
      {'descricao_original': descricaoOriginal},
    );
    if (raw == null) return null;
    return MapeamentoModel.fromMap(raw);
  }
}

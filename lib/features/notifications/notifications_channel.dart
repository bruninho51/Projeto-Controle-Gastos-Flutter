import 'package:flutter/services.dart';
import 'package:orcamentos_app/features/notifications/models/mapping_model.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';

class NotificationsChannel {
  static const _channel = MethodChannel('com.bapps.orcamentos/notificacoes');
  static const _bridgeChannel = MethodChannel('notification_bridge');

  /// Escuta as notificações bancárias capturadas nativamente em tempo real
  /// e delega o processamento de cada evento para [onEvent].
  static void listenToBridge(
    Future<void> Function(Map<dynamic, dynamic> evento) onEvent,
  ) {
    _bridgeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNotification') {
        final evento = call.arguments as Map<dynamic, dynamic>;
        await onEvent(evento);
      }
    });
  }

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
    required String descricaoOriginal,
    required String descricaoNormalizada,
  }) async {
    await _channel.invokeMethod('update', {
      'id': id,
      'valor': valor,
      'descricao_original': descricaoOriginal,
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

  static Future<void> marcarErroProcessamento({
    required int id,
    required bool erro,
  }) async {
    await _channel.invokeMethod('marcarErroProcessamento', {
      'id': id,
      'erro': erro,
    });
  }

  static Future<void> delete(int id) async {
    await _channel.invokeMethod('delete', {'id': id});
  }

  static Future<MapeamentoModel?> buscarMapeamento(
      String descricaoOriginal) async {
    final raw = await _channel.invokeMethod<Map<Object?, Object?>?>(
      'buscarMapeamento',
      {'descricao_original': descricaoOriginal},
    );
    if (raw == null) return null;
    return MapeamentoModel.fromMap(raw);
  }
}

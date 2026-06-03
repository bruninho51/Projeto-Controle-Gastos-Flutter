import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';

Map<String, List<NotificacaoBancariaModel>> groupByDay(
    List<NotificacaoBancariaModel> lista) {
  final Map<String, List<NotificacaoBancariaModel>> grupos = {};
  for (final n in lista) {
    final key =
        DateFormat('yyyy-MM-dd').format(n.dataNotificacaoDateTime.toLocal());
    grupos.putIfAbsent(key, () => []).add(n);
  }
  return grupos;
}

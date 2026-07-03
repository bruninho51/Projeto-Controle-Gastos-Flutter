import 'package:orcamentos_app/features/notifications/regex_patterns/models/padrao_regex_notificacao.dart';
import 'package:orcamentos_app/shared/database/app_database.dart';

class PadraoRegexNotificacaoDao {
  static const _table = 'padroes_regex_notificacoes';

  Future<PadraoRegexNotificacao?> findByInstituicaoETitulo(
    String instituicaoFinanceira,
    String tituloNotificacao,
  ) async {
    final db = await AppDatabase.getInstance();
    final rows = await db.query(
      _table,
      where: 'instituicao_financeira = ? AND titulo_notificacao = ?',
      whereArgs: [instituicaoFinanceira, tituloNotificacao],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PadraoRegexNotificacao.fromMap(rows.first);
  }

  Future<int> insert(PadraoRegexNotificacao padrao) async {
    final db = await AppDatabase.getInstance();
    return db.insert(_table, padrao.toMap());
  }

  Future<void> updateRegex({
    required int id,
    required String regex,
    required DateTime dataAtualizacao,
    required DateTime dataExpiracao,
  }) async {
    final db = await AppDatabase.getInstance();
    await db.update(
      _table,
      {
        'regex': regex,
        'data_atualizacao': dataAtualizacao.millisecondsSinceEpoch,
        'data_expiracao': dataExpiracao.millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

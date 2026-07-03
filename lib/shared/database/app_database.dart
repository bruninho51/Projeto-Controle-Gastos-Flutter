import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static const String _dbName = 'orcamentos_local.db';
  static const int _dbVersion = 1;

  static Database? _instance;

  AppDatabase._();

  static Future<Database> getInstance() async {
    _instance ??= await _open();
    return _instance!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE padroes_regex_notificacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        instituicao_financeira TEXT NOT NULL,
        titulo_notificacao TEXT NOT NULL,
        regex TEXT NOT NULL,
        data_criacao INTEGER NOT NULL,
        data_atualizacao INTEGER NOT NULL,
        data_expiracao INTEGER NOT NULL,
        UNIQUE(instituicao_financeira, titulo_notificacao)
      )
    ''');
  }

  // ignore: unused_element_parameter
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Nenhuma migração ainda — reservado para futuras alterações de versão.
  }
}

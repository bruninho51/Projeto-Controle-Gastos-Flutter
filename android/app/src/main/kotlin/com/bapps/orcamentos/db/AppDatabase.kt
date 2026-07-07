package com.bapps.orcamentos.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import com.bapps.orcamentos.db.mapeamentos.MapeamentoNotificacaoDao
import com.bapps.orcamentos.db.mapeamentos.MapeamentoNotificacao
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancaria
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancariaDao

@Database(
    entities = [NotificacaoBancaria::class, MapeamentoNotificacao::class],
    version = 3,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun notificacaoDao(): NotificacaoBancariaDao
    abstract fun mapeamentoDao(): MapeamentoNotificacaoDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        private val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE notificacoes_bancarias ADD COLUMN nome_app TEXT")
            }
        }

        private val MIGRATION_2_3 = object : Migration(2, 3) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL(
                    "ALTER TABLE notificacoes_bancarias ADD COLUMN erro_processamento INTEGER NOT NULL DEFAULT 0"
                )
            }
        }

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "app.db"
                ).addMigrations(MIGRATION_1_2, MIGRATION_2_3).build().also { INSTANCE = it }
            }
    }
}
package com.bapps.orcamentos.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.bapps.orcamentos.db.mapeamentos.MapeamentoNotificacaoDao
import com.bapps.orcamentos.db.mapeamentos.MapeamentoNotificacao
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancaria
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancariaDao

@Database(
    entities = [NotificacaoBancaria::class, MapeamentoNotificacao::class],
    version = 1,
    exportSchema = false,
)
abstract class AppDatabase : RoomDatabase() {

    abstract fun notificacaoDao(): NotificacaoBancariaDao
    abstract fun mapeamentoDao(): MapeamentoNotificacaoDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            INSTANCE ?: synchronized(this) {
                INSTANCE ?: Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "app.db"
                ).build().also { INSTANCE = it }
            }
    }
}
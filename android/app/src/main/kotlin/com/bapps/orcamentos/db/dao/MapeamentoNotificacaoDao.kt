package com.bapps.orcamentos.db.mapeamentos

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface MapeamentoNotificacaoDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(mapeamento: MapeamentoNotificacao): Long

    @Query("SELECT * FROM mapeamentos_notificacoes WHERE descricao_original = :descricao AND soft_delete = 0 LIMIT 1")
    suspend fun findByDescricao(descricao: String): MapeamentoNotificacao?

    @Query("UPDATE mapeamentos_notificacoes SET ultimo_uso = :agora, data_atualizacao = :agora WHERE id = :id")
    suspend fun atualizarUltimoUso(id: Long, agora: Long)
}
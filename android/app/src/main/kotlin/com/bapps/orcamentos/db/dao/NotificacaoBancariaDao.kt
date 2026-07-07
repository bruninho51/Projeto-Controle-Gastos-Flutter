package com.bapps.orcamentos.db.notificacoes

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface NotificacaoBancariaDao {

    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insert(notificacao: NotificacaoBancaria): Long

    @Query("SELECT * FROM notificacoes_bancarias WHERE soft_delete = 0 ORDER BY data_notificacao DESC")
    suspend fun findAll(): List<NotificacaoBancaria>

    @Query("SELECT * FROM notificacoes_bancarias WHERE gasto_id IS NULL AND soft_delete = 0")
    suspend fun findPendentes(): List<NotificacaoBancaria>

    @Query("UPDATE notificacoes_bancarias SET gasto_id = :gastoId, data_atualizacao = :agora WHERE id = :id")
    suspend fun associarGasto(id: Long, gastoId: Long, agora: Long)

    @Query("""
        UPDATE notificacoes_bancarias
        SET valor = :valor,
            descricao_original = :descricaoOriginal,
            descricao_normalizada = :descricaoNormalizada,
            erro_processamento = 0,
            data_atualizacao = :agora
        WHERE id = :id
    """)
    suspend fun update(
        id: Long,
        valor: Double,
        descricaoOriginal: String,
        descricaoNormalizada: String,
        agora: Long
    )

    @Query("UPDATE notificacoes_bancarias SET soft_delete = 1, data_inatividade = :agora WHERE id = :id")
    suspend fun delete(id: Long, agora: Long)

    @Query("UPDATE notificacoes_bancarias SET erro_processamento = :erro, data_atualizacao = :agora WHERE id = :id")
    suspend fun marcarErroProcessamento(id: Long, erro: Int, agora: Long)
}
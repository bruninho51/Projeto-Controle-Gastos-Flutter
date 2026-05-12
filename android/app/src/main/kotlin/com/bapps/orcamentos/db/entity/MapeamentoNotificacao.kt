package com.bapps.orcamentos.db.mapeamentos

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "mapeamentos_notificacoes",
    indices = [Index(value = ["descricao_original"], unique = true)]
)
data class MapeamentoNotificacao (
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    @ColumnInfo(name = "descricao_original")
    val descricaoOriginal: String,

    @ColumnInfo(name = "descricao_normalizada")
    val descricaoNormalizada: String,

    @ColumnInfo(name = "gasto_id")
    val gastoId: Long? = null,

    @ColumnInfo(name = "ultimo_uso")
    val ultimoUso: Long? = null,

    @ColumnInfo(name = "data_criacao")
    val dataCriacao: Long,

    @ColumnInfo(name = "data_atualizacao")
    val dataAtualizacao: Long? = null,

    @ColumnInfo(name = "data_inatividade")
    val dataInatividade: Long? = null,

    @ColumnInfo(name = "soft_delete")
    val softDelete: Int = 0,
)
package com.bapps.orcamentos.db.notificacoes

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "notificacoes_bancarias",
    indices = [
        Index("data_notificacao"),
        Index("gasto_id"),
        Index("banco"),
        Index(value = ["hash_unico"], unique = true),
    ]
)
data class NotificacaoBancaria(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,

    val banco: String,

    @ColumnInfo(name = "descricao_original")
    val descricaoOriginal: String,

    @ColumnInfo(name = "descricao_normalizada")
    val descricaoNormalizada: String? = null,

    val valor: Double,

    @ColumnInfo(name = "payload_bruto")
    val payloadBruto: String? = null,

    @ColumnInfo(name = "data_notificacao")
    val dataNotificacao: Long,

    @ColumnInfo(name = "gasto_id")
    val gastoId: Long? = null,

    @ColumnInfo(name = "hash_unico")
    val hashUnico: String,

    @ColumnInfo(name = "data_criacao")
    val dataCriacao: Long,

    @ColumnInfo(name = "data_atualizacao")
    val dataAtualizacao: Long? = null,

    @ColumnInfo(name = "data_inatividade")
    val dataInatividade: Long? = null,

    @ColumnInfo(name = "soft_delete")
    val softDelete: Int = 0,
)
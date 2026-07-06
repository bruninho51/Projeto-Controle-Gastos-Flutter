package com.bapps.orcamentos.notificacoes

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import com.bapps.orcamentos.db.AppDatabase
import com.bapps.orcamentos.db.mapeamentos.MapeamentoNotificacao

class NotificacoesFlutterCallReceiver(
    private val context: Context
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.bapps.orcamentos/notificacoes"
    }

    private val db by lazy { AppDatabase.getInstance(context) }
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // ── Notificações ────────────────────────────────────────────────

            "getAll" -> scope.launch {
                try {
                    val lista = db.notificacaoDao().findAll()
                    val mapList = lista.map { n ->
                        val titulo = try {
                            n.payloadBruto?.let { JSONObject(it).optString("title") }
                        } catch (e: Exception) {
                            null
                        }
                        mapOf(
                            "id" to n.id,
                            "banco" to n.banco,
                            "nome_app" to n.nomeApp,
                            "descricao_original" to n.descricaoOriginal,
                            "descricao_normalizada" to n.descricaoNormalizada,
                            "valor" to n.valor,
                            "titulo_notificacao" to titulo,
                            "data_notificacao" to n.dataNotificacao,
                            "gasto_id" to n.gastoId,
                            "data_criacao" to n.dataCriacao
                        )
                    }
                    result.success(mapList)
                } catch (e: Exception) {
                    result.error("DB_ERROR", e.message, null)
                }
            }

            "update" -> {
                val id = (call.argument<Any>("id") as? Number)?.toLong()
                    ?: return result.error("INVALID_ARG", "id obrigatório", null)
                val valor = (call.argument<Any>("valor") as? Number)?.toDouble()
                    ?: return result.error("INVALID_ARG", "valor obrigatório", null)
                val descricaoOriginal = call.argument<String>("descricao_original")
                    ?: return result.error("INVALID_ARG", "descricao_original obrigatória", null)
                val descricaoNormalizada = call.argument<String>("descricao_normalizada")
                    ?: return result.error("INVALID_ARG", "descricao_normalizada obrigatória", null)

                scope.launch {
                    try {
                        db.notificacaoDao().update(
                            id = id,
                            valor = valor,
                            descricaoOriginal = descricaoOriginal,
                            descricaoNormalizada = descricaoNormalizada,
                            agora = System.currentTimeMillis()
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
            }

            "associarGasto" -> {
                val id = (call.argument<Any>("id") as? Number)?.toLong()
                    ?: return result.error("INVALID_ARG", "id obrigatório", null)
                val gastoId = (call.argument<Any>("gasto_id") as? Number)?.toLong()
                    ?: return result.error("INVALID_ARG", "gasto_id obrigatório", null)

                scope.launch {
                    try {
                        db.notificacaoDao().associarGasto(
                            id = id,
                            gastoId = gastoId,
                            agora = System.currentTimeMillis()
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
            }

            // ── Mapeamentos ─────────────────────────────────────────────────

            "salvarMapeamento" -> {
                val descricaoOriginal = call.argument<String>("descricao_original")
                    ?: return result.error("INVALID_ARG", "descricao_original obrigatória", null)
                val descricaoNormalizada = call.argument<String>("descricao_normalizada")
                    ?: return result.error("INVALID_ARG", "descricao_normalizada obrigatória", null)
                val gastoId = (call.argument<Any>("gasto_id") as? Number)?.toLong()
                val agora = System.currentTimeMillis()

                scope.launch {
                    try {
                        val existing = db.mapeamentoDao().findByDescricao(descricaoOriginal)
                        if (existing != null) {
                            db.mapeamentoDao().updateByDescricaoOriginal(
                                descricaoOriginal = descricaoOriginal,
                                descricaoNormalizada = descricaoNormalizada,
                                gastoId = gastoId,
                                agora = agora
                            )
                        } else {
                            db.mapeamentoDao().insert(
                                MapeamentoNotificacao(
                                    descricaoOriginal = descricaoOriginal,
                                    descricaoNormalizada = descricaoNormalizada,
                                    gastoId = gastoId,
                                    ultimoUso = agora,
                                    dataCriacao = agora
                                )
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
            }

            "delete" -> {
                val id = (call.argument<Any>("id") as? Number)?.toLong()
                    ?: return result.error("INVALID_ARG", "id obrigatório", null)

                scope.launch {
                    try {
                        db.notificacaoDao().delete(id = id, agora = System.currentTimeMillis())
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
            }

            "buscarMapeamento" -> {
                val descricaoOriginal = call.argument<String>("descricao_original")
                    ?: return result.error("INVALID_ARG", "descricao_original obrigatória", null)

                scope.launch {
                    try {
                        val mapeamento = db.mapeamentoDao().findByDescricao(descricaoOriginal)
                        if (mapeamento != null) {
                            result.success(mapOf(
                                "id" to mapeamento.id,
                                "descricao_original" to mapeamento.descricaoOriginal,
                                "descricao_normalizada" to mapeamento.descricaoNormalizada,
                                "gasto_id" to mapeamento.gastoId
                            ))
                        } else {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        result.error("DB_ERROR", e.message, null)
                    }
                }
            }

            else -> result.notImplemented()
        }
    }
}

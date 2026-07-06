package com.bapps.orcamentos.notifications

import android.os.Handler
import android.os.HandlerThread
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.bapps.orcamentos.db.AppDatabase
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancaria
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import java.security.MessageDigest

class NotificationListener : NotificationListenerService() {

    private lateinit var workerThread: HandlerThread
    private lateinit var workerHandler: Handler
    private lateinit var db: AppDatabase

    companion object {
        private const val TAG = "NOTIF"

        private val ALLOWED_PACKAGES = setOf(
            "com.nu.production",
            "br.com.intermedium",
            "br.gov.caixa.tem",
            "com.bradesco",
            "com.itau",
            "one.inter",
            "com.mand.notitest",
            "br.com.ifood.benefits",
            "air.br.com.alelo.mobile.android"
        )

        // Valor monetário em formato brasileiro (ex.: "1.234,56" ou "32,50").
        // Não reconhece valores por extenso ou em outros formatos (ex.: "32.50", "32", "R$ 32").
        private val VALOR_REGEX =
            Regex("""\b\d{1,3}(?:\.\d{3})*,\d{2}\b|\b\d+,\d{2}\b""")
    }

    override fun onCreate() {
        super.onCreate()
        workerThread = HandlerThread("NotificationWorker").also { it.start() }
        workerHandler = Handler(workerThread.looper)
        db = AppDatabase.getInstance(applicationContext)
    }

    override fun onDestroy() {
        workerThread.quitSafely()
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName
        if (packageName !in ALLOWED_PACKAGES) return

        val notification = sbn.notification
        val postTime     = sbn.postTime

        workerHandler.post {
            val extras = notification.extras

            val title = extras.getCharSequence("android.title")
                ?.toString()
                ?.trim()
                .orEmpty()

            val content = extras.getCharSequence("android.text")
                ?.toString()
                ?.trim()
                .orEmpty()

            Log.d(TAG, "[$packageName] $title - $content")

            if (content.isBlank()) {
                Log.d(TAG, "Notificação descartada: conteúdo vazio [$packageName]")
                return@post
            }

            val valoresEncontrados = VALOR_REGEX.findAll(content).map { it.value }.toList()
            if (valoresEncontrados.size != 1) {
                Log.d(
                    TAG,
                    "Notificação descartada: ${valoresEncontrados.size} valores monetários " +
                        "encontrados [$packageName] - $content",
                )
                return@post
            }

            val valor = parseValorBrasileiro(valoresEncontrados.first())

            // A extração de descrição via regex acontece no lado Dart
            // (NotificationProcessingService), que resolve a regex através do
            // cache local/API e atualiza este registro pelo canal "update".
            val payload = JSONObject().apply {
                put("package",   packageName)
                put("title",     title)
                put("content",   content)
                put("timestamp", postTime)
            }.toString()

            runBlocking {
                val mapeamento = db.mapeamentoDao().findByDescricao(content)

                val notificacao = NotificacaoBancaria(
                    banco                = packageName,
                    nomeApp              = nomeDoApp(packageName),
                    descricaoOriginal    = content,
                    descricaoNormalizada = mapeamento?.descricaoNormalizada,
                    valor                = valor,
                    payloadBruto         = payload,
                    dataNotificacao      = postTime,
                    hashUnico            = buildHash(packageName, content, postTime),
                    dataCriacao          = System.currentTimeMillis(),
                )

                val inserted = db.notificacaoDao().insert(notificacao)
                Log.d(TAG, "Salvo no banco (aguardando extração): id=$inserted — descricao=$content")

                if (mapeamento != null) {
                    db.mapeamentoDao().atualizarUltimoUso(mapeamento.id, System.currentTimeMillis())
                }

                NotificationBridge.sendNotification(
                    mapOf(
                        "id"        to inserted,
                        "package"   to packageName,
                        "title"     to title,
                        "content"   to content,
                        "timestamp" to postTime,
                    )
                )
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) = Unit

    // ── Nome do app bancário instalado ───────────────────────────────────────

    private fun nomeDoApp(packageName: String): String? {
        return try {
            val pm = applicationContext.packageManager
            val info = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            Log.w(TAG, "Não foi possível resolver o nome do app para $packageName", e)
            null
        }
    }

    // ── Valor monetário em formato brasileiro (ex.: "1.234,56" → 1234.56) ────

    private fun parseValorBrasileiro(valor: String): Double {
        return valor.replace(".", "").replace(",", ".").toDouble()
    }

    // ── Hash para deduplicação ────────────────────────────────────────────────

    private fun buildHash(
        banco: String,
        descricao: String,
        timestamp: Long,
    ): String {
        val raw = "$banco|$descricao|$timestamp"
        return MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }
}
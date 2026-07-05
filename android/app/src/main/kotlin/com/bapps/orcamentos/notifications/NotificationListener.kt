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
            val extras  = notification.extras
            val title   = extras.getCharSequence("android.title")?.toString().orEmpty()
            val content = extras.getCharSequence("android.text")?.toString().orEmpty()

            Log.d(TAG, "[$packageName] $title - $content")

            // A extração de valor/descrição via regex acontece no lado Dart
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
                    valor                = 0.0,
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
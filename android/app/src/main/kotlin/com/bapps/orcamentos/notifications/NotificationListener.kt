package com.bapps.orcamentos.notifications

import android.os.Handler
import android.os.HandlerThread
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.bapps.orcamentos.db.AppDatabase
import com.bapps.orcamentos.db.notificacoes.NotificacaoBancaria
import com.bapps.orcamentos.notifications.parser.NotificationParserFactory
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
            "com.mand.notitest"
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

            val parser    = NotificationParserFactory.getParser(packageName)
            val parsed    = parser.parse(title, content)
            val valor     = parsed.valor
            val descricao = parsed.descricao ?: content

            val payload = JSONObject().apply {
                put("package",   packageName)
                put("title",     title)
                put("content",   content)
                put("timestamp", postTime)
            }.toString()

            if (valor != null) {
                runBlocking {
                    val mapeamento = db.mapeamentoDao().findByDescricao(descricao)

                    val notificacao = NotificacaoBancaria(
                        banco                = packageName,
                        descricaoOriginal    = descricao,
                        descricaoNormalizada = mapeamento?.descricaoNormalizada,
                        valor                = valor,
                        payloadBruto         = payload,
                        dataNotificacao      = postTime,
                        hashUnico            = buildHash(packageName, descricao, valor, postTime),
                        dataCriacao          = System.currentTimeMillis(),
                    )

                    val inserted = db.notificacaoDao().insert(notificacao)
                    Log.d(TAG, "Salvo no banco: id=$inserted — descricao=$descricao — valor=$valor — normalizada=${mapeamento?.descricaoNormalizada}")

                    if (mapeamento != null) {
                        db.mapeamentoDao().atualizarUltimoUso(mapeamento.id, System.currentTimeMillis())
                    }
                }
            } else {
                Log.d(TAG, "Valor não encontrado na notificação, ignorando salvamento")
            }

            NotificationBridge.sendNotification(
                mapOf(
                    "package"   to packageName,
                    "title"     to title,
                    "content"   to content,
                    "timestamp" to postTime,
                    "valor"     to (valor ?: 0.0),
                )
            )
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) = Unit

    // ── Hash para deduplicação ────────────────────────────────────────────────

    private fun buildHash(
        banco: String,
        descricao: String,
        valor: Double,
        timestamp: Long,
    ): String {
        val raw = "$banco|$descricao|$valor|$timestamp"
        return MessageDigest.getInstance("SHA-256")
            .digest(raw.toByteArray())
            .joinToString("") { "%02x".format(it) }
    }
}
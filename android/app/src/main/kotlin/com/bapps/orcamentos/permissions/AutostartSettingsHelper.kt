package com.bapps.orcamentos.permissions

import android.app.Activity
import android.content.ComponentName
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import android.util.Log

/**
 * Várias fabricantes (Xiaomi/MIUI, Huawei/Honor, Oppo/ColorOS, Vivo,
 * Asus, Letv, OnePlus...) restringem apps em segundo plano numa camada
 * própria, abaixo das permissões padrão do Android — o que pode fazer o
 * NotificationListenerService parar de receber eventos mesmo com a
 * permissão concedida e o rebind confirmado pelo sistema.
 *
 * Não existe uma API oficial para isso: cada fabricante tem sua própria
 * tela de "autoinício"/"inicialização automática", em componentes não
 * documentados que variam entre versões de firmware. Por isso tentamos uma
 * lista de combinações conhecidas, na ordem, e paramos na primeira que
 * existir no aparelho — com fallback para as configurações padrão do app
 * caso nenhuma exista.
 */
object AutostartSettingsHelper {
    private const val TAG = "AutostartSettings"

    private val CANDIDATOS = listOf(
        ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"),
        ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"),
        ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"),
        ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"),
        ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"),
        ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity"),
        ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.autostart.AutoStartActivity"),
        ComponentName("com.oneplus.security", "com.oneplus.security.chainlaunch.view.ChainLaunchAppListActivity"),
    )

    /** Retorna `true` se alguma tela específica de fabricante foi aberta, `false` se caiu no fallback. */
    fun open(activity: Activity): Boolean {
        for (componentName in CANDIDATOS) {
            val intent = Intent().apply {
                component = componentName
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            try {
                activity.startActivity(intent)
                Log.d(TAG, "Tela de autoinício aberta: $componentName")
                return true
            } catch (e: Exception) {
                // Componente não existe nesse fabricante/versão — tenta o próximo.
            }
        }

        Log.w(TAG, "Nenhuma tela de autoinício conhecida encontrada — abrindo configurações do app")
        openAppSettingsFallback(activity)
        return false
    }

    private fun openAppSettingsFallback(activity: Activity) {
        try {
            activity.startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${activity.packageName}")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                },
            )
        } catch (e: Exception) {
            Log.e(TAG, "Falha até no fallback de configurações do app: ${e.message}", e)
        }
    }
}

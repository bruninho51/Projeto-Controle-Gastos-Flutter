package com.bapps.orcamentos.notifications.parser

data class ParsedNotification(
    val valor: Double?,
    val descricao: String?,
)

interface NotificationParser {
    fun parse(title: String, content: String): ParsedNotification
}
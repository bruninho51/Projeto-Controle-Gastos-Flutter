package com.bapps.orcamentos.notifications.parser

import java.util.regex.Pattern

class GenericParser : NotificationParser {

    override fun parse(title: String, content: String): ParsedNotification {
        return ParsedNotification(
            valor     = extractValor(content),
            descricao = extractDescricao(content),
        )
    }

    private fun extractDescricao(content: String): String? {
        val regex = Regex("""[A-ZÁÉÍÓÚÃÕÂÊÎÔÛÀÇ]{4,}(?:\s+[A-ZÁÉÍÓÚÃÕÂÊÎÔÛÀÇ]+)*""")
        val matches = regex.findAll(content)
            .map { it.value.trim() }
            .filter { it.replace(" ", "").length >= 4 }
            .toList()
        return if (matches.isEmpty()) content else matches.joinToString(" ")
    }

    private fun extractValor(text: String): Double? {
        val regex = Regex("""R?\$?\s*(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2}))""")
        val match = regex.find(text) ?: return null
        val raw   = match.groupValues[1]
            .replace(".", "")
            .replace(",", ".")
        return raw.toDoubleOrNull()
    }
}
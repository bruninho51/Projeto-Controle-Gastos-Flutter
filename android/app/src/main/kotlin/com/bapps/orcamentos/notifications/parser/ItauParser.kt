package com.bapps.orcamentos.notifications.parser

class ItauParser : NotificationParser {

    // Adicione exemplos reais do Itaú aqui para ajustar o parser

    override fun parse(title: String, content: String): ParsedNotification {
        return ParsedNotification(
            valor     = extractValor(content),
            descricao = extractDescricao(content),
        )
    }

    private fun extractValor(content: String): Double? {
        val regex = Regex("""R\$\s*(\d{1,3}(?:\.\d{3})*,\d{2})""")
        val match = regex.find(content) ?: return null
        return match.groupValues[1]
            .replace(".", "")
            .replace(",", ".")
            .toDoubleOrNull()
    }

    private fun extractDescricao(content: String): String? {
        val regex = Regex("""[A-ZÁÉÍÓÚÃÕÂÊÎÔÛÀÇ]{4,}(?:\s+[A-ZÁÉÍÓÚÃÕÂÊÎÔÛÀÇ]+)*""")
        return regex.findAll(content)
            .map { it.value.trim() }
            .filter { it.replace(" ", "").length >= 4 }
            .joinToString(" ")
            .ifEmpty { content }
    }
}
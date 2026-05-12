package com.bapps.orcamentos.notifications.parser

object NotificationParserFactory {

    fun getParser(packageName: String): NotificationParser = when (packageName) {
        "com.nu.production"   -> NubankParser()
        "one.inter"           -> InterParser()
        "com.itau"            -> ItauParser()
        else                  -> GenericParser()
    }
}
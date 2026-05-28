# Kotlin Style Guide

> Usado na camada nativa Android do Orçamentos App (plugins Flutter, integrações de sistema como notificações e permissões).

## Formatting

- Indentação: 4 espaços
- Linha máxima: 120 caracteres
- Usar `ktfmt` ou o formatter padrão do Android Studio

## Naming Conventions

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Classes | UpperCamelCase | `NotificationHandler` |
| Funções/variáveis | lowerCamelCase | `handleNotification()` |
| Constantes | SCREAMING_SNAKE_CASE | `MAX_RETRY_COUNT` |
| Arquivos | UpperCamelCase | `NotificationHandler.kt` |
| Pacotes | lowercase.separado.por.ponto | `com.orcamentos.notifications` |

## Flutter Plugin / MethodChannel

- Tratar todos os erros de MethodChannel e retornar resultados tipados
- Nunca deixar exceções propagarem sem tratamento no lado nativo

```kotlin
override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
        "getDeviceInfo" -> {
            try {
                result.success(getDeviceInfo())
            } catch (e: Exception) {
                result.error("DEVICE_INFO_ERROR", e.message, null)
            }
        }
        else -> result.notImplemented()
    }
}
```

## Null Safety

- Preferir tipos não-nulos sempre que possível
- Usar `?.` e `?:` em vez de verificações explícitas de null quando legível
- Evitar `!!` (non-null assertion) — tratar o caso nulo explicitamente

```kotlin
// Preferir
val name = user?.name ?: "Usuário"

// Evitar
val name = user!!.name
```

## Coroutines

- Usar `suspend` functions para operações assíncronas
- Preferir `viewModelScope` ou `lifecycleScope` para escopo de coroutines
- Sempre usar `Dispatchers.IO` para operações de I/O

```kotlin
suspend fun fetchExpenses(): List<Expense> = withContext(Dispatchers.IO) {
    // operação de rede ou banco de dados
}
```

## Android Components

- Activities e Fragments devem ser magros — delegar lógica a ViewModels ou repositórios
- Usar View Binding em vez de `findViewById`
- Registrar e desregistrar receivers/listeners no ciclo de vida correto

## Notifications (Firebase Messaging)

- Tratar mensagens em foreground e background separadamente
- Notificações com dados financeiros nunca devem exibir valores sensíveis no título/corpo quando o dispositivo está bloqueado

## Comments

- Comentar apenas o "porquê", não o "o quê"
- KDoc para funções públicas de plugins que serão chamadas pelo Flutter

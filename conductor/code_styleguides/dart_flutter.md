# Dart / Flutter Style Guide

## Formatting

- Use `dart format` (formatter oficial) — linha máxima de 80 caracteres
- Trailing commas em listas e parâmetros com múltiplos itens para melhor formatação
- Imports organizados em grupos: dart, flutter, packages externos, packages internos

```dart
// Ordem de imports
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import 'package:orcamentos_app/features/auth/auth_service.dart';
import 'package:orcamentos_app/shared/models/expense.dart';
```

## Naming Conventions

| Elemento | Convenção | Exemplo |
|----------|-----------|---------|
| Classes | UpperCamelCase | `ExpenseRepository` |
| Variáveis/funções | lowerCamelCase | `fetchExpenses()` |
| Constantes | lowerCamelCase | `maxBudgetLimit` |
| Arquivos | snake_case | `expense_repository.dart` |
| Diretórios | snake_case | `features/despesas/` |

## File Structure

Organização por feature (feature-first):

```
lib/
  features/
    auth/
      pages/
      components/
      services/
      models/
    despesas/
      pages/
      components/
      repositories/
      models/
  shared/
    components/
    models/
    utils/
  providers/
```

## Widgets

- Preferir `StatelessWidget` quando não há estado local
- Extrair widgets complexos em classes separadas (não funções)
- Nomear widgets de forma descritiva: `ExpenseCategoryChip`, não `ChipWidget`
- `const` constructors sempre que possível

```dart
// Preferir
class ExpenseTile extends StatelessWidget {
  const ExpenseTile({super.key, required this.expense});
  final Expense expense;
  // ...
}

// Evitar (função retornando widget)
Widget buildExpenseTile(Expense expense) { ... }
```

## State Management (Provider)

- Um `ChangeNotifier` por domínio (ex: `ExpenseProvider`, `BudgetProvider`)
- Não expor estado mutável diretamente — usar getters e `notifyListeners()`
- `Consumer` ou `context.watch()` apenas nos widgets que precisam reconstruir

```dart
class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  List<Expense> get expenses => List.unmodifiable(_expenses);

  Future<void> loadExpenses() async {
    _expenses = await _repository.fetchAll();
    notifyListeners();
  }
}
```

## Error Handling

- Usar `Result` pattern ou classes de erro tipadas para operações assíncronas
- Nunca silenciar exceções com catch vazio
- Erros de UI devem ter mensagens amigáveis ao usuário (ver product-guidelines.md)

```dart
// Preferir
try {
  final result = await repository.save(expense);
  // handle success
} catch (e) {
  // log + mostrar mensagem amigável
}
```

## Async/Await

- Preferir `async/await` sobre `.then()` para legibilidade
- Sempre tratar erros em operações assíncronas
- Cancelar subscriptions e StreamControllers no `dispose()`

## Data Models

- Usar `json_serializable` para serialização/deserialização JSON
- Modelos imutáveis com `copyWith` para atualizações

```dart
@JsonSerializable()
class Expense {
  const Expense({required this.id, required this.amount, required this.description});

  final String id;
  final double amount;
  final String description;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseToJson(this);

  Expense copyWith({String? id, double? amount, String? description}) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }
}
```

## Currency & Numbers

- Sempre usar `intl` para formatação de moeda: `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')`
- Nunca fazer aritmética com `double` para valores monetários em contextos críticos — usar inteiros (centavos) ou `Decimal`

## Testing

- Testes em `test/` espelhando estrutura de `lib/`
- `flutter_test` para widget e unit tests
- Mocks com `mockito` ou implementações fake simples
- Nomear testes descritivamente: `'deve retornar erro quando orçamento excedido'`

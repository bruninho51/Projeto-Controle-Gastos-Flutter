# Implementation Plan: Refactor — Categories Feature

**Track ID:** categories-refactor_20260603
**Spec:** [spec.md](./spec.md)
**Created:** 2026-06-03
**Status:** [ ] Not Started

## Overview

Refatoração estrutural da feature `categories` em três fases sequenciais:

1. **Fundação** — criar utilitário e service sem dependências de widgets
2. **Componentes** — extrair widgets visuais (card, dialog, empty state)
3. **Page** — substituir header legado por `SharedAppBar` e conectar tudo

Cada fase é independentemente verificável. A page `lib/features/categories/pages/categorias_gastos_page.dart` já foi movida para a estrutura `features/` — o trabalho restante é a extração dos componentes e a migração do header.

---

## Phase 1: Fundação — Utilitários e Service

Criar os dois artefatos sem dependência de widget, garantindo que a separação de responsabilidades seja estabelecida antes de tocar nos componentes visuais.

### Tasks

- [x] Task 1.1: Criar `lib/features/categories/utils/category_icon_mapper.dart`
  - Extrair `_getIconForCategoria(String nome)` e `_containsAny(String, List<String>)` da page
  - Criar `class CategoryIconMapper` com `static IconData getIcon(String nome)`
  - Preservar exatamente todas as regras de mapeamento atuais (13 categorias + fallback)

- [x] Task 1.2: Criar `lib/features/categories/services/categories_service.dart`
  - Criar `class CategoriesService` recebendo `ApiService apiService` via construtor
  - Implementar `Future<List<CategoriaGastoResponseDto>> getCategorias()`
  - Implementar `Future<void> createCategoria(CategoriaGastoCreateDto dto)`
  - Implementar `Future<void> deleteCategoria(int id)`
  - Delegar para os métodos já existentes no `ApiService`

### Verification

- [ ] `flutter analyze` sem erros ou warnings novos
- [ ] `CategoryIconMapper` e `CategoriesService` não importam widgets (`package:flutter/material.dart` apenas se necessário para `IconData`)

---

## Phase 2: Componentes Visuais

Extrair os três componentes visuais da page. Cada extração é independente e pode ser feita em qualquer ordem.

### Tasks

- [x] Task 2.1: Criar `lib/features/categories/components/category_card.dart`
  - Renomear `_CategoriaCard` para `CategoryCard` (widget público)
  - Preservar integralmente: `AnimationController`, `_fadeAnim`, `_slideAnim`, timing escalonado por índice (`300 + index * 60`), layout, cores, botão excluir, `InkWell` com splash/highlight
  - Props: `categoria`, `color`, `icon`, `index`, `onDelete`

- [x] Task 2.2: Criar `lib/features/categories/components/categories_empty_state.dart`
  - Extrair `_buildEmptyState()` para `class CategoriesEmptyState extends StatelessWidget`
  - Preservar: ícone, textos, espaçamentos, cores exatas

- [x] Task 2.3: Criar `lib/features/categories/components/category_create_dialog.dart`
  - Extrair toda a lógica de `_showCreateCategoriaDialog()` para uma função top-level:
    `Future<void> showCategoryCreateDialog({required BuildContext context, required Future<void> Function(String nome) onConfirm})`
  - O dialog gerencia internamente `TextEditingController` e `GlobalKey<FormState>`
  - Preservar: layout, validação ("O nome não pode ser vazio!"), botões Cancelar/Salvar, bordas, cores, autofocus
  - A page passa apenas o callback `onConfirm`; não precisa mais de `_nomeCategoriaController` nem `_formKey`

### Verification

- [ ] `flutter analyze` sem erros
- [ ] Componentes não contêm lógica de negócio (sem chamadas a `ApiService` ou `CategoriesService`)

---

## Phase 3: Refatoração da CategoriesPage

Conectar todos os artefatos criados e migrar o header legado para `SharedAppBar`.

### Tasks

- [ ] Task 3.1: Substituir `_CategoriasHeader` por `SharedAppBar` na page
  - Configurar `SharedAppBar`:
    ```dart
    SharedAppBar(
      title: 'Categorias',
      subtitle: 'Organize seus tipos de gasto',
      mainIcon: Icons.category_rounded,
      gradientColors: const [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
      showBackButton: true,
      onBack: () => Navigator.of(context).pop(),
      showAvatar: false,
      bottomContent: _buildCategoryBadge(),   // badge animado com contagem
      actionButtons: [
        SharedAppBar.headerButton(child: ..., onTap: _showCreateCategoriaDialog, tooltip: 'Nova categoria'),
        SharedAppBar.headerButton(child: RotationTransition(...), onTap: _handleRefresh, tooltip: 'Recarregar', isSquare: true),
      ],
    )
    ```
  - `_buildCategoryBadge()` retorna o widget de badge com contagem (pode ser método privado da page)
  - `_PulseDot` pode ser mantido como widget privado inline na page para uso no badge
  - NÃO modificar o código do `SharedAppBar`

- [ ] Task 3.2: Atualizar a page para usar `CategoriesService` e componentes extraídos
  - Instanciar `CategoriesService` com `Provider.of<ApiService>(context, listen: false)` no `initState`
  - Substituir todas as chamadas diretas ao `apiService` por chamadas ao `_categoriesService`
  - Substituir `_CategoriaCard` por `CategoryCard`
  - Substituir `_buildEmptyState()` por `CategoriesEmptyState()`
  - Substituir `_showCreateCategoriaDialog()` por `showCategoryCreateDialog(...)`
  - Usar `CategoryIconMapper.getIcon(categoria.nome)` no lugar de `_getIconForCategoria`
  - Remover `_formKey` e `_nomeCategoriaController` (agora gerenciados pelo dialog)

- [ ] Task 3.3: Limpar código legado e imports
  - Remover classes `_CategoriasHeader`, `_HeaderButton`, `_PulseDot` (exceto se `_PulseDot` for mantido para o badge)
  - Remover `_CategoriaCard` (substituído por `CategoryCard`)
  - Remover `_getIconForCategoria` e `_containsAny` (substituídos por `CategoryIconMapper`)
  - Atualizar imports: adicionar novos, remover os não utilizados
  - Verificar que nenhum import de `ApiService` permanece na page de forma direta (apenas via `CategoriesService`)

### Verification

- [ ] `flutter analyze` sem erros ou warnings introduzidos
- [ ] `flutter test` — todos os testes passando
- [ ] Verificação manual dos fluxos:
  - [ ] Carregar lista de categorias ao abrir a tela
  - [ ] Refresh via botão no header
  - [ ] Criar nova categoria via dialog (incluindo validação de campo vazio)
  - [ ] Excluir categoria com confirmação
  - [ ] Exibir estado vazio quando não há categorias
  - [ ] Animações fade/slide dos cards ao carregar
  - [ ] Navegação de retorno
- [ ] Código do `SharedAppBar` não foi modificado

---

## Final Verification

- [ ] Todos os critérios de aceitação do `spec.md` atendidos
- [ ] Estrutura de arquivos corresponde exatamente ao definido no spec
- [ ] `flutter analyze` sem erros introduzidos pela refatoração
- [ ] Imports antigos removidos; sem código morto
- [ ] Page não depende diretamente de `ApiService`
- [ ] `SharedAppBar` em uso; header legado completamente removido
- [ ] Comportamento visual e funcional equivalente ao original

---

_Generated by Conductor. Tasks will be marked [~] in progress and [x] complete._

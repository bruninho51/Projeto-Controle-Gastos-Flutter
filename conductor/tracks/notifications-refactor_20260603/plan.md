# Implementation Plan: Refactor — Notifications Feature

**Track ID:** notifications-refactor_20260603
**Spec:** [spec.md](./spec.md)
**Created:** 2026-06-03
**Status:** [x] Complete

## Overview

Refatoração em 4 fases sequenciais. A ordem importa: os modelos são criados primeiro
(sem dependências), depois o channel os importa, depois os componentes são extraídos,
por fim as pages são criadas e os arquivos legados removidos. Em nenhum momento
arquivos existentes são modificados antes de os substitutos estarem prontos.

---

## Phase 1: Models e Channel

Extrair os modelos do channel para arquivos próprios e recriar o channel no novo
local importando os modelos externos. Nenhum arquivo existente é modificado nesta fase.

### Tasks

- [x] Task 1.1: Criar diretório `lib/features/notifications/models/` e criar
  `notification_model.dart` com `NotificacaoBancariaModel` (exatamente como está em
  `notificacoes_channel.dart`, incluindo `fromMap`, `dataNotificacaoDateTime`,
  `vinculado` e `nomeBanco`)
- [x] Task 1.2: Criar `models/mapping_model.dart` com `MapeamentoModel` (exatamente
  como está no channel atual, incluindo `fromMap`)
- [x] Task 1.3: Criar `lib/features/notifications/notifications_channel.dart` com
  `NotificationsChannel` — mesma implementação do channel atual, removendo as duas
  classes de modelo e adicionando imports de `notification_model.dart` e
  `mapping_model.dart`. Renomear classe `NotificacoesChannel` → `NotificationsChannel`

### Verification

- [x] `flutter analyze` sem erros nos 3 novos arquivos
- [x] Nenhum arquivo existente modificado nesta fase

---

## Phase 2: Utils e Componentes

Extrair o utilitário de agrupamento e os 4 componentes visuais da NotificacoesPage
atual. Todos os novos arquivos importam do novo channel e modelos.

### Tasks

- [x] Task 2.1: Criar `lib/features/notifications/utils/notifications_grouping.dart`
  com função pura `groupByDay(List<NotificacaoBancariaModel> lista)`
  extraída de `_ListaNotificacoes._agruparPorDia()`

- [x] Task 2.2: Criar `components/notification_list_item.dart` com `NotificationListItem`
  (widget público, era `_NotificacaoItem`). Preservar exatamente: ícones por banco,
  cores por banco, badge "Vinculado", separador entre itens, interação `InkWell`.
  Substituir `.withOpacity()` por `.withValues(alpha:)`

- [x] Task 2.3: Criar `components/notification_day_group.dart` com `NotificationDayGroup`
  (widget público, era `_DiaGroup`). Preservar: `_diaLabel`, `_diaSemana`, cálculo
  de total, card branco com sombra. Substituir `.withOpacity()` por `.withValues(alpha:)`

- [x] Task 2.4: Criar `components/notifications_list.dart` com `NotificationsList`
  (widget público, era `_ListaNotificacoes`). Usa `groupByDay()` e `NotificationDayGroup`.
  Preservar: `CustomScrollView`, `BouncingScrollPhysics`, padding `fromLTRB(16,12,16,100)`

- [x] Task 2.5: Criar `components/notifications_states.dart` com 3 widgets públicos:
  `NotificationsEmptyState` (era `_EmptyState`), `NotificationsErrorState`
  (era `_ErrorState`), `NotificationsWebUnsupportedState` (era `_WebUnsupported`).
  Substituir `.withOpacity()` por `.withValues(alpha:)`

### Verification

- [x] `flutter analyze` sem erros nos 5 novos arquivos
- [x] Nenhum arquivo existente modificado nesta fase

---

## Phase 3: Pages com SharedAppBar

Criar as duas pages refatoradas com SharedAppBar azul. Os arquivos antigos ainda
existem nesta fase — serão removidos na Phase 4.

### Tasks

- [x] Task 3.1: Criar `lib/features/notifications/pages/notifications_page.dart`
  com `NotificationsPage`:
  - Importa channel, componentes e states do novo local
  - Substitui `_NotificacoesHeader` por `SharedAppBar`:
    - `title: 'Notificações'`, `subtitle: 'Capturas bancárias'`
    - `gradientColors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)]`
    - `showAvatar: true`
    - `bottomContent`: filter toggle pill (mesma lógica atual, preservando animação)
    - `actionButtons: [SharedAppBar.headerButton(refresh)]`
  - Usa `NotificationsList`, `NotificationsEmptyState`, `NotificationsErrorState`,
    `NotificationsWebUnsupportedState`
  - Remove `_NotificacoesHeader`, `_HeaderButton` (usará o do SharedAppBar)
  - Mantém toda lógica de estado: `_future`, `_refreshCtrl`, `_isRefreshing`,
    `_apenasNaoVinculadas`, `_fetch()`, `_abrirEdicao()`, `_handleRefresh()`
  - Navega para `NotificationEditPage` (novo)

- [x] Task 3.2: Criar `lib/features/notifications/pages/notification_edit_page.dart`
  com `NotificationEditPage`:
  - Move conteúdo de `notificacao_edicao_page.dart`
  - Renomeia classe `NotificacaoEdicaoPage` → `NotificationEditPage`
  - Substitui `_buildHeader()` por `SharedAppBar`:
    - `title: 'Editar Notificação'`, `subtitle: nomeBanco`
    - `gradientColors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)]`
    - `showBackButton: true`, `onBack: Navigator.of(context).pop()`
    - `showAvatar: false`
    - `actionButtons: [SharedAppBar.headerButton(delete, isSquare: true)]`
  - Remove `_teal`, `_tealDark` (constantes verdes) — substituir pelo azul onde
    necessário (focusBorder dos TextFields, botão salvar, etc.)
  - Mantém todos os widgets privados internos sem extração
  - Importa `NotificationsChannel` do novo local

### Verification

- [x] `flutter analyze` nos 2 novos arquivos
- [x] Verificar que `NotificationsPage` usa apenas imports de `lib/features/notifications/`
- [x] Verificar que `NotificationEditPage` usa apenas imports de `lib/features/notifications/`

---

## Phase 4: Imports Externos e Cleanup

Atualizar o único consumidor externo real, depois deletar todos os arquivos e
diretórios legados.

### Tasks

- [x] Task 4.1: Atualizar `lib/components/common/app_navigation_items.dart`:
  - Substituir import de `notificacoes_page.dart` pelo novo path
  - Substituir `NotificacoesPage()` por `NotificationsPage()`

- [x] Task 4.2: Deletar `lib/components/notificacoes_page/notificacoes_page.dart`
- [x] Task 4.3: Deletar `lib/components/notificacoes_page/notificacao_edicao_page.dart`
- [x] Task 4.4: Remover diretório `lib/components/notificacoes_page/`
- [x] Task 4.5: Deletar `lib/features/notificacoes/notificacoes_channel.dart`
- [x] Task 4.6: Remover diretório `lib/features/notificacoes/`

### Verification

- [x] `flutter analyze lib/` sem issues nos arquivos desta track
- [x] `grep -r "notificacoes_page\|notificacoes_channel\|NotificacoesPage\|NotificacoesChannel" lib/` retorna vazio (hits restantes são `PermissoesNotificacoesPage` — feature independente de config)
- [x] Diretórios `lib/components/notificacoes_page/` e `lib/features/notificacoes/` não existem mais

---

## Final Verification

- [x] Todos os acceptance criteria da spec atendidos
- [x] `flutter analyze` — zero issues nos arquivos da track
- [ ] NotificationsPage funcionando (listagem, agrupamento, filtro, refresh)
- [ ] NotificationEditPage funcionando (salvar, apagar, cadastrar como gasto)
- [ ] SharedAppBar azul exibido corretamente em ambas as páginas
- [ ] Nenhuma funcionalidade existente quebrada

---

_Generated by Conductor. Tasks will be marked [~] in progress and [x] complete._

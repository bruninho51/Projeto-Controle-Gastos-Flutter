# Implementation Plan: Refactor — Dashboard e MainAppScaffold

**Track ID:** dashboard-refactor_20260602
**Spec:** [spec.md](./spec.md)
**Created:** 2026-06-02
**Status:** [~] In Progress

## Overview

Refatoração em 4 fases sequenciais. Cada fase é atômica e verificável independentemente. A ordem importa: começamos pelos tipos de dados (sem risco), depois a camada de API (risco alto), depois os componentes visuais, e por último simplificamos as pages. Nunca deletar código da page original antes de ter o substituto funcionando.

## Estrutura final

```
lib/features/dashboard/
├── pages/
│   └── dashboard_page.dart          ← simplificado
├── components/
│   ├── dashboard_header.dart        ← era _DashboardHeader
│   ├── dashboard_card_grid.dart     ← era _buildDashboardCards
│   ├── dashboard_card.dart          ← era _DashboardCard
│   └── pill_segmented_control.dart  ← era _PillSegmentedControl
├── repositories/
│   └── dashboard_repository.dart   ← chamadas HTTP/GraphQL
├── services/
│   └── dashboard_service.dart      ← agregação e contagens
├── models/
│   ├── dashboard_data.dart         ← dados agregados da API
│   └── dashboard_card_config.dart  ← configuração visual de cada card
└── constants/
    └── dashboard_cards.dart        ← lista de cards (ordem, ícone, cor)

lib/components/common/
├── navigation_item.dart            ← modelo NavigationItem
├── app_navigation_items.dart       ← lista kNavigationItems
├── app_navigation_rail.dart        ← AppNavigationRail (inclui _RailItem, _RailFooterButton)
├── app_bottom_nav.dart             ← AppBottomNav (inclui _BottomNavItem)
└── main_app_scaffold.dart          ← simplificado
```

---

## Phase 1: Modelos, Constantes e Configuração

Criar os tipos de dados base que todas as outras camadas vão usar. Fase sem risco — apenas novos arquivos, sem modificar nada existente.

### Tasks

- [x] Task 1.1: Criar `models/dashboard_data.dart` — classe `DashboardData` com os campos: `qtdOrcamentosAtivos`, `qtdOrcamentosEncerrados`, `valorInicialAtivos`, `valorLivreAtivos`, `valorAtualAtivos`, `gastosFixosAtivos`, `gastosVariaveisAtivos`, `valorPoupado`
- [x] Task 1.2: Criar `models/dashboard_card_config.dart` — classe `DashboardCardConfig` com: `title`, `value` (String formatada), `color`, `icon`, `isCount`
- [x] Task 1.3: Criar `constants/dashboard_cards.dart` — função `buildCardConfigs(DashboardData data) → List<DashboardCardConfig>` com a definição dos 8 cards (mesma ordem, mesmos ícones, mesmas cores do original)

### Verification

- [x] `flutter analyze` sem erros nos 3 novos arquivos
- [x] `buildCardConfigs` produz exatamente 8 cards na mesma ordem do `_buildCardDataList` original

---

## Phase 2: Repository e Service

Mover toda a lógica de acesso a dados e agregação. Fase de maior risco — preservar comportamento exato das chamadas de API.

### Tasks

- [ ] Task 2.1: Criar `repositories/dashboard_repository.dart` — classe `DashboardRepository` com:
  - `fetchOrcamentos(String token) → Future<List<dynamic>>` (chamada REST)
  - `fetchConsolidado(String token) → Future<Map<String, dynamic>>` (chamada GraphQL — mesma query)
- [ ] Task 2.2: Criar `services/dashboard_service.dart` — classe `DashboardService` com:
  - `getDashboardData(String token) → Future<DashboardData>`
  - Faz uma única chamada a `fetchOrcamentos`, aplica os dois filtros (ativo/encerrado) sobre o mesmo resultado
  - Mapeia campos do consolidado para `DashboardData`
- [ ] Task 2.3: Verificar que a query GraphQL e os nomes de campos REST estão idênticos ao original

### Verification

- [ ] `flutter analyze` sem erros
- [ ] Substituir temporariamente `_fetchDashboardData` em `DashboardPage` pelo `DashboardService` e confirmar que os dados carregam corretamente no app
- [ ] Counts de orçamentos ativos/encerrados batem com o comportamento original
- [ ] Erro de API continua sendo propagado corretamente para o `FutureBuilder`

---

## Phase 3: Componentes

Extrair os componentes significativos de `dashboard_page.dart` para arquivos dedicados. Nesta fase o arquivo original ainda mantém as classes privadas — elas serão removidas apenas na fase 4.

### Tasks

- [ ] Task 3.1: Criar `components/pill_segmented_control.dart` — classe pública `PillSegmentedControl` (era `_PillSegmentedControl`). Mesma lógica de animação com `tabController.animation`.
- [ ] Task 3.2: Criar `components/dashboard_card.dart` — classe pública `DashboardCard` (era `_DashboardCard`). Recebe `DashboardCardConfig` em vez de `_CardData`. Mantém animação de entrada e hover.
- [ ] Task 3.3: Criar `components/dashboard_card_grid.dart` — widget público `DashboardCardGrid` (era `_buildDashboardCards`). Recebe `DashboardData`, chama `buildCardConfigs`, renderiza o grid responsivo.
- [ ] Task 3.4: Criar `components/dashboard_header.dart` — classe pública `DashboardHeader` (era `_DashboardHeader`). Recebe `AuthState` e `TabController`.

### Verification

- [ ] `flutter analyze` sem erros
- [ ] Visual do dashboard idêntico ao original (inspeção manual)
- [ ] Animação de entrada dos cards funcionando
- [ ] Hover nos cards funcionando (web)
- [ ] Pill segmented control animando suavemente com swipe e toque
- [ ] Avatar do usuário carregando corretamente

---

## Phase 4: Simplificar Pages e MainAppScaffold

Com todas as peças no lugar, simplificar `DashboardPage` e refatorar `MainAppScaffold`. Esta é a fase onde o código antigo é removido.

### Tasks

- [ ] Task 4.1: Atualizar `dashboard_page.dart` — remover todas as classes privadas e métodos de API extraídos. Importar e usar `DashboardService`, `DashboardHeader`, `DashboardCardGrid`. A page deve ter apenas: `TabController`, `FutureBuilder`, e montagem do `Scaffold`.
- [ ] Task 4.2: Criar `lib/components/common/navigation_item.dart` — mover o modelo `NavigationItem` para arquivo próprio
- [ ] Task 4.3: Criar `lib/components/common/app_navigation_items.dart` — extrair a lista `_navigationItems` para constante `kNavigationItems`
- [ ] Task 4.4: Criar `lib/components/common/app_navigation_rail.dart` — extrair `_buildNavigationRail` como widget `AppNavigationRail`. Manter `_RailItem` e `_RailFooterButton` no mesmo arquivo como classes privadas.
- [ ] Task 4.5: Criar `lib/components/common/app_bottom_nav.dart` — extrair `_buildFloatingBottomNav` como widget `AppBottomNav`. Manter `_BottomNavItem` no mesmo arquivo como classe privada.
- [ ] Task 4.6: Simplificar `main_app_scaffold.dart` — remover código extraído, importar novos arquivos. O scaffold deve ter apenas: `currentIndex`, `railExtended`, decisão `useRail`, e composição com `AppNavigationRail`/`AppBottomNav`.

### Verification

- [ ] `flutter analyze` — zero warnings/errors em todo o projeto
- [ ] Navegação mobile: BottomNav funcionando, todas as abas acessíveis
- [ ] Navegação web: NavigationRail funcionando, colapso/expansão funcionando
- [ ] Logout funcionando pelo botão "Sair" no rail
- [ ] Dashboard carrega métricas corretamente
- [ ] Todos os fluxos principais testados manualmente

---

## Final Verification

- [ ] Todos os acceptance criteria da spec.md atendidos
- [ ] `flutter analyze` — zero warnings/errors
- [ ] Teste manual: dashboard carrega 8 métricas corretamente
- [ ] Teste manual: navegação entre todas as 6 telas funciona
- [ ] Teste manual: web (NavigationRail + colapso) funcionando
- [ ] Teste manual: mobile (BottomNav flutuante) funcionando
- [ ] Nenhuma funcionalidade existente quebrada

---

_Generated by Conductor. Tasks will be marked [~] in progress and [x] complete._

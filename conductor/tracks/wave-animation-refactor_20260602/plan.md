# Implementation Plan: Refactor — Wave Animation e Decomposição do LoadingScreen

**Track ID:** wave-animation-refactor_20260602
**Spec:** [spec.md](./spec.md)
**Created:** 2026-06-02
**Status:** [x] Complete

## Overview

Refactor em 3 fases sequenciais: primeiro criar o componente compartilhado de ondas, depois migrar o Login para usá-lo, por fim decompor e mover o LoadingScreen. Cada fase é verificável de forma independente antes de avançar. Nenhuma fase altera comportamento visual — apenas reorganiza o código.

---

## Phase 1: Criar AnimatedWaveBackground

Criar o componente genérico de ondas animadas em `lib/features/shared/components/`. Esta fase não modifica nenhum arquivo existente — apenas adiciona código novo.

### Tasks

- [x] Task 1.1: Criar `lib/features/shared/components/` (diretório)
- [x] Task 1.2: Criar `lib/features/shared/components/animated_wave_background.dart` com:
  - modelo `WaveLayer` com campos `baseY`, `amplitude`, `frequency`, `color`
  - widget `AnimatedWaveBackground` recebendo `w1`, `w2`, `w3` (`Animation<double>`) e `layers` (`List<WaveLayer>`)
  - `WaveBackgroundPainter` (único `CustomPainter` de ondas do projeto) com método `_wave()` usando `sin()` e `freq` configurável
  - `shouldRepaint` comparando os 3 valores de onda

### Verification

- [x] `flutter analyze` sem erros no arquivo criado
- [x] Confirmar que nenhum arquivo existente foi modificado

---

## Phase 2: Migrar LoginBackgroundAnimation

Substituir `BackgroundWavePainter` pelo `AnimatedWaveBackground` criado na Phase 1. Após esta fase, o Login continua com aparência idêntica mas sem painter próprio.

### Tasks

- [x] Task 2.1: Atualizar `lib/features/auth/components/login_background_animation.dart`:
  - Adicionar import de `animated_wave_background.dart`
  - Substituir `AnimatedBuilder + CustomPaint(painter: BackgroundWavePainter(...))` por `AnimatedWaveBackground(w1: w1, w2: w2, w3: w3, layers: _loginLayers)`
  - Definir `_loginLayers` com os 3 `WaveLayer` preservando exatamente: `baseY` (0.18, 0.38, 0.72), `amplitude` (28, 22, 18), `frequency` (1.8, 2.2, 1.5), cores e opacidades originais
  - Remover a classe `BackgroundWavePainter` do arquivo

### Verification

- [x] `flutter analyze` sem erros
- [x] Verificar visualmente a tela de login: ondas com mesmo movimento, posições e opacidades

---

## Phase 3: Decompor e Mover LoadingScreen

Extrair os 3 componentes visuais do LoadingScreen, mover a tela para `features/loading/` e atualizar o import em `auth_wrapper.dart`. O arquivo `shared/components/loading_screen.dart` é excluído ao final.

### Tasks

- [x] Task 3.1: Criar estrutura de diretórios:
  - `lib/features/loading/pages/`
  - `lib/features/loading/components/`

- [x] Task 3.2: Criar `lib/features/loading/components/animated_coin.dart`:
  - Extrair `_CoinWidget` como `AnimatedCoin` (widget público)
  - Parâmetro: `progress` (`double`)
  - Preservar exatamente: tamanho (64px), cores, bordas, texto 'R\$', transformação `rotateY`

- [x] Task 3.3: Criar `lib/features/loading/components/animated_phrase.dart`:
  - Extrair `_PhraseWidget` como `AnimatedPhrase` (widget público)
  - Parâmetros: `phrase` (`String`), `progress` (`double`)
  - Preservar: lógica de `_opacity` e `_offsetY`, altura (28px), estilo do texto

- [x] Task 3.4: Criar `lib/features/loading/components/animated_bar_chart.dart`:
  - Extrair `_BarChart` como `AnimatedBarChart` (widget público com `StatefulWidget`)
  - Preservar: `_heights`, `_opacities`, controller interno (1000ms, reverse), lógica de `delay` por índice

- [x] Task 3.5: Criar `lib/features/loading/pages/loading_screen.dart`:
  - Mover `LoadingScreen` para o novo arquivo
  - Substituir `_WavePainter` por `AnimatedWaveBackground` com `_loadingLayers`
  - Definir `_loadingLayers` com os 3 `WaveLayer` preservando: `baseY` (0.35, 0.50, 0.62), `amplitude` (20, 16, 12), `frequency: 2.0` (equivalente ao `2 * pi` fixo atual), cores e opacidades originais
  - Substituir `_CoinWidget` por `AnimatedCoin`
  - Substituir `_PhraseWidget` por `AnimatedPhrase`
  - Substituir `_BarChart` por `AnimatedBarChart`
  - Manter: todos os `AnimationController`, `Timer`, `dispose`, `_phrases`, `_phraseIndex`
  - Manter: posicionamento das ondas em `Positioned(bottom: 0)` + `SizedBox(height: 180)`

- [x] Task 3.6: Atualizar import em `lib/features/auth/auth_wrapper.dart`:
  - Substituir import de `shared/components/loading_screen.dart` por `features/loading/pages/loading_screen.dart`

- [x] Task 3.7: Deletar `lib/shared/components/loading_screen.dart`

### Verification

- [x] `flutter analyze` sem warnings ou erros
- [x] Verificar visualmente a tela de loading: ondas no rodapé, moeda girando, frases alternando com fade, barras animando
- [x] Confirmar que `_WavePainter` e `BackgroundWavePainter` não existem mais em nenhum arquivo do projeto
- [x] Confirmar que `grep -r "class.*WavePainter" lib/` retorna apenas `WaveBackgroundPainter`

---

## Final Verification

- [x] Todos os acceptance criteria da spec marcados como concluídos
- [x] `flutter analyze` sem warnings ou erros
- [x] Apenas uma implementação do algoritmo de ondas no projeto
- [x] Login visualmente idêntico ao original
- [x] Loading visualmente idêntico ao original
- [x] AuthWrapper compila e exibe LoadingScreen corretamente
- [x] Nenhum arquivo `.dart` órfão ou import quebrado

---

_Generated by Conductor. Tasks will be marked [~] in progress and [x] complete._

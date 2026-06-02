# Specification: Refactor — Wave Animation e Decomposição do LoadingScreen

**Track ID:** wave-animation-refactor_20260602
**Type:** Refactor
**Created:** 2026-06-02
**Status:** Complete

## Summary

Extrair um componente genérico `AnimatedWaveBackground` a partir do painter de ondas duplicado entre `LoginBackgroundAnimation` e `LoadingScreen`, e decompor `LoadingScreen` em componentes visuais independentes movendo-o para `lib/features/loading/`.

## Context

O app possui duas telas com animação de fundo em ondas (Login e Loading) que compartilham o mesmo algoritmo de `CustomPainter` — `sin()`, 3 waves, paleta azul escuro — porém com parâmetros diferentes (baseY, amplitude, frequência, cores e posicionamento).

Atualmente existem duas implementações do mesmo algoritmo:

- `BackgroundWavePainter` em Login
- `_WavePainter` em Loading

Além disso, `LoadingScreen` está concentrando responsabilidades distintas:

- ciclo de vida
- controllers de animação
- timer de frases
- painter de ondas
- moeda animada
- frase animada
- gráfico de barras

A intenção é eliminar duplicação real de código, melhorar organização por feature e manter exatamente o mesmo comportamento visual.

---

## Estrutura desejada

```text
lib/
└── features/
    ├── loading/
    │   ├── pages/
    │   │   └── loading_screen.dart
    │   │
    │   └── components/
    │       ├── animated_coin.dart
    │       ├── animated_phrase.dart
    │       └── animated_bar_chart.dart
    │
    ├── auth/
    │   └── components/
    │       └── login_background_animation.dart
    │
    └── shared/
        └── components/
            └── animated_wave_background.dart
```

---

## Acceptance Criteria

- [x] `AnimatedWaveBackground` criado em `lib/features/shared/components/animated_wave_background.dart`
- [x] Modelo `WaveLayer` criado para configuração das ondas
- [x] `LoginBackgroundAnimation` refatorado para utilizar `AnimatedWaveBackground`
- [x] `_WavePainter` removido do LoadingScreen
- [x] `BackgroundWavePainter` removido do Login
- [x] Existe apenas uma implementação do algoritmo de ondas em todo o projeto
- [x] `LoadingScreen` movido para `lib/features/loading/pages/loading_screen.dart`
- [x] `AnimatedCoin` extraído para `lib/features/loading/components/animated_coin.dart`
- [x] `AnimatedPhrase` extraído para `lib/features/loading/components/animated_phrase.dart`
- [x] `AnimatedBarChart` extraído para `lib/features/loading/components/animated_bar_chart.dart`
- [x] Comportamento visual idêntico ao original
- [x] Tempos das animações preservados
- [x] Controllers continuam sendo gerenciados pela tela consumidora
- [x] Nenhum controller é criado dentro de `AnimatedWaveBackground`
- [x] Posicionamento das ondas continua sendo responsabilidade da tela consumidora
- [x] Login continua ocupando tela inteira
- [x] Loading continua renderizando ondas apenas no rodapé

---

## Dependencies

Arquivos impactados:

```text
lib/features/auth/components/login_background_animation.dart
lib/shared/components/loading_screen.dart
lib/features/auth/auth_wrapper.dart
```

Arquivos criados:

```text
lib/features/loading/pages/loading_screen.dart

lib/features/loading/components/
├── animated_coin.dart
├── animated_phrase.dart
└── animated_bar_chart.dart

lib/features/shared/components/
└── animated_wave_background.dart
```

---

## Out of Scope

Não faz parte desta refatoração:

- Alterar cores
- Alterar tamanhos
- Alterar amplitudes
- Alterar frequências
- Alterar duração das animações
- Alterar layout das telas
- Alterar lógica dos timers
- Alterar lógica dos AnimationControllers
- Criar testes widget
- Refatorar outras telas
- Criar abstrações adicionais para moeda, frase ou gráfico além dos componentes previstos

---

## Technical Notes

### WaveLayer

Criar um modelo configurável:

```dart
class WaveLayer {
  final double baseY;
  final double amplitude;
  final double frequency;
  final Color color;
}
```

A frequência deve ser configurável porque:

#### Login

Hoje utiliza:

```dart
freq = 1.8
freq = 2.2
freq = 1.5
```

#### Loading

Hoje utiliza:

```dart
2 * pi
```

fixo.

Para manter compatibilidade, `frequency: 2.0` deve reproduzir exatamente o comportamento atual do Loading.

---

### AnimatedWaveBackground

Responsabilidades:

- receber valores das animações (`w1`, `w2`, `w3`)
- receber configuração das camadas (`WaveLayer`)
- renderizar o `CustomPaint`
- concentrar a única implementação do algoritmo de ondas

Não deve:

- criar AnimationControllers
- criar Timers
- controlar ciclo de vida
- decidir posicionamento na tela
- conhecer Login ou Loading

---

### Posicionamento

O posicionamento permanece responsabilidade da tela consumidora.

#### Login

Continua:

```dart
Positioned.fill(...)
```

ocupando toda a tela.

#### Loading

Continua:

```dart
SizedBox(height: 180)
```

renderizando apenas no rodapé.

---

### LoadingScreen

Após a refatoração:

#### Mantém responsabilidades

- criação dos AnimationControllers
- gerenciamento do Timer
- dispose dos recursos
- troca de frases
- composição da tela

#### Perde responsabilidades

- painter das ondas
- moeda animada
- frase animada
- gráfico animado

---

### Componentização

Extrair apenas componentes com responsabilidade visual clara:

```text
AnimatedCoin
AnimatedPhrase
AnimatedBarChart
```

Não criar componentes adicionais para:

```text
Text
Container
Label
Ícones
Partes internas da moeda
Partes internas do gráfico
```

Evitar componentização excessiva.

---

## Verification Checklist

### Login

- [x] Ondas renderizadas corretamente
- [x] Movimento idêntico ao original
- [x] Opacidade preservada
- [x] Frequências preservadas
- [x] Layout preservado

### Loading

- [x] Ondas renderizadas apenas no rodapé
- [x] Moeda continua girando
- [x] Frases continuam alternando
- [x] Fade e deslocamento das frases continuam funcionando
- [x] Barras continuam animando
- [x] Layout preservado

### Projeto

- [x] `flutter analyze` sem warnings ou erros
- [x] Apenas uma implementação do algoritmo de ondas existe no projeto
- [x] Nenhuma funcionalidade existente foi quebrada
- [x] Imports atualizados corretamente
- [x] AuthWrapper continua compilando e exibindo LoadingScreen corretamente

---

## Success Criteria

A refatoração será considerada concluída quando:

- houver apenas uma implementação do algoritmo de ondas;
- Login e Loading mantiverem aparência idêntica;
- Loading estiver organizado por feature;
- componentes compartilhados estiverem em `lib/features/shared/components`;
- componentes específicos do Loading estiverem em `lib/features/loading/components`;
- o código estiver mais simples de manter sem introduzir abstrações desnecessárias.

---

_Generated by Conductor. Review and edit as needed._

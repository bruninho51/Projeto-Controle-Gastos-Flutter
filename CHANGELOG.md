# [1.23.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.22.0...v1.23.0) (2026-07-18)


### Features

* adiciona configuração para habilitar ou desabilitar a biometria ([eedca05](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/eedca05c20b1813ea61a3f707d28b28f6546a5da))
* caso a notificação não tenha título, usa a primeira palavra da notificação como título ([eaedeac](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/eaedeac86a88a8364d81b4bf78e2726750994bd8))
* implementa autenticação biométrica ([004c453](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/004c45317df3e2ed9156ac912192de03c6bd9133))
* inicia a processamento das notificações no dart apenas após o login ([f552dc6](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/f552dc6605a151df2e5ae13e88bfe3b550c22a42))
* loga automaticamente quando a conta do google está salva no dispositivo ([116c94d](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/116c94d938bc88e26225af1d55bc34dc596b7059))
* unifica listas de orçamentos ativos e orçamentos encerrados nos mesmos componentes e adiciona filtros ([82b5fe5](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/82b5fe5eda22fcb942a9724a2b438cbae3dc27f3))

# [1.22.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.21.0...v1.22.0) (2026-07-07)


### Bug Fixes

* altera nomenclaturas ([2d80470](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/2d80470b91b2c3d4f71657b283c48dd8bfc95cb4))
* corrige depreciações e move arquivos ([081b5e3](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/081b5e34b49113367e192b363afa02696a9cb815))
* corrige use_build_context_synchronously no projeto ([ef936d9](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/ef936d980a9de47b73258b2721a5178b521eeef8))


### Features

* adiciona menu metric card e metric card ([3f1de9e](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/3f1de9e51fb42c84523dba8ba1d8b096a14ba414))
* melhora o design e a usabilidade das telas de investimentos ([c1eca92](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/c1eca920ca3866974f3ca3156144a92c450bfe0c))
* refatora orcamentos detalhes page ([a7fcb66](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/a7fcb66c5bc53a505ff2d7e74a1d8c88e0aeff2e))

# [1.21.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.20.1...v1.21.0) (2026-07-07)


### Features

* quando o app falhar ao identificar um padrão, um botão ficará disponível para tentar novamente ([425b2e3](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/425b2e39a93ad677c9db11973cd7600c45a0396b))

## [1.20.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.20.0...v1.20.1) (2026-07-06)


### Bug Fixes

* corrige bug em que o app deixa de receber notificações de outros apps, mesmo estando habilitado ([930a1c9](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/930a1c9ac8685be8ea03c9c02dd31e39250a19e8))
* corrige bug na identificação de notificações de mesmo estabelecimento ([3bb5a41](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/3bb5a41338467d2cb48d7d88a51049204b569ed8))

# [1.20.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.19.0...v1.20.0) (2026-07-05)


### Features

* adiciona suporte a Alelo e tela para visualização e sincronização de regex ([4c4a9b3](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/4c4a9b3ad4af57ee15fb0714d9cf7cf8ff238059))

# [1.19.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.18.2...v1.19.0) (2026-07-03)


### Features

* usa gemini para obter dados do gasto através de notificações ([97e9f10](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/97e9f10304db41d9001e29f687fb0f54c2513645))

## [1.18.2](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.18.1...v1.18.2) (2026-06-29)


### Bug Fixes

* corrige alteração da data de vencimento nas cópias de gastos fixos com vencimento ([31fd32f](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/31fd32f5fce657e3d906dfa6950347e7dd4fc5bd))

## [1.18.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.18.0...v1.18.1) (2026-06-29)


### Bug Fixes

* corrige bug ao atualizar dados via api ([f68bc95](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/f68bc95e4b5b1cb828ef3d6e8b1ba58285b6a79c))

# [1.18.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.17.1...v1.18.0) (2026-06-24)


### Features

* refatora app, adiciona total gasto e filtro de categoria ([fff8829](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/fff8829c413ffbffcfd824a3b8169671346d3a70))

## [1.17.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.17.0...v1.17.1) (2026-06-03)


### Bug Fixes

* **investimentos:** corrige overflow da SharedAppBar e deprecation withOpacity ([5fd649e](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/5fd649e174c4d41d904e933e1c55cac1087135bd))

# [1.17.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.16.0...v1.17.0) (2026-06-02)


### Features

* corrige layout da login page na web ([4493caa](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/4493caa4820988cc60a75de9a63ab5b481b0a1b6))
* lê notificações do Ifood Beneficios ([8a1cfb6](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/8a1cfb664ad8b523dbf77ed268f63946fc9458e4))

# [1.16.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.15.0...v1.16.0) (2026-05-28)


### Features

* adiciona conductor ([c89a07a](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/c89a07a05a409caa352be4b2997021d762d4a4a9))

# [1.15.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.14.3...v1.15.0) (2026-05-26)


### Features

* adiciona suporte a captura de notificações bancárias ([2ae0517](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/2ae0517b9c84933689b172b1f191fde777e2f397))

## [1.14.3](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.14.2...v1.14.3) (2026-05-03)


### Bug Fixes

* corrige nome ao instalar o aplicativo como PWA ([6c445fb](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/6c445fbcffabefea8af3f4bfd087a054c489e2b0))

## [1.14.2](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.14.1...v1.14.2) (2026-05-03)


### Bug Fixes

* corrige bug nas configurações na web ([a0f2baa](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/a0f2baaec6724df768db77f21eab219e6a2e3003))

## [1.14.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.14.0...v1.14.1) (2026-05-03)


### Bug Fixes

* corrige bug nas configurações na web ([051da1d](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/051da1dd590b93f4b15f9fe3b4789dc02e98ff19))

# [1.14.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.13.0...v1.14.0) (2026-05-03)


### Features

* corrige notificações na web ([22beef5](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/22beef5c7b65ec1b74790c6fe45e99530d13f153))

# [1.13.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.12.0...v1.13.0) (2026-05-03)


### Features

* cria foreground service para android ([f830843](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/f8308431b779aa4460ead23d729a036af5c22158))
* cria foreground service para android ([b0fad82](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/b0fad8277578968821eba817af17d46433bc669f))
* cria foreground service para android ([dce75cd](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/dce75cdca5a0e11e5c44c22c734305fff088482a))

# [1.12.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.11.0...v1.12.0) (2026-04-25)


### Features

* melhorias visuais e limpeza de código ([53730c4](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/53730c46635e55ec6b4a27f158f244c44661ace3))

# [1.11.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.10.0...v1.11.0) (2026-04-23)


### Features

* melhora a configuração do registro de dispositivo ([d686555](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/d686555132a2a5b2897c33429ebf07fdb20cbec6))
* refatora estados ([f1dd90f](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/f1dd90fd60993968ac49c026b439efb1c118e7c8))

# [1.10.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.9.0...v1.10.0) (2026-04-16)


### Features

* adiciona suporte para notificações push via firebase messaging ([39da53e](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/39da53eea13cd778d01ac6c2e2c59f0867200381))

# [1.9.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.8.1...v1.9.0) (2026-03-27)


### Features

* adiciona funcionalidade de cópia de gastos fixos de um orçamento para o outro ([c99f7c6](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/c99f7c6ce8d509c0536d1d7862d05c7b38fc2e90))

## [1.8.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.8.0...v1.8.1) (2026-03-25)


### Bug Fixes

* corrige a versão no app android ([989a79f](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/989a79fa8bd2cc2a08f1d1f9d038fe9afef20cb5))

# [1.8.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.7.0...v1.8.0) (2026-03-25)


### Features

* assina apk ([ce0aeee](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/ce0aeeed93c77d8ed718f3901a3d39fb38ab16b0))

# [1.7.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.6.0...v1.7.0) (2026-03-25)


### Bug Fixes

* ajusta pipe do android ([af56afc](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/af56afc77a20a045dd6aa8ddf0a462b5987e7beb))
* altera os builds ([e46ef04](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/e46ef04fa62e1479313e8ba9f35f5136e40c1138))


### Features

* ajusta pipe android ([90d751d](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/90d751d8977bbdb0cc80e6347fcf6631eec3575c))

## [1.6.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.6.0...v1.6.1) (2026-03-25)


### Bug Fixes

* ajusta pipe do android ([af56afc](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/af56afc77a20a045dd6aa8ddf0a462b5987e7beb))
* altera os builds ([e46ef04](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/e46ef04fa62e1479313e8ba9f35f5136e40c1138))

# [1.6.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.5.0...v1.6.0) (2026-03-24)


### Features

* agrupa gastos fixos pagos por data ([b2e7885](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/b2e788547a162cd5108c24306145893e6a56cdd0))

# [1.5.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.4.0...v1.5.0) (2026-03-23)


### Features

* implementa nova identidade visual ([8241fbf](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/8241fbf2ae76e17891b21cc82cb9fc6e26bc427c))
* implementa nova identidade visual ([100c763](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/100c763fbd2e61c459fc467c3aa706343e470ac0))

# [1.4.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.3.0...v1.4.0) (2026-02-19)


### Features

* atualiza flutter para a versão 3.41.1 ([b13e06c](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/b13e06c2e374ec9774cd971bdf27b15a0d2337a1))
* implementa comunicação com o analytics ([9122c75](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/9122c75482be51345c1119c9e7fb339c934aa31b))

# [1.3.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.2.0...v1.3.0) (2025-10-07)


### Features

* adiciona data de vencimento nos gastos fixos ([41d5bae](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/41d5bae77a2d75af3c372272d8a786c63a87d144))

# [1.2.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.1.0...v1.2.0) (2025-08-21)


### Features

* implementa alterações de responsividade e visuais ([6282d5f](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/6282d5f48ebde2cad8c52a6f97931b7ca69403b2))

# [1.1.0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.0.1...v1.1.0) (2025-08-18)


### Features

* refatora cards de orçamento para listagem na web ([9139f39](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/9139f390f5dd1e8aeb7e0e91b0cbab2266f3b72b))

## [1.0.1](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/compare/v1.0.0...v1.0.1) (2025-07-29)


### Bug Fixes

* altera porta do deployment ([a58716b](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/a58716b08695e7ecde42e23f439648df3259042f))

# 1.0.0 (2025-07-29)


### Features

* adiciona a tela de detalhes de gasto variado ([8b68b33](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/8b68b33b758240a79b037c3cfe4bd4a211c171a2))
* adiciona filtros e formatações ([320239c](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/320239c7351d770a12c70c3601a5dd14fd80be70))
* adiciona flutter web ([a9eadc2](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/a9eadc224f623627911a024bf90d5cfe849a92f3))
* adiciona formulário para cadastro de investimentos ([803927b](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/803927bc4bb1f9013d69474a39613a040acc1125))
* adiciona listagem de investimentos ([d7123d8](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/d7123d8385cddaeb1097e296280f9bbaaa957cea))
* adiciona logo ([dc69031](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/dc690312d3722bedadd510299d2ed36997fef106))
* adiciona modal para inserir entradas na linha do tempo ([fb6dcaf](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/fb6dcaf011b0a8e7526e601be49470046c384f27))
* adiciona o formulario de cadastro de gastos variaveis ([7993815](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/799381518e30c919f0fac4e136ab14353c5be635))
* adiciona tela de detalhes do investimento ([d68c189](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/d68c1898050eb3165f17dfb52e57e0ac7c9de28e))
* deixa a versão web mais responsiva ([399b8da](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/399b8da029aac6b8f8f57cccfea948714b38543f))
* refatora componentes ([9ec19f0](https://gitlab.com/bruninho51/projeto-controle-gastos-flutter/commit/9ec19f0c4ca5afb04ce669de4f654f331af06b61))

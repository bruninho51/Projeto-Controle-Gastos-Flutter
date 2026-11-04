import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamento_detalhes_web_content.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamento_detalhes_web_header.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamento_detalhes_web_utilizacao.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  for (final largura in [1600.0, 800.0]) {
    testWidgets('detalhes web renderiza sem exceções ($largura px)',
        (tester) async {
      tester.view.physicalSize = Size(largura, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final ctrl = AnimationController(
          vsync: const TestVSync(), duration: const Duration(seconds: 1));
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OrcamentoDetalhesWebHeader(
                nome: 'IFOOD - Novembro (2026)',
                encerrado: false,
                criadoEm: DateTime(2026, 10, 30),
                refreshCtrl: ctrl,
                menuKey: GlobalKey(),
                onBack: () {},
                onRefresh: () {},
                onEditar: () {},
                onEncerrarOuReativar: () {},
                onMenu: () {},
                onNovoGasto: (_) {},
              ),
              Expanded(
                child: OrcamentoDetalhesWebContent(
                  cards: const SizedBox(height: 150),
                  grafico: const SizedBox(height: 420),
                  valorInicial: 1270.13,
                  valorAtual: 850.13,
                  vencidos: 0,
                  criadoEm: DateTime(2026, 10, 30),
                ),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Utilização'), findsOneWidget);
    });
  }

  testWidgets('utilização cabe em tela de celular', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: OrcamentoDetalhesWebUtilizacao(
            valorInicial: 1270.13,
            valorAtual: 850.13,
            vencidos: 1,
            criadoEm: DateTime(2026, 10, 30),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

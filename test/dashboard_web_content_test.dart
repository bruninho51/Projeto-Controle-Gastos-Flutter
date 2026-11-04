import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orcamentos_app/features/dashboard/components/dashboard_card_grid.dart';
import 'package:orcamentos_app/features/dashboard/components/web/dashboard_web_content.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_orcamento.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets('dashboard web renderiza sem exceções', (tester) async {
    tester.view.physicalSize = const Size(1600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final data = _dados();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardWebContent(data: data, onVerOrcamentos: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Situação dos orçamentos'), findsOneWidget);
  });

  testWidgets('dashboard mobile exibe os gráficos sem exceções',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DashboardCardGrid(data: _dados(), onVerOrcamentos: () {}),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Situação dos orçamentos'), 400,
        scrollable: find.byType(Scrollable).first);
    expect(tester.takeException(), isNull);
    expect(find.text('Situação dos orçamentos'), findsOneWidget);
  });
}

DashboardData _dados() {
  return DashboardData(
    qtdOrcamentosAtivos: 2,
    qtdOrcamentosEncerrados: 44,
    valorInicialAtivos: '8400.61',
    valorLivreAtivos: 2448.97,
    valorAtualAtivos: '5564.48',
    gastosFixosAtivos: 3574.63,
    gastosVariaveisAtivos: '861.49',
    valorPoupado: 100,
    orcamentosAtivos: [
      DashboardOrcamento(
          nome: 'INTER',
          dataCriacao: DateTime(2026, 11, 1),
          orcado: 7130.48,
          saldo: 4714.35),
      DashboardOrcamento(
          nome: 'IFOOD',
          dataCriacao: DateTime(2026, 11, 1),
          orcado: 1270.13,
          saldo: 850.13),
    ],
  );
}

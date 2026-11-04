import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/web/gasto_variado_web_content.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/shared/api_models.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  for (final largura in [1600.0, 800.0]) {
    for (final ativo in [true, false]) {
      testWidgets('gasto variado web ($largura px, ativo: $ativo)',
          (tester) async {
        tester.view.physicalSize = Size(largura, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final ctrl = AnimationController(
            vsync: const TestVSync(), duration: const Duration(seconds: 1));
        addTearDown(ctrl.dispose);

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: GastoVariadoWebContent(
              onBack: () {},
              breadcrumb: const [
                WebCrumb('Orçamentos'),
                WebCrumb('Gastos variados'),
                WebCrumb('MR JONES'),
              ],
              descricao: 'Mr Jones',
              valor: '214.39',
              dataPgto: DateTime(2026, 11, 2),
              categoriaNome: 'Alimentação e Bebidas Fora de Casa e Delivery',
              tipo: TipoCategoriaGasto.despesa,
              observacoes: null,
              isPatrimonio: false,
              isAtivo: ativo,
              refreshCtrl: ctrl,
              onRefresh: () {},
              onDelete: ativo ? () {} : null,
              onEditNome: () {},
              onEditValor: () {},
              onEditData: () {},
              onEditCategoria: () {},
              onEditObservacoes: () {},
            ),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Observações'), findsOneWidget);
      });
    }
  }
}

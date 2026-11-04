import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:orcamentos_app/components/gasto_fixo_detalhes_page/web/gasto_fixo_web_content.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/shared/api_models.dart';

GastoFixoResponseDto _gasto({String? valor}) => GastoFixoResponseDto(
      id: 1,
      descricao: 'Aluguel',
      previsto: '1500.00',
      valor: valor,
      categoriaId: 1,
      orcamentoId: 1,
      diferenca: valor == null ? null : '-20.00',
      dataPgto: valor == null ? null : DateTime(2026, 11, 2),
      dataVenc: DateTime(2026, 11, 5),
      dataCriacao: DateTime(2026),
      categoriaGasto: CategoriaGastoResponseDto(
        id: 1,
        nome: 'Moradia e Utilidades',
        dataCriacao: DateTime(2026),
        dataAtualizacao: DateTime(2026),
      ),
    );

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  for (final largura in [1600.0, 800.0]) {
    for (final pago in [true, false]) {
      for (final ativo in [true, false]) {
        testWidgets('gasto fixo web ($largura px, pago: $pago, ativo: $ativo)',
            (tester) async {
          tester.view.physicalSize = Size(largura, 1300);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          final ctrl = AnimationController(
              vsync: const TestVSync(), duration: const Duration(seconds: 1));
          addTearDown(ctrl.dispose);
          void nada() {}

          await tester.pumpWidget(MaterialApp(
            home: Scaffold(
              body: GastoFixoWebContent(
                breadcrumb: const [
                  WebCrumb('Orçamentos'),
                  WebCrumb('IFOOD - Novembro (2026)'),
                  WebCrumb('Gastos Fixos'),
                  WebCrumb('ALUGUEL'),
                ],
                onBack: nada,
                gasto: _gasto(valor: pago ? '1520.00' : null),
                isPago: pago,
                isVencido: false,
                isPatrimonio: false,
                isAtivo: ativo,
                refreshCtrl: ctrl,
                onRefresh: nada,
                onRegistrar: !pago && ativo ? nada : null,
                onDelete: ativo ? nada : null,
                onEditNome: nada,
                onEditPrevisto: nada,
                onEditPago: nada,
                onEditDataPgto: nada,
                onEditVencimento: nada,
                onEditCategoria: nada,
                onEditObservacoes: nada,
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
}

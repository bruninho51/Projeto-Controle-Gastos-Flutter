import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcamentos_app/features/shared/components/web/web_botoes.dart';
import 'package:orcamentos_app/features/shared/components/web/web_page_toolbar.dart';

void main() {
  for (final largura in [1600.0, 1300.0, 1100.0, 900.0, 760.0]) {
    testWidgets('botões da barra superior têm a mesma altura ($largura px)',
        (tester) async {
      tester.view.physicalSize = Size(largura, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: WebPageToolbar(
            titulo: 'Gastos Fixos',
            subtitulo: 'Planejamento de despesas',
            busca: '',
            temFiltroAtivo: false,
            podeCriar: true,
            onBuscar: (_) {},
            onFiltros: () {},
            onRefresh: () {},
            onNovoGasto: () {},
            onBack: () {},
            acoes: [
              WebOutlinedButton(
                icon: Icons.copy_all_rounded,
                label: 'Copiar do Orçamento',
                onTap: () {},
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final alturas = <double>{
        for (final tipo in [WebIconButton, WebPrimaryButton])
          for (final e in find.byType(tipo).evaluate())
            tester.getSize(find.byWidget(e.widget)).height,
        for (final e in find.byType(WebOutlinedButton).evaluate())
          tester.getSize(find.byWidget(e.widget)).height,
      };
      expect(alturas, {kWebAlturaBotao});

      // O último botão (Novo gasto) deve encostar na margem direita (28px).
      final direita = tester.getTopRight(find.byType(WebPrimaryButton)).dx;
      expect(direita, closeTo(largura - 28, 0.5));
    });
  }
}

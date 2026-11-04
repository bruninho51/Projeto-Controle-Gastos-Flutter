import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcamentos_app/features/categories/components/web/categories_web_content.dart';
import 'package:orcamentos_app/shared/api_models.dart';

CategoriaGastoResponseDto _cat(int id, String nome, TipoCategoriaGasto tipo) =>
    CategoriaGastoResponseDto(
      id: id,
      nome: nome,
      tipo: tipo,
      dataCriacao: DateTime(2026),
      dataAtualizacao: DateTime(2026),
    );

void main() {
  for (final largura in [1600.0, 900.0, 760.0]) {
    testWidgets('categorias web renderiza sem exceções ($largura px)',
        (tester) async {
      tester.view.physicalSize = Size(largura, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final todas = [
        for (var i = 0; i < 17; i++)
          _cat(i, 'Alimentação e Bebidas Fora de Casa e Delivery $i',
              i == 3 ? TipoCategoriaGasto.patrimonio : TipoCategoriaGasto.despesa),
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CategoriesWebContent(
            todas: todas,
            filtradas: todas,
            tipo: null,
            limite: 11,
            cores: const [Colors.indigo, Colors.teal],
            onTipo: (_) {},
            onCarregarMais: () {},
            onNova: () {},
            onEditar: (_) {},
            onExcluir: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Carregar mais'), findsOneWidget);
    });
  }
}

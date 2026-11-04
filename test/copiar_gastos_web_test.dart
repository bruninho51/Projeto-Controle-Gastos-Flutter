import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/copiar_web_content.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/copiar_web_gastos.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/shared/api_models.dart';

OrcamentoResponseDto _orc(int id, String nome, {bool encerrado = true}) =>
    OrcamentoResponseDto(
      id: id,
      nome: nome,
      valorInicial: '100.00',
      valorAtual: '74.13',
      valorLivre: '74.13',
      dataEncerramento: encerrado ? DateTime(2026, 10, 31) : null,
      dataCriacao: DateTime(2026, 10, 1),
    );

GastoFixoResponseDto _gasto(int id) => GastoFixoResponseDto(
      id: id,
      descricao: 'Conta $id',
      previsto: '260.00',
      categoriaId: 1,
      orcamentoId: 1,
      dataCriacao: DateTime(2026),
      categoriaGasto: CategoriaGastoResponseDto(
        id: 1,
        nome: 'Moradia e Utilidades',
        dataCriacao: DateTime(2026),
        dataAtualizacao: DateTime(2026),
      ),
    );

void main() {
  for (final largura in [1600.0, 800.0]) {
    testWidgets('copiar gastos web: painel de origem ($largura px)',
        (tester) async {
      tester.view.physicalSize = Size(largura, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: CopiarWebContent(
            breadcrumb: const [
              WebCrumb('Orçamentos'),
              WebCrumb('IFOOD - Novembro (2026)'),
              WebCrumb('Copiar gastos fixos'),
            ],
            destinoNome: 'IFOOD - Novembro (2026)',
            destinoId: 9,
            orcamentos: [
              for (var i = 0; i < 10; i++)
                _orc(i, 'INTER - Mês $i (2026)', encerrado: i != 0),
            ],
            onBack: () {},
            onConcluido: (_) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Orçamento de origem'), findsOneWidget);
      expect(find.text('Escolha um orçamento de origem ao lado'),
          findsOneWidget);
    });
  }

  testWidgets('copiar gastos web: seleção e total', (tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final selecionados = <int>{1, 2};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => CopiarWebGastos(
            origem: _orc(1, 'INTER - Outubro (2026)'),
            carregando: false,
            processando: false,
            erro: null,
            gastos: [for (var i = 1; i <= 5; i++) _gasto(i)],
            selecionados: selecionados,
            onAlternar: (g) => setState(() {
              if (!selecionados.remove(g.id)) selecionados.add(g.id);
            }),
            onAlternarTodos: () {},
            onCancelar: () {},
            onCopiar: () {},
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Copiar 2 gastos'), findsOneWidget);
    expect(find.textContaining('520,00', findRichText: true), findsWidgets);

    await tester.tap(find.text('CONTA 3'));
    await tester.pumpAndSettle();
    expect(find.text('Copiar 3 gastos'), findsOneWidget);
  });
}

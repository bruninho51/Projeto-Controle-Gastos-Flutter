import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orcamentos_app/features/categories/components/categories_empty_state.dart';
import 'package:orcamentos_app/features/categories/components/category_form_dialog.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_badge.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/patch_field.dart';

CategoriaGastoResponseDto _categoria({
  String nome = 'Poupança',
  TipoCategoriaGasto tipo = TipoCategoriaGasto.patrimonio,
}) =>
    CategoriaGastoResponseDto(
      id: 1,
      nome: nome,
      tipo: tipo,
      dataCriacao: DateTime(2026, 1, 1),
      dataAtualizacao: DateTime(2026, 1, 1),
    );

void main() {
  group('TipoCategoriaGasto — serialização', () {
    test('resposta lê o tipo enviado pela API', () {
      final dto = CategoriaGastoResponseDto.fromJson({
        'id': 1,
        'nome': 'CDB',
        'tipo': 'PATRIMONIO',
        'data_criacao': '2026-01-01T00:00:00.000Z',
        'data_atualizacao': '2026-01-01T00:00:00.000Z',
      });

      expect(dto.tipo, TipoCategoriaGasto.patrimonio);
    });

    test('resposta sem tipo (API antiga) assume DESPESA', () {
      final dto = CategoriaGastoResponseDto.fromJson({
        'id': 1,
        'nome': 'Mercado',
        'data_criacao': '2026-01-01T00:00:00.000Z',
        'data_atualizacao': '2026-01-01T00:00:00.000Z',
      });

      expect(dto.tipo, TipoCategoriaGasto.despesa);
    });

    test('criação envia o tipo no formato da API', () {
      final json = CategoriaGastoCreateDto(
        nome: 'Reserva',
        tipo: TipoCategoriaGasto.patrimonio,
      ).toJson();

      expect(json, {'nome': 'Reserva', 'tipo': 'PATRIMONIO'});
    });

    test('criação usa DESPESA por padrão', () {
      expect(
          CategoriaGastoCreateDto(nome: 'Mercado').toJson()['tipo'], 'DESPESA');
    });

    test('edição só envia o tipo quando ele está presente', () {
      expect(
          CategoriaGastoUpdateDto(nome: const PatchField.value('X')).toJson(),
          {'nome': 'X'});

      expect(
        CategoriaGastoUpdateDto(
          tipo: const PatchField.value(TipoCategoriaGasto.patrimonio),
        ).toJson(),
        {'tipo': 'PATRIMONIO'},
      );
    });
  });

  group('showCategoryFormDialog', () {
    Future<void> abrir(
      WidgetTester tester, {
      CategoriaGastoResponseDto? categoria,
      required Future<void> Function(String, TipoCategoriaGasto) onConfirm,
    }) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showCategoryFormDialog(
                context: context,
                categoria: categoria,
                onConfirm: onConfirm,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('criação começa em Despesa e permite escolher Patrimônio',
        (tester) async {
      String? nome;
      TipoCategoriaGasto? tipo;
      await abrir(tester, onConfirm: (n, t) async {
        nome = n;
        tipo = t;
      });

      expect(find.text('Nova Categoria'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'Investimentos');
      await tester.tap(find.text('Patrimônio'));
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(nome, 'Investimentos');
      expect(tipo, TipoCategoriaGasto.patrimonio);
    });

    testWidgets('criação sem alterar o tipo envia Despesa', (tester) async {
      TipoCategoriaGasto? tipo;
      await abrir(tester, onConfirm: (_, t) async => tipo = t);

      await tester.enterText(find.byType(TextFormField), 'Mercado');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(tipo, TipoCategoriaGasto.despesa);
    });

    testWidgets('edição abre preenchida com nome e tipo da categoria',
        (tester) async {
      TipoCategoriaGasto? tipo;
      await abrir(
        tester,
        categoria: _categoria(),
        onConfirm: (_, t) async => tipo = t,
      );

      expect(find.text('Editar Categoria'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Poupança'), findsOneWidget);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(tipo, TipoCategoriaGasto.patrimonio);
    });

    testWidgets('nome vazio não confirma', (tester) async {
      var chamado = false;
      await abrir(tester, onConfirm: (_, __) async => chamado = true);

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(find.text('O nome não pode ser vazio!'), findsOneWidget);
      expect(chamado, isFalse);
    });

    testWidgets('se a confirmação falhar o botão Salvar volta a ficar ativo',
        (tester) async {
      await abrir(tester, onConfirm: (_, __) async => throw Exception('erro'));

      await tester.enterText(find.byType(TextFormField), 'Mercado');
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Salvar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('CategoriesEmptyState', () {
    testWidgets('usa o texto e o ícone informados', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: CategoriesEmptyState(
            icon: Icons.savings_outlined,
            title: 'Nenhuma categoria deste tipo',
            subtitle: 'Toque em "Nova" para criar uma de Patrimônio',
          ),
        ),
      ));

      expect(find.byIcon(Icons.savings_outlined), findsOneWidget);
      expect(find.text('Nenhuma categoria deste tipo'), findsOneWidget);
      expect(find.textContaining('Patrimônio'), findsOneWidget);
    });

    testWidgets('mantém o texto padrão quando nada é informado',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: CategoriesEmptyState()),
      ));

      expect(find.text('Nenhuma categoria cadastrada'), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });
  });

  group('CategoryTipoBadge', () {
    Future<void> montar(WidgetTester tester, Widget badge) =>
        tester.pumpWidget(MaterialApp(home: Scaffold(body: badge)));

    testWidgets('mostra o rótulo de cada tipo', (tester) async {
      await montar(
          tester, const CategoryTipoBadge(tipo: TipoCategoriaGasto.patrimonio));
      expect(find.text('Patrimônio'), findsOneWidget);

      await montar(
          tester, const CategoryTipoBadge(tipo: TipoCategoriaGasto.despesa));
      expect(find.text('Despesa'), findsOneWidget);
    });

    testWidgets('ocultarDespesa esconde só a despesa', (tester) async {
      await montar(
        tester,
        const CategoryTipoBadge(
            tipo: TipoCategoriaGasto.despesa, ocultarDespesa: true),
      );
      expect(find.text('Despesa'), findsNothing);

      await montar(
        tester,
        const CategoryTipoBadge(
            tipo: TipoCategoriaGasto.patrimonio, ocultarDespesa: true),
      );
      expect(find.text('Patrimônio'), findsOneWidget);
    });
  });
}

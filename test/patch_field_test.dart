import 'package:flutter_test/flutter_test.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/patch_field.dart';

void main() {
  group('PatchField — serialização', () {
    test('Absent não adiciona a chave ao map', () {
      final map = <String, dynamic>{};
      const PatchField<String> field = PatchField.absent();

      field.addToMap(map, 'nome');

      expect(map.containsKey('nome'), isFalse);
    });

    test('Present adiciona a chave com o valor correto', () {
      final map = <String, dynamic>{};
      const PatchField<String> field = PatchField.value('Mercado');

      field.addToMap(map, 'nome');

      expect(map['nome'], 'Mercado');
    });

    test('Nulled adiciona a chave com null', () {
      final map = <String, dynamic>{};
      const PatchField<String> field = PatchField.nullValue();

      field.addToMap(map, 'observacoes');

      expect(map.containsKey('observacoes'), isTrue);
      expect(map['observacoes'], isNull);
    });

    test('Present com tipo nullable serializa corretamente', () {
      final map = <String, dynamic>{};
      const PatchField<int?> field = PatchField.value(null);

      field.addToMap(map, 'categoria_id');

      expect(map.containsKey('categoria_id'), isTrue);
      expect(map['categoria_id'], isNull);
    });

    test('Funciona com DateTime (requer conversão para ISO 8601)', () {
      final map = <String, dynamic>{};
      final data = DateTime.utc(2026, 6, 29, 10, 30);
      final field = PatchField<DateTime>.value(data);

      field.addToMap(map, 'data_pgto');

      expect(map['data_pgto'], data.toIso8601String());
    });
  });

  group('OrcamentoUpdateDto.toJson', () {
    test('body vazio quando todos os campos são Absent', () {
      final dto = OrcamentoUpdateDto();

      expect(dto.toJson(), isEmpty);
    });

    test('apenas campos presentes aparecem no body', () {
      final dto = OrcamentoUpdateDto(nome: PatchField.value('Viagem'));

      final json = dto.toJson();

      expect(json, {'nome': 'Viagem'});
    });

    test('null explícito (Nulled) aparece no body como null', () {
      final dto = OrcamentoUpdateDto(dataEncerramento: PatchField.nullValue());

      final json = dto.toJson();

      expect(json.containsKey('data_encerramento'), isTrue);
      expect(json['data_encerramento'], isNull);
    });
  });

  group('GastoFixoUpdateDto.toJson', () {
    test('combinação de Absent, Present e Nulled', () {
      final dataPgto = DateTime.utc(2026, 6, 29);
      final dto = GastoFixoUpdateDto(
        descricao: PatchField.value('Aluguel'),
        valor: PatchField.value('150.00'),
        dataPgto: PatchField.value(dataPgto),
        dataVenc: PatchField.nullValue(),
        observacoes: PatchField.absent(),
      );

      final json = dto.toJson();

      expect(json, {
        'descricao': 'Aluguel',
        'valor': '150.00',
        'data_pgto': dataPgto.toIso8601String(),
        'data_venc': null,
      });
      expect(json.containsKey('observacoes'), isFalse);
    });

    test('categoria_id limpo com Nulled', () {
      final dto = GastoFixoUpdateDto(categoriaId: PatchField.nullValue());

      final json = dto.toJson();

      expect(json, {'categoria_id': null});
    });

    test('categoria_id atualizado com Present', () {
      final dto = GastoFixoUpdateDto(categoriaId: PatchField.value(7));

      final json = dto.toJson();

      expect(json, {'categoria_id': 7});
    });
  });

  group('CategoriaGastoUpdateDto.toJson', () {
    test('combinação de Absent, Present e Nulled', () {
      final dto = CategoriaGastoUpdateDto(
        nome: PatchField.value('Lazer'),
        dataInatividade: PatchField.nullValue(),
      );

      final json = dto.toJson();

      expect(json, {
        'nome': 'Lazer',
        'data_inatividade': null,
      });
    });

    test('body vazio quando todos os campos são Absent', () {
      final dto = CategoriaGastoUpdateDto();

      expect(dto.toJson(), isEmpty);
    });
  });

  group('GastoVariadoUpdateDto.toJson', () {
    test('combinação de Absent, Present e Nulled', () {
      final dto = GastoVariadoUpdateDto(
        descricao: PatchField.value('Cinema'),
        observacoes: PatchField.value('Com desconto'),
        dataInatividade: PatchField.nullValue(),
      );

      final json = dto.toJson();

      expect(json, {
        'descricao': 'Cinema',
        'observacoes': 'Com desconto',
        'data_inatividade': null,
      });
      expect(json.containsKey('valor'), isFalse);
      expect(json.containsKey('categoria_id'), isFalse);
    });
  });
}

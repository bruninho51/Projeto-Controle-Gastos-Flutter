// ignore_for_file: invalid_annotation_target

import 'package:json_annotation/json_annotation.dart';

part 'api_models.g.dart';

/// Categoria de gasto (resposta)
@JsonSerializable()
class CategoriaGastoResponseDto {
  final int id;
  final String nome;

  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  CategoriaGastoResponseDto({
    required this.id,
    required this.nome,
    required this.dataCriacao,
    required this.dataAtualizacao,
    this.dataInatividade,
  });

  factory CategoriaGastoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$CategoriaGastoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriaGastoResponseDtoToJson(this);
}

/// DTO de criação de categoria de gasto
@JsonSerializable()
class CategoriaGastoCreateDto {
  final String nome;

  CategoriaGastoCreateDto({required this.nome});

  factory CategoriaGastoCreateDto.fromJson(Map<String, dynamic> json) =>
      _$CategoriaGastoCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriaGastoCreateDtoToJson(this);
}

/// DTO de atualização de categoria de gasto
@JsonSerializable()
class CategoriaGastoUpdateDto {
  final String? nome;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  CategoriaGastoUpdateDto({this.nome, this.dataInatividade});

  factory CategoriaGastoUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$CategoriaGastoUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoriaGastoUpdateDtoToJson(this);
}

/// DTO de criação de orçamento
@JsonSerializable()
class OrcamentoCreateDto {
  final String nome;

  @JsonKey(name: 'valor_inicial')
  final String valorInicial;

  OrcamentoCreateDto({required this.nome, required this.valorInicial});

  factory OrcamentoCreateDto.fromJson(Map<String, dynamic> json) =>
      _$OrcamentoCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrcamentoCreateDtoToJson(this);
}

/// Resposta de orçamento
@JsonSerializable()
class OrcamentoResponseDto {
  final int id;
  final String nome;

  @JsonKey(name: 'valor_inicial')
  final String valorInicial;

  @JsonKey(name: 'valor_atual')
  final String valorAtual;

  @JsonKey(name: 'valor_livre')
  final String valorLivre;

  @JsonKey(name: 'data_encerramento')
  final DateTime? dataEncerramento;

  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime? dataAtualizacao;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  OrcamentoResponseDto({
    required this.id,
    required this.nome,
    required this.valorInicial,
    required this.valorAtual,
    required this.valorLivre,
    this.dataEncerramento,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.dataInatividade,
  });

  factory OrcamentoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$OrcamentoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrcamentoResponseDtoToJson(this);
}

/// DTO de atualização de orçamento
@JsonSerializable()
class OrcamentoUpdateDto {
  final String? nome;

  @JsonKey(name: 'valor_inicial')
  final String? valorInicial;

  @JsonKey(name: 'data_encerramento')
  final DateTime? dataEncerramento;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  OrcamentoUpdateDto({
    this.nome,
    this.valorInicial,
    this.dataEncerramento,
    this.dataInatividade,
  });

  factory OrcamentoUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$OrcamentoUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrcamentoUpdateDtoToJson(this);
}

/// DTO de criação de gasto fixo
@JsonSerializable()
class GastoFixoCreateDto {
  final String descricao;
  final String previsto;

  @JsonKey(name: 'categoria_id')
  final int categoriaId;

  final String observacoes;

  @JsonKey(name: 'data_venc')
  final DateTime? dataVenc;

  GastoFixoCreateDto({
    required this.descricao,
    required this.previsto,
    required this.categoriaId,
    required this.observacoes,
    this.dataVenc,
  });

  factory GastoFixoCreateDto.fromJson(Map<String, dynamic> json) =>
      _$GastoFixoCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoFixoCreateDtoToJson(this);
}

/// Resposta de gasto fixo
@JsonSerializable()
class GastoFixoResponseDto {
  final int id;
  final String descricao;
  final String previsto;
  final String? valor;

  @JsonKey(name: 'categoria_id')
  final int categoriaId;

  @JsonKey(name: 'orcamento_id')
  final int orcamentoId;

  final String? diferenca;

  @JsonKey(name: 'data_pgto')
  final DateTime? dataPgto;

  @JsonKey(name: 'data_venc')
  final DateTime? dataVenc;

  final String? observacoes;

  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime? dataAtualizacao;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  @JsonKey(name: 'categoriaGasto')
  final CategoriaGastoResponseDto categoriaGasto;

  GastoFixoResponseDto({
    required this.id,
    required this.descricao,
    required this.previsto,
    this.valor,
    required this.categoriaId,
    required this.orcamentoId,
    this.diferenca,
    this.dataPgto,
    this.dataVenc,
    this.observacoes,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.dataInatividade,
    required this.categoriaGasto,
  });

  factory GastoFixoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GastoFixoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoFixoResponseDtoToJson(this);
}

/// DTO de atualização de gasto fixo
@JsonSerializable()
class GastoFixoUpdateDto {
  final String? descricao;
  final String? previsto;
  final String? valor;

  @JsonKey(name: 'data_pgto')
  final DateTime? dataPgto;

  @JsonKey(name: 'data_venc')
  final DateTime? dataVenc;

  @JsonKey(name: 'categoria_id')
  final int? categoriaId;

  final String? observacoes;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  GastoFixoUpdateDto({
    this.descricao,
    this.previsto,
    this.valor,
    this.dataPgto,
    this.dataVenc,
    this.categoriaId,
    this.observacoes,
    this.dataInatividade,
  });

  factory GastoFixoUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$GastoFixoUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoFixoUpdateDtoToJson(this);
}

/// DTO de criação de gasto variado
@JsonSerializable()
class GastoVariadoCreateDto {
  final String descricao;
  final String valor;

  @JsonKey(name: 'data_pgto')
  final DateTime dataPgto;

  @JsonKey(name: 'categoria_id')
  final int categoriaId;

  final String observacoes;

  GastoVariadoCreateDto({
    required this.descricao,
    required this.valor,
    required this.dataPgto,
    required this.categoriaId,
    required this.observacoes,
  });

  factory GastoVariadoCreateDto.fromJson(Map<String, dynamic> json) =>
      _$GastoVariadoCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoVariadoCreateDtoToJson(this);
}

/// Resposta de gasto variado
@JsonSerializable()
class GastoVariadoResponseDto {
  final int id;
  final String descricao;
  final String valor;

  @JsonKey(name: 'categoria_id')
  final int categoriaId;

  @JsonKey(name: 'orcamento_id')
  final int orcamentoId;

  @JsonKey(name: 'data_pgto')
  final DateTime dataPgto;

  final String? observacoes;

  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime? dataAtualizacao;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  @JsonKey(name: 'categoriaGasto')
  final CategoriaGastoResponseDto categoriaGasto;

  GastoVariadoResponseDto({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.categoriaId,
    required this.orcamentoId,
    required this.dataPgto,
    this.observacoes,
    required this.dataCriacao,
    this.dataAtualizacao,
    this.dataInatividade,
    required this.categoriaGasto,
  });

  factory GastoVariadoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$GastoVariadoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoVariadoResponseDtoToJson(this);
}

/// DTO de atualização de gasto variado
@JsonSerializable()
class GastoVariadoUpdateDto {
  final String? descricao;
  final String? valor;

  @JsonKey(name: 'data_pgto')
  final DateTime? dataPgto;

  @JsonKey(name: 'categoria_id')
  final int? categoriaId;

  final String? observacoes;

  @JsonKey(name: 'data_inatividade')
  final DateTime? dataInatividade;

  GastoVariadoUpdateDto({
    this.descricao,
    this.valor,
    this.dataPgto,
    this.categoriaId,
    this.observacoes,
    this.dataInatividade,
  });

  factory GastoVariadoUpdateDto.fromJson(Map<String, dynamic> json) =>
      _$GastoVariadoUpdateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$GastoVariadoUpdateDtoToJson(this);
}

/// DTO de autenticação (envio do token do Google)
@JsonSerializable()
class AuthCreateDto {
  @JsonKey(name: 'idToken')
  final String idToken;

  AuthCreateDto({required this.idToken});

  factory AuthCreateDto.fromJson(Map<String, dynamic> json) =>
      _$AuthCreateDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthCreateDtoToJson(this);
}

/// Resposta de autenticação (JWT da API)
@JsonSerializable()
class AuthResponseDto {
  @JsonKey(name: 'access_token')
  final String accessToken;

  AuthResponseDto({required this.accessToken});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$AuthResponseDtoToJson(this);
}
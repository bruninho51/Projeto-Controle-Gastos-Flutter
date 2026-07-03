// ignore_for_file: invalid_annotation_target

import 'package:json_annotation/json_annotation.dart';

import 'patch_field.dart';

part 'api_models.g.dart';

/// DTO de upsert de token de dispositivo
@JsonSerializable()
class TokenDispositivoUpsertDto {
  final String token;
  final String plataforma;

  TokenDispositivoUpsertDto({
    required this.token,
    required this.plataforma,
  });

  factory TokenDispositivoUpsertDto.fromJson(Map<String, dynamic> json) =>
      _$TokenDispositivoUpsertDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TokenDispositivoUpsertDtoToJson(this);
}

/// Resposta de token de dispositivo
@JsonSerializable()
class TokenDispositivoResponseDto {
  final int id;
  final String token;

  @JsonKey(name: 'usuario_id')
  final int usuarioId;

  final String plataforma;

  @JsonKey(name: 'data_criacao')
  final DateTime? dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime? dataAtualizacao;

  TokenDispositivoResponseDto({
    required this.id,
    required this.token,
    required this.usuarioId,
    required this.plataforma,
    this.dataCriacao,
    this.dataAtualizacao,
  });

  factory TokenDispositivoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TokenDispositivoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TokenDispositivoResponseDtoToJson(this);
}

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
class CategoriaGastoUpdateDto {
  final PatchField<String> nome;
  final PatchField<DateTime> dataInatividade;

  CategoriaGastoUpdateDto({
    this.nome = const PatchField.absent(),
    this.dataInatividade = const PatchField.absent(),
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    nome.addToMap(map, 'nome');
    dataInatividade.addToMap(map, 'data_inatividade');
    return map;
  }
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
class OrcamentoUpdateDto {
  final PatchField<String> nome;
  final PatchField<String> valorInicial;
  final PatchField<DateTime> dataEncerramento;
  final PatchField<DateTime> dataInatividade;

  OrcamentoUpdateDto({
    this.nome = const PatchField.absent(),
    this.valorInicial = const PatchField.absent(),
    this.dataEncerramento = const PatchField.absent(),
    this.dataInatividade = const PatchField.absent(),
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    nome.addToMap(map, 'nome');
    valorInicial.addToMap(map, 'valor_inicial');
    dataEncerramento.addToMap(map, 'data_encerramento');
    dataInatividade.addToMap(map, 'data_inatividade');
    return map;
  }
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
class GastoFixoUpdateDto {
  final PatchField<String> descricao;
  final PatchField<String> previsto;
  final PatchField<String> valor;
  final PatchField<DateTime> dataPgto;
  final PatchField<DateTime> dataVenc;
  final PatchField<int> categoriaId;
  final PatchField<String> observacoes;
  final PatchField<DateTime> dataInatividade;

  GastoFixoUpdateDto({
    this.descricao = const PatchField.absent(),
    this.previsto = const PatchField.absent(),
    this.valor = const PatchField.absent(),
    this.dataPgto = const PatchField.absent(),
    this.dataVenc = const PatchField.absent(),
    this.categoriaId = const PatchField.absent(),
    this.observacoes = const PatchField.absent(),
    this.dataInatividade = const PatchField.absent(),
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    descricao.addToMap(map, 'descricao');
    previsto.addToMap(map, 'previsto');
    valor.addToMap(map, 'valor');
    dataPgto.addToMap(map, 'data_pgto');
    dataVenc.addToMap(map, 'data_venc');
    categoriaId.addToMap(map, 'categoria_id');
    observacoes.addToMap(map, 'observacoes');
    dataInatividade.addToMap(map, 'data_inatividade');
    return map;
  }
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
class GastoVariadoUpdateDto {
  final PatchField<String> descricao;
  final PatchField<String> valor;
  final PatchField<DateTime> dataPgto;
  final PatchField<int> categoriaId;
  final PatchField<String> observacoes;
  final PatchField<DateTime> dataInatividade;

  GastoVariadoUpdateDto({
    this.descricao = const PatchField.absent(),
    this.valor = const PatchField.absent(),
    this.dataPgto = const PatchField.absent(),
    this.categoriaId = const PatchField.absent(),
    this.observacoes = const PatchField.absent(),
    this.dataInatividade = const PatchField.absent(),
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    descricao.addToMap(map, 'descricao');
    valor.addToMap(map, 'valor');
    dataPgto.addToMap(map, 'data_pgto');
    categoriaId.addToMap(map, 'categoria_id');
    observacoes.addToMap(map, 'observacoes');
    dataInatividade.addToMap(map, 'data_inatividade');
    return map;
  }
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

/// DTO de requisição para obter/gerar um padrão de regex de notificação bancária
@JsonSerializable()
class PadraoRegexNotificacaoRequestDto {
  @JsonKey(name: 'instituicao_financeira')
  final String instituicaoFinanceira;

  @JsonKey(name: 'titulo_notificacao')
  final String tituloNotificacao;

  @JsonKey(name: 'corpo_notificacao')
  final String corpoNotificacao;

  PadraoRegexNotificacaoRequestDto({
    required this.instituicaoFinanceira,
    required this.tituloNotificacao,
    required this.corpoNotificacao,
  });

  factory PadraoRegexNotificacaoRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PadraoRegexNotificacaoRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PadraoRegexNotificacaoRequestDtoToJson(this);
}

/// Resposta de um padrão de regex de notificação bancária
@JsonSerializable()
class PadraoRegexNotificacaoResponseDto {
  final int id;

  @JsonKey(name: 'instituicao_financeira')
  final String instituicaoFinanceira;

  @JsonKey(name: 'titulo_notificacao')
  final String tituloNotificacao;

  final String regex;

  @JsonKey(name: 'data_criacao')
  final DateTime dataCriacao;

  @JsonKey(name: 'data_atualizacao')
  final DateTime dataAtualizacao;

  @JsonKey(name: 'data_expiracao')
  final DateTime dataExpiracao;

  PadraoRegexNotificacaoResponseDto({
    required this.id,
    required this.instituicaoFinanceira,
    required this.tituloNotificacao,
    required this.regex,
    required this.dataCriacao,
    required this.dataAtualizacao,
    required this.dataExpiracao,
  });

  factory PadraoRegexNotificacaoResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PadraoRegexNotificacaoResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PadraoRegexNotificacaoResponseDtoToJson(this);
}
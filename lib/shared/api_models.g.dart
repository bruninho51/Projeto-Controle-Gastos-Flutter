// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoriaGastoResponseDto _$CategoriaGastoResponseDtoFromJson(
        Map<String, dynamic> json) =>
    CategoriaGastoResponseDto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
      dataAtualizacao: DateTime.parse(json['data_atualizacao'] as String),
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$CategoriaGastoResponseDtoToJson(
        CategoriaGastoResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'data_criacao': instance.dataCriacao.toIso8601String(),
      'data_atualizacao': instance.dataAtualizacao.toIso8601String(),
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

CategoriaGastoCreateDto _$CategoriaGastoCreateDtoFromJson(
        Map<String, dynamic> json) =>
    CategoriaGastoCreateDto(
      nome: json['nome'] as String,
    );

Map<String, dynamic> _$CategoriaGastoCreateDtoToJson(
        CategoriaGastoCreateDto instance) =>
    <String, dynamic>{
      'nome': instance.nome,
    };

CategoriaGastoUpdateDto _$CategoriaGastoUpdateDtoFromJson(
        Map<String, dynamic> json) =>
    CategoriaGastoUpdateDto(
      nome: json['nome'] as String?,
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$CategoriaGastoUpdateDtoToJson(
        CategoriaGastoUpdateDto instance) =>
    <String, dynamic>{
      'nome': instance.nome,
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

OrcamentoCreateDto _$OrcamentoCreateDtoFromJson(Map<String, dynamic> json) =>
    OrcamentoCreateDto(
      nome: json['nome'] as String,
      valorInicial: json['valor_inicial'] as String,
    );

Map<String, dynamic> _$OrcamentoCreateDtoToJson(OrcamentoCreateDto instance) =>
    <String, dynamic>{
      'nome': instance.nome,
      'valor_inicial': instance.valorInicial,
    };

OrcamentoResponseDto _$OrcamentoResponseDtoFromJson(
        Map<String, dynamic> json) =>
    OrcamentoResponseDto(
      id: (json['id'] as num).toInt(),
      nome: json['nome'] as String,
      valorInicial: json['valor_inicial'] as String,
      valorAtual: json['valor_atual'] as String,
      valorLivre: json['valor_livre'] as String,
      dataEncerramento: json['data_encerramento'] == null
          ? null
          : DateTime.parse(json['data_encerramento'] as String),
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
      dataAtualizacao: json['data_atualizacao'] == null
          ? null
          : DateTime.parse(json['data_atualizacao'] as String),
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$OrcamentoResponseDtoToJson(
        OrcamentoResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'valor_inicial': instance.valorInicial,
      'valor_atual': instance.valorAtual,
      'valor_livre': instance.valorLivre,
      'data_encerramento': instance.dataEncerramento?.toIso8601String(),
      'data_criacao': instance.dataCriacao.toIso8601String(),
      'data_atualizacao': instance.dataAtualizacao?.toIso8601String(),
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

OrcamentoUpdateDto _$OrcamentoUpdateDtoFromJson(Map<String, dynamic> json) =>
    OrcamentoUpdateDto(
      nome: json['nome'] as String?,
      valorInicial: json['valor_inicial'] as String?,
      dataEncerramento: json['data_encerramento'] == null
          ? null
          : DateTime.parse(json['data_encerramento'] as String),
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$OrcamentoUpdateDtoToJson(OrcamentoUpdateDto instance) =>
    <String, dynamic>{
      'nome': instance.nome,
      'valor_inicial': instance.valorInicial,
      'data_encerramento': instance.dataEncerramento?.toIso8601String(),
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

GastoFixoCreateDto _$GastoFixoCreateDtoFromJson(Map<String, dynamic> json) =>
    GastoFixoCreateDto(
      descricao: json['descricao'] as String,
      previsto: json['previsto'] as String,
      categoriaId: (json['categoria_id'] as num).toInt(),
      observacoes: json['observacoes'] as String,
      dataVenc: json['data_venc'] == null
          ? null
          : DateTime.parse(json['data_venc'] as String),
    );

Map<String, dynamic> _$GastoFixoCreateDtoToJson(GastoFixoCreateDto instance) =>
    <String, dynamic>{
      'descricao': instance.descricao,
      'previsto': instance.previsto,
      'categoria_id': instance.categoriaId,
      'observacoes': instance.observacoes,
      'data_venc': instance.dataVenc?.toIso8601String(),
    };

GastoFixoResponseDto _$GastoFixoResponseDtoFromJson(
        Map<String, dynamic> json) =>
    GastoFixoResponseDto(
      id: (json['id'] as num).toInt(),
      descricao: json['descricao'] as String,
      previsto: json['previsto'] as String,
      valor: json['valor'] as String?,
      categoriaId: (json['categoria_id'] as num).toInt(),
      orcamentoId: (json['orcamento_id'] as num).toInt(),
      diferenca: json['diferenca'] as String?,
      dataPgto: json['data_pgto'] == null
          ? null
          : DateTime.parse(json['data_pgto'] as String),
      dataVenc: json['data_venc'] == null
          ? null
          : DateTime.parse(json['data_venc'] as String),
      observacoes: json['observacoes'] as String?,
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
      dataAtualizacao: json['data_atualizacao'] == null
          ? null
          : DateTime.parse(json['data_atualizacao'] as String),
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
      categoriaGasto: CategoriaGastoResponseDto.fromJson(
          json['categoriaGasto'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GastoFixoResponseDtoToJson(
        GastoFixoResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'descricao': instance.descricao,
      'previsto': instance.previsto,
      'valor': instance.valor,
      'categoria_id': instance.categoriaId,
      'orcamento_id': instance.orcamentoId,
      'diferenca': instance.diferenca,
      'data_pgto': instance.dataPgto?.toIso8601String(),
      'data_venc': instance.dataVenc?.toIso8601String(),
      'observacoes': instance.observacoes,
      'data_criacao': instance.dataCriacao.toIso8601String(),
      'data_atualizacao': instance.dataAtualizacao?.toIso8601String(),
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
      'categoriaGasto': instance.categoriaGasto,
    };

GastoFixoUpdateDto _$GastoFixoUpdateDtoFromJson(Map<String, dynamic> json) =>
    GastoFixoUpdateDto(
      descricao: json['descricao'] as String?,
      previsto: json['previsto'] as String?,
      valor: json['valor'] as String?,
      dataPgto: json['data_pgto'] == null
          ? null
          : DateTime.parse(json['data_pgto'] as String),
      dataVenc: json['data_venc'] == null
          ? null
          : DateTime.parse(json['data_venc'] as String),
      categoriaId: (json['categoria_id'] as num?)?.toInt(),
      observacoes: json['observacoes'] as String?,
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$GastoFixoUpdateDtoToJson(GastoFixoUpdateDto instance) =>
    <String, dynamic>{
      'descricao': instance.descricao,
      'previsto': instance.previsto,
      'valor': instance.valor,
      'data_pgto': instance.dataPgto?.toIso8601String(),
      'data_venc': instance.dataVenc?.toIso8601String(),
      'categoria_id': instance.categoriaId,
      'observacoes': instance.observacoes,
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

GastoVariadoCreateDto _$GastoVariadoCreateDtoFromJson(
        Map<String, dynamic> json) =>
    GastoVariadoCreateDto(
      descricao: json['descricao'] as String,
      valor: json['valor'] as String,
      dataPgto: DateTime.parse(json['data_pgto'] as String),
      categoriaId: (json['categoria_id'] as num).toInt(),
      observacoes: json['observacoes'] as String,
    );

Map<String, dynamic> _$GastoVariadoCreateDtoToJson(
        GastoVariadoCreateDto instance) =>
    <String, dynamic>{
      'descricao': instance.descricao,
      'valor': instance.valor,
      'data_pgto': instance.dataPgto.toIso8601String(),
      'categoria_id': instance.categoriaId,
      'observacoes': instance.observacoes,
    };

GastoVariadoResponseDto _$GastoVariadoResponseDtoFromJson(
        Map<String, dynamic> json) =>
    GastoVariadoResponseDto(
      id: (json['id'] as num).toInt(),
      descricao: json['descricao'] as String,
      valor: json['valor'] as String,
      categoriaId: (json['categoria_id'] as num).toInt(),
      orcamentoId: (json['orcamento_id'] as num).toInt(),
      dataPgto: DateTime.parse(json['data_pgto'] as String),
      observacoes: json['observacoes'] as String?,
      dataCriacao: DateTime.parse(json['data_criacao'] as String),
      dataAtualizacao: json['data_atualizacao'] == null
          ? null
          : DateTime.parse(json['data_atualizacao'] as String),
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
      categoriaGasto: CategoriaGastoResponseDto.fromJson(
          json['categoriaGasto'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$GastoVariadoResponseDtoToJson(
        GastoVariadoResponseDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'descricao': instance.descricao,
      'valor': instance.valor,
      'categoria_id': instance.categoriaId,
      'orcamento_id': instance.orcamentoId,
      'data_pgto': instance.dataPgto.toIso8601String(),
      'observacoes': instance.observacoes,
      'data_criacao': instance.dataCriacao.toIso8601String(),
      'data_atualizacao': instance.dataAtualizacao?.toIso8601String(),
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
      'categoriaGasto': instance.categoriaGasto,
    };

GastoVariadoUpdateDto _$GastoVariadoUpdateDtoFromJson(
        Map<String, dynamic> json) =>
    GastoVariadoUpdateDto(
      descricao: json['descricao'] as String?,
      valor: json['valor'] as String?,
      dataPgto: json['data_pgto'] == null
          ? null
          : DateTime.parse(json['data_pgto'] as String),
      categoriaId: (json['categoria_id'] as num?)?.toInt(),
      observacoes: json['observacoes'] as String?,
      dataInatividade: json['data_inatividade'] == null
          ? null
          : DateTime.parse(json['data_inatividade'] as String),
    );

Map<String, dynamic> _$GastoVariadoUpdateDtoToJson(
        GastoVariadoUpdateDto instance) =>
    <String, dynamic>{
      'descricao': instance.descricao,
      'valor': instance.valor,
      'data_pgto': instance.dataPgto?.toIso8601String(),
      'categoria_id': instance.categoriaId,
      'observacoes': instance.observacoes,
      'data_inatividade': instance.dataInatividade?.toIso8601String(),
    };

AuthCreateDto _$AuthCreateDtoFromJson(Map<String, dynamic> json) =>
    AuthCreateDto(
      idToken: json['idToken'] as String,
    );

Map<String, dynamic> _$AuthCreateDtoToJson(AuthCreateDto instance) =>
    <String, dynamic>{
      'idToken': instance.idToken,
    };

AuthResponseDto _$AuthResponseDtoFromJson(Map<String, dynamic> json) =>
    AuthResponseDto(
      accessToken: json['access_token'] as String,
    );

Map<String, dynamic> _$AuthResponseDtoToJson(AuthResponseDto instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
    };

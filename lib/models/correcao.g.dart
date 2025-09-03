// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correcao.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Correcao _$CorrecaoFromJson(Map<String, dynamic> json) => Correcao(
  id: json['id'] as String,
  nomeAluno: json['nomeAluno'] as String,
  respostas: Map<String, String>.from(json['respostas'] as Map),
  acertos: (json['acertos'] as num).toInt(),
  nota: (json['nota'] as num).toDouble(),
  data: DateTime.parse(json['data'] as String),
);

Map<String, dynamic> _$CorrecaoToJson(Correcao instance) => <String, dynamic>{
  'id': instance.id,
  'nomeAluno': instance.nomeAluno,
  'respostas': instance.respostas,
  'acertos': instance.acertos,
  'nota': instance.nota,
  'data': instance.data.toIso8601String(),
};

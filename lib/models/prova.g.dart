// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prova.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Prova _$ProvaFromJson(Map<String, dynamic> json) => Prova(
      id: (json['id'] as num?)?.toInt(),
      nome: json['nome'] as String,
      data: json['data'] as String,
      numeroDeQuestoes: (json['numeroDeQuestoes'] as num?)?.toInt() ?? 10,
      correcoes: (json['correcoes'] as List<dynamic>?)
              ?.map((e) => Correcao.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    )..gabaritoOficial =
        Map<String, String>.from(json['gabaritoOficial'] as Map);

Map<String, dynamic> _$ProvaToJson(Prova instance) => <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'data': instance.data,
      'numeroDeQuestoes': instance.numeroDeQuestoes,
      'gabaritoOficial': instance.gabaritoOficial,
      'correcoes': instance.correcoes.map((e) => e.toJson()).toList(),
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turma.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Turma _$TurmaFromJson(Map<String, dynamic> json) => Turma(
      id: (json['id'] as num?)?.toInt(),
      nome: json['nome'] as String,
      alunos: (json['alunos'] as List<dynamic>?)
              ?.map((e) => Aluno.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      provas: (json['provas'] as List<dynamic>?)
              ?.map((e) => Prova.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      numeroDeAlunos: (json['numeroDeAlunos'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$TurmaToJson(Turma instance) => <String, dynamic>{
      'id': instance.id,
      'nome': instance.nome,
      'alunos': instance.alunos.map((e) => e.toJson()).toList(),
      'provas': instance.provas.map((e) => e.toJson()).toList(),
      'numeroDeAlunos': instance.numeroDeAlunos,
    };

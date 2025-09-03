// lib/models/turma.dart
import 'package:json_annotation/json_annotation.dart';
import 'aluno.dart'; // Importa a nova classe
import 'prova.dart';

part 'turma.g.dart';

@JsonSerializable(explicitToJson: true)
class Turma {
  final String id;
  String nome;
  List<Aluno> alunos; // Adiciona a lista de alunos
  List<Prova> provas;

  // Propriedade calculada para o número de alunos
  int get numeroDeAlunos => alunos.length;

  Turma({
    required this.id,
    required this.nome,
    this.alunos = const [], // Inicializa a lista
    required this.provas,
  });

  factory Turma.fromJson(Map<String, dynamic> json) => _$TurmaFromJson(json);
  Map<String, dynamic> toJson() => _$TurmaToJson(this);
}
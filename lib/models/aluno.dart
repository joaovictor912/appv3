import 'package:json_annotation/json_annotation.dart';

part 'aluno.g.dart';

@JsonSerializable()
class Aluno {
  final String id; // ID interno, gerado pelo app
  String nome;
  String matricula; // O ID/matrícula que o utilizador vai inserir

  Aluno({
    required this.id,
    required this.nome,
    required this.matricula, // Adiciona ao construtor
  });

  factory Aluno.fromJson(Map<String, dynamic> json) => _$AlunoFromJson(json);
  Map<String, dynamic> toJson() => _$AlunoToJson(this);
}
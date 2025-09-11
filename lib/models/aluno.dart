import 'package:json_annotation/json_annotation.dart';

part 'aluno.g.dart';

@JsonSerializable()
class Aluno {
  final int? id; // ID do banco de dados (int e opcional)
  String nome;
  String matricula; // O ID/matrícula que o utilizador vai inserir

  Aluno({
    this.id,
    required this.nome,
    required this.matricula,
  });


  factory Aluno.fromMap(Map<String, dynamic> map) {
    return Aluno(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      matricula: map['matricula'] as String,
    );
  }

  /// Método para converter um Aluno em um Map para salvar no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'matricula': matricula,
    };
  }

  // --- MÉTODOS PARA JSON (Gerados automaticamente) ---

  factory Aluno.fromJson(Map<String, dynamic> json) => _$AlunoFromJson(json);
  Map<String, dynamic> toJson() => _$AlunoToJson(this);
}
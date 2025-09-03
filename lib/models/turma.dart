import 'package:json_annotation/json_annotation.dart';
import 'aluno.dart';
import 'prova.dart';

part 'turma.g.dart';

@JsonSerializable(explicitToJson: true)
class Turma {
  final int? id;
  String nome;
  List<Aluno> alunos;
  List<Prova> provas;

  int get numeroDeAlunos => alunos.length;

  Turma({
    this.id,
    required this.nome,
    this.alunos = const [],
    this.provas = const [],
  });

  // MÉTODO 'COPY' ADICIONADO AQUI
  // Utilizado para criar uma cópia da turma, modificando apenas alguns campos.
  // Muito útil para a função de editar.
  Turma copy({int? id, String? nome, List<Aluno>? alunos, List<Prova>? provas}) {
    return Turma(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      alunos: alunos ?? this.alunos,
      provas: provas ?? this.provas,
    );
  }

  // --- MÉTODOS PARA O BANCO DE DADOS ---
  factory Turma.fromMap(Map<String, dynamic> map) {
    return Turma(
      id: map['id'] as int,
      nome: map['nome'] as String,
      alunos: [],
      provas: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
    };
  }

  // --- MÉTODOS PARA JSON ---
  factory Turma.fromJson(Map<String, dynamic> json) => _$TurmaFromJson(json);
  Map<String, dynamic> toJson() => _$TurmaToJson(this);
}
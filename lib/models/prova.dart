import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'correcao.dart';

part 'prova.g.dart';

@JsonSerializable(explicitToJson: true)
class Prova {
  final int? id; // <-- ID do banco de dados é um inteiro e opcional
  String nome;
  String data;
  int numeroDeQuestoes;
  Map<String, String> gabaritoOficial;
  List<Correcao> correcoes;

  Prova({
    this.id, // <-- ID agora é opcional, não 'required'
    required this.nome,
    required this.data,
    this.numeroDeQuestoes = 10,
    Map<String, String>? gabarito,
    this.correcoes = const [],
  }) : gabaritoOficial = gabarito ?? {};

  // --- MÉTODOS PARA O BANCO DE DADOS ---
  factory Prova.fromMap(Map<String, dynamic> map) {
    return Prova(
      id: map['id'] as int,
      nome: map['nome'] as String,
      data: map['data'] as String? ?? '', // Adicionado data aqui
      numeroDeQuestoes: map['numeroDeQuestoes'] as int,
      gabarito: Map<String, String>.from(jsonDecode(map['gabaritoOficial'])),
      correcoes: [], // Correções são carregadas separadamente
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'data': data,
      'numeroDeQuestoes': numeroDeQuestoes,
      'gabaritoOficial': jsonEncode(gabaritoOficial),
    };
  }

  // --- MÉTODOS PARA JSON ---
  factory Prova.fromJson(Map<String, dynamic> json) => _$ProvaFromJson(json);
  Map<String, dynamic> toJson() => _$ProvaToJson(this);
}
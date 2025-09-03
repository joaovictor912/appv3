import 'package:json_annotation/json_annotation.dart';

part 'correcao.g.dart';

@JsonSerializable()
class Correcao {
  final String id;
  final String nomeAluno;
  final Map<String, String> respostas;
  final int acertos;
  final double nota;
  final DateTime data;

  Correcao({
    required this.id,
    required this.nomeAluno,
    required this.respostas,
    required this.acertos,
    required this.nota,
    required this.data,
  });

  factory Correcao.fromJson(Map<String, dynamic> json) => _$CorrecaoFromJson(json);
  Map<String, dynamic> toJson() => _$CorrecaoToJson(this);
}
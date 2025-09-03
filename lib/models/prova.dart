import 'package:json_annotation/json_annotation.dart';
import 'correcao.dart'; // 1. Importação da nova classe

part 'prova.g.dart';

// 2. Adicionado explicitToJson para serializar a lista de objetos Correcao
@JsonSerializable(explicitToJson: true) 
class Prova {
  final String id;
  String nome;
  String data;
  int numeroDeQuestoes;
  Map<String, String> gabaritoOficial;
  List<Correcao> correcoes; // 3. Nova propriedade para armazenar as correções

  Prova({
    required this.id,
    required this.nome,
    required this.data,
    this.numeroDeQuestoes = 20,
    Map<String, String>? gabarito,
    this.correcoes = const [], // 4. Inicialização da nova lista
  }) : gabaritoOficial = gabarito ?? {};

  factory Prova.fromJson(Map<String, dynamic> json) => _$ProvaFromJson(json);
  
  Map<String, dynamic> toJson() => _$ProvaToJson(this);
}
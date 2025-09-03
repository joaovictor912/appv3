import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/turma.dart';

class PersistenciaService {
  // Salva a lista de turmas no disco
  Future<void> salvarTurmas(List<Turma> turmas) async {
    final prefs = await SharedPreferences.getInstance();
    // Converte a lista de objetos Turma para uma lista de Mapas, e depois para uma string JSON
    List<String> listaDeJsons = turmas.map((turma) => jsonEncode(turma.toJson())).toList();
    await prefs.setStringList('lista_turmas', listaDeJsons);
  }

  // Carrega a lista de turmas do disco
  Future<List<Turma>> carregarTurmas() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? listaDeJsons = prefs.getStringList('lista_turmas');

    if (listaDeJsons == null) {
      return []; // Se não há nada salvo, retorna uma lista vazia
    }

    // Converte a string JSON de volta para uma lista de objetos Turma
    List<Turma> turmas = listaDeJsons.map((jsonString) => Turma.fromJson(jsonDecode(jsonString))).toList();
    return turmas;
  }
}
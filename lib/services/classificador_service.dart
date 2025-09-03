import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassificadorService {
  bool _isInitialized = false;
  late List<String> _labels;
  Interpreter? _interpreter;

  // Inicializa o modelo e os rótulos
  Future<void> initialize() async {
    if (_isInitialized) return; // evita inicialização dupla

    // Carrega os labels
    final labelsData = await rootBundle.loadString('assets/models/classificador_bolhas_labels.txt');
    _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();

    // Carrega o modelo com o Interpreter
    _interpreter = await Interpreter.fromAsset('models/classificador_bolhas.tflite');

    _isInitialized = true;
    print("✅ Classificador inicializado com TensorFlow Lite!");
  }

  // Classifica uma bolha a partir de uma imagem
  Future<String> classificarBolha(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception("Serviço não inicializado. Chame initialize() primeiro.");
    }

    // Prepara a entrada
    var input = _prepararImagem(imageBytes);

    // Saída: assumindo que seu modelo retorna vetor [1, num_classes]
    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    // Executa o modelo
    _interpreter!.run(input, output);

    // Encontra a classe com maior probabilidade
    double maiorValor = -1;
    int indice = -1;
    for (int i = 0; i < _labels.length; i++) {
      if (output[0][i] > maiorValor) {
        maiorValor = output[0][i];
        indice = i;
      }
    }

    return indice == -1 ? "desconhecido" : _labels[indice];
  }

  // Pré-processa a imagem (224x224 RGB normalizado em Float32)
  List<List<List<List<double>>>> _prepararImagem(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Não foi possível decodificar a imagem.");
    }

    // Redimensiona
    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    // Modelo espera [1, 224, 224, 3]
    var input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(
          224,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  // Libera os recursos
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

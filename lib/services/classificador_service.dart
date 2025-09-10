import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassificadorService {
  bool _isInitialized = false;
  late List<String> _labels;
  Interpreter? _interpreter;

  Future<void> initialize() async {
    if (_isInitialized) return;
    final labelsData = await rootBundle.loadString('assets/models/classificador_bolhas_labels.txt');
    _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    _interpreter = await Interpreter.fromAsset('assets/models/classificador_bolhas.tflite');
    _isInitialized = true;
  }

  Future<String> classificarBolha(Uint8List imageBytes) async {
  if (!_isInitialized || _interpreter == null) {
    throw Exception("Serviço não inicializado. Chame initialize() primeiro.");
  }

  // A preparação da imagem de entrada já está correta
  final inputTensor = _prepararImagem(imageBytes);
  final input = inputTensor.reshape([1, 224, 224, 3]);

  // A criação do buffer de saída também está correta
  final output = Uint8List(1 * _labels.length).reshape([1, _labels.length]);

  _interpreter!.run(input, output);
  
  final scores = output[0];
  int highestScore = -1;
  int bestIndex = -1;

  for (int i = 0; i < scores.length; i++) {
    if (scores[i] > highestScore) {
      highestScore = scores[i];
      bestIndex = i;
    }
  }

  // --- CÓDIGO DE DEPURAÇÃO (ADICIONE AQUI) ---
  print('--- DEPURAÇÃO DA CLASSIFICAÇÃO ---');
  print('Labels do modelo (Ordem): $_labels');
  print('Pontuações da IA (Scores): $scores');
  print('Maior Pontuação encontrada: $highestScore no índice $bestIndex');
  print('Decisão Final: ${_labels[bestIndex]}');
  print('----------------------------------');
  // --- FIM DO CÓDIGO DE DEPURAÇÃO ---

  // O 'bestIndex' é o nosso resultado.
  // Se o bestIndex for 0, ele pega o primeiro label, se for 1, pega o segundo, etc.
  return bestIndex == -1 ? "desconhecido" : _labels[bestIndex];
}
  
  Uint8List _prepararImagem(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Não foi possível decodificar a imagem.");
    }
    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);
    final inputBytes = Uint8List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = pixel.r.toInt();
        inputBytes[pixelIndex++] = pixel.g.toInt();
        inputBytes[pixelIndex++] = pixel.b.toInt();
      }
    }
    return inputBytes;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
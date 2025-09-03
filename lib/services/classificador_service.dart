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

    // SUGESTÃO 1: Corrigido o caminho do asset
    _interpreter = await Interpreter.fromAsset('assets/models/classificador_bolhas.tflite');

    _isInitialized = true;
  }

  Future<String> classificarBolha(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception("Serviço não inicializado. Chame initialize() primeiro.");
    }

    // SUGESTÃO 3: A entrada agora é um Float32List e o reshape é feito no final
    final inputTensor = _prepararImagem(imageBytes);
    final input = inputTensor.reshape([1, 224, 224, 3]);

    var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);
    
    // SUGESTÃO 2: Lógica simplificada para encontrar o melhor resultado
    final outputList = output[0].cast<double>();
    double maiorValor = outputList.reduce((a, b) => a > b ? a : b);
    int indice = outputList.indexOf(maiorValor);

    return indice == -1 ? "desconhecido" : _labels[indice];
  }
  
  // SUGESTÃO 3: Refatorado para usar Float32List para melhor performance
  Float32List _prepararImagem(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Não foi possível decodificar a imagem.");
    }

    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    final inputBytes = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        inputBytes[pixelIndex++] = pixel.r / 255.0;
        inputBytes[pixelIndex++] = pixel.g / 255.0;
        inputBytes[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return inputBytes;
  }

  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
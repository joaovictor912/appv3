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
      final inputDetails = _interpreter!.getInputTensor(0);
      final outputDetails = _interpreter!.getOutputTensor(0);
      print('--- DIAGNÓSTICO TFLITE ---');
      print('ENTRADA (INPUT) Esperada:');
      print('  - Tipo de Dado: ${inputDetails.type}');
      print('  - Formato/Shape: ${inputDetails.shape}');
      print('SAÍDA (OUTPUT) Esperada:');
      print('  - Tipo de Dado: ${outputDetails.type}');
      print('  - Formato/Shape: ${outputDetails.shape}');
      print('--------------------------');
    _isInitialized = true;
  }

  Future<String> classificarBolha(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null) {
      throw Exception("Serviço não inicializado. Chame initialize() primeiro.");
    }

    // A entrada agora é um Uint8List, que será preparado pela função _prepararImagem
    final inputTensor = _prepararImagem(imageBytes);
    // O reshape continua o mesmo, pois a estrutura [batch, height, width, channels] é a mesma
    final input = inputTensor.reshape([1, 224, 224, 3]);

    // A saída do modelo geralmente é em float, então mantemos a configuração da saída
    var output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);
    
    final outputList = output[0].cast<double>();
    double maiorValor = outputList.reduce((a, b) => a > b ? a : b);
    int indice = outputList.indexOf(maiorValor);

    return indice == -1 ? "desconhecido" : _labels[indice];
  }
  
  // CORREÇÃO APLICADA AQUI
  // A função agora retorna Uint8List e não divide os valores dos pixels.
  Uint8List _prepararImagem(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Não foi possível decodificar a imagem.");
    }

    final resizedImage = img.copyResize(originalImage, width: 224, height: 224);

    // 1. Usamos Uint8List para armazenar inteiros de 0 a 255
    final inputBytes = Uint8List(1 * 224 * 224 * 3);
    int pixelIndex = 0;
    for (var y = 0; y < 224; y++) {
      for (var x = 0; x < 224; x++) {
        final pixel = resizedImage.getPixel(x, y);
        // 2. Removemos a divisão por 255.0
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
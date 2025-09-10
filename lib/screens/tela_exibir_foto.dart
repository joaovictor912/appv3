import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import '../models/prova.dart';
import '../services/classificador_service.dart';
import 'tela_resultado.dart';

class TelaExibirFoto extends StatefulWidget {
  final String imagePath;
  final Prova prova;
  final String nomeAluno;
  final VoidCallback onDadosAlterados;

  const TelaExibirFoto({
    super.key,
    required this.imagePath,
    required this.prova,
    required this.nomeAluno,
    required this.onDadosAlterados,
  });

  @override
  State<TelaExibirFoto> createState() => _TelaExibirFotoState();
}

class _TelaExibirFotoState extends State<TelaExibirFoto> {
  bool _isProcessing = false;
  final _classificadorService = ClassificadorService();
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _classificadorService.initialize();
  }

  @override
  void dispose() {
    _classificadorService.dispose();
    super.dispose();
  }

  Future<void> _analisarEObterResultado() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final imagemOriginal = cv.imdecode(bytes, cv.IMREAD_COLOR);

      final cinza = cv.cvtColor(imagemOriginal, cv.COLOR_BGR2GRAY);
      final borrada = cv.gaussianBlur(cinza, (5, 5), 0);
      final bordas = cv.canny(borrada, 75, 200);

      final contornos = cv.findContours(bordas, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE).$1;
      final contornosList = contornos.toList();
      contornosList.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

      cv.VecPoint? contornoDaFolha;
      for (var c in contornosList) {
        final perimetro = cv.arcLength(c, true);
        final approx = cv.approxPolyDP(c, 0.02 * perimetro, true);
        if (approx.length == 4) {
          contornoDaFolha = approx;
          break;
        }
      }

      if (contornoDaFolha == null) {
        throw Exception("Não foi possível encontrar os 4 cantos da folha.");
      }

      final folhaCorrigida = fourPointTransform(imagemOriginal, contornoDaFolha);

      final threshParaContornos = cv.threshold(
          cv.cvtColor(folhaCorrigida, cv.COLOR_BGR2GRAY), 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU).$2;

      final (bolhasCnts, _) = cv.findContours(threshParaContornos, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);

      final List<cv.Rect> bolhasRects = [];
      for (var c in bolhasCnts.toList()) {
        final rect = cv.boundingRect(c);
        final aspectRatio = rect.width / rect.height;
        if (rect.width >= 20 && rect.height >= 20 && aspectRatio >= 0.8 && aspectRatio <= 1.2) {
          bolhasRects.add(rect);
        }
      }

      if (bolhasRects.isEmpty || bolhasRects.length % 5 != 0) {
        throw Exception("Número de bolhas detectado é inválido: ${bolhasRects.length}");
      }

      bolhasRects.sort((a, b) => a.y.compareTo(b.y));

      final Map<String, String> respostasDoAluno = {};
      final alternativas = ['A', 'B', 'C', 'D', 'E'];

      for (int i = 0; i < bolhasRects.length; i += 5) {
        final linha = bolhasRects.sublist(i, i + 5)..sort((a, b) => a.x.compareTo(b.x));

        int? bolhaMarcadaIndex;
        Uint8List? bytesCandidato;
        int pixelsPreenchidos = -1;

        for (int j = 0; j < linha.length; j++) {
          final rect = linha[j];
          final bolhaROI = folhaCorrigida.region(rect);
          final bolhaThresh = cv.threshold(cv.cvtColor(bolhaROI, cv.COLOR_BGR2GRAY), 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU).$2;
          final total = cv.countNonZero(bolhaThresh);

          if (total > pixelsPreenchidos) {
            pixelsPreenchidos = total;
            bolhaMarcadaIndex = j;
            bytesCandidato = cv.imencode(".jpg", bolhaROI).$2;
          }
        }

        String resultadoIA = "vazia";
        if (bytesCandidato != null) {
          resultadoIA = await _classificadorService.classificarBolha(bytesCandidato);
        }

        final numeroQuestao = (i ~/ 5) + 1;
        respostasDoAluno[numeroQuestao.toString()] = (resultadoIA == 'marcada' && bolhaMarcadaIndex != null)
            ? alternativas[bolhaMarcadaIndex]
            : 'N/A';
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaResultado(
            respostasAluno: respostasDoAluno,
            gabaritoMestre: widget.prova.gabaritoOficial,
            totalQuestoes: widget.prova.numeroDeQuestoes,
            prova: widget.prova,
            nomeAluno: widget.nomeAluno,
            onDadosAlterados: widget.onDadosAlterados,
          ),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na análise: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  cv.Mat fourPointTransform(cv.Mat image, cv.VecPoint pts) {
    final rect = orderPoints(pts);
    final (tl, tr, br, bl) = (rect[0], rect[1], rect[2], rect[3]);

    final widthA = sqrt(pow(br.x - bl.x, 2) + pow(br.y - bl.y, 2));
    final widthB = sqrt(pow(tr.x - tl.x, 2) + pow(tr.y - tl.y, 2));
    final maxWidth = max(widthA.toInt(), widthB.toInt());

    final heightA = sqrt(pow(tr.x - br.x, 2) + pow(tr.y - br.y, 2));
    final heightB = sqrt(pow(tl.x - bl.x, 2) + pow(tl.y - bl.y, 2));
    final maxHeight = max(heightA.toInt(), heightB.toInt());

    final dstPoints = [
      [0.0, 0.0], [maxWidth - 1.0, 0.0], [maxWidth - 1.0, maxHeight - 1.0], [0.0, maxHeight - 1.0]
    ].expand((p) => p).toList();
    final dst = cv.Mat.fromList(4, 2, cv.CV_32F, dstPoints);

    final srcPoints = [
      [tl.x.toDouble(), tl.y.toDouble()], [tr.x.toDouble(), tr.y.toDouble()],
      [br.x.toDouble(), br.y.toDouble()], [bl.x.toDouble(), bl.y.toDouble()]
    ].expand((p) => p).toList();
    final src = cv.Mat.fromList(4, 2, cv.CV_32F, srcPoints);

    final M = cv.getPerspectiveTransform(src, dst);
    return cv.warpPerspective(image, M, (maxWidth, maxHeight));
  }

  List<cv.Point> orderPoints(cv.VecPoint pts) {
    List<cv.Point> rect = List.generate(4, (_) => cv.Point(0, 0));
    List<cv.Point> points = pts.toList();

    points.sort((a, b) => (a.x + a.y).compareTo(b.x + b.y));
    rect[0] = points.first;
    rect[2] = points.last;

    points.removeWhere((p) => p == rect[0] || p == rect[2]);
    points.sort((a, b) => (a.y - a.x).compareTo(b.y - b.x));
    rect[1] = points.first;
    rect[3] = points.last;

    return rect;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifique a Foto')),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Preparando o classificador...')]));
          }
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Falha ao carregar o modelo de IA. Erro: ${snapshot.error}', textAlign: TextAlign.center)));
          }
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(widget.imagePath), fit: BoxFit.contain),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text('Analisando gabarito...', style: TextStyle(color: Colors.white, fontSize: 18, decoration: TextDecoration.none)),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _analisarEObterResultado,
        label: _isProcessing ? const Text("Aguarde...") : const Text("Corrigir Prova"),
        icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.check_circle),
      ),
    );
  }
}
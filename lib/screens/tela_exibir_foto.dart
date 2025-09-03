import 'dart:io';
import 'dart:typed_data'; // Necessário para os bytes da imagem
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv; // Importa o OpenCV
import '../models/prova.dart';
import '../services/classificador_service.dart'; // Importa o nosso serviço de IA
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

  // CORREÇÃO 1: Criamos uma variável para armazenar o Future da inicialização.
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // CORREÇÃO 2: Atribuímos o Future aqui. O FutureBuilder irá gerenciá-lo.
    _initializationFuture = _classificadorService.initialize();
  }

  @override
  void dispose() {
    _classificadorService.dispose();
    super.dispose();
  }

  // A sua função de análise está ótima e não precisou de correções na lógica.
  Future<void> _analisarEObterResultado() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final bytes = await File(widget.imagePath).readAsBytes();
      final imagemOriginal = cv.imdecode(bytes, cv.IMREAD_COLOR);
      final folhaCorrigida = imagemOriginal;
      final cinza = cv.cvtColor(folhaCorrigida, cv.COLOR_BGR2GRAY);
      final borrada = cv.gaussianBlur(cinza, (5, 5), 0);
      final (_, thresh) = cv.threshold(borrada, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU);
      final (contornos, _) = cv.findContours(thresh, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE);
      final List<cv.Rect> bolhasRects = [];
      for (var c in contornos) {
        final rect = cv.boundingRect(c);
        if (rect.width >= 20 && rect.height >= 20 && (rect.width / rect.height) >= 0.8 && (rect.width / rect.height) <= 1.2) {
          bolhasRects.add(rect);
        }
      }

      if (bolhasRects.isEmpty || bolhasRects.length % 5 != 0) {
        throw Exception("Não foi possível encontrar um número válido de bolhas (${bolhasRects.length} encontradas).");
      }

      bolhasRects.sort((a, b) => a.y.compareTo(b.y));
      final Map<String, String> respostasDoAluno = {};
      final alternativas = ['A', 'B', 'C', 'D', 'E'];

      for (int i = 0; i < bolhasRects.length; i += 5) {
        final linha = bolhasRects.sublist(i, i + 5);
        linha.sort((a, b) => a.x.compareTo(b.x));
        int pixelsPreenchidos = -1;
        int? bolhaMarcadaIndex;
        Uint8List? bytesCandidato;

        for (int j = 0; j < linha.length; j++) {
          final rect = linha[j];
          final bolhaROI = folhaCorrigida.region(rect);
          final bolhaCinza = cv.cvtColor(bolhaROI, cv.COLOR_BGR2GRAY);
          final (_, bolhaThresh) = cv.threshold(bolhaCinza, 0, 255, cv.THRESH_BINARY_INV | cv.THRESH_OTSU);
          final total = cv.countNonZero(bolhaThresh);

          if (total > pixelsPreenchidos) {
            pixelsPreenchidos = total;
            bolhaMarcadaIndex = j;
            final (_, buf) = cv.imencode(".jpg", bolhaROI);
            bytesCandidato = buf;
          }
        }

        String resultadoIA = "vazia";
        if (bytesCandidato != null) {
          resultadoIA = await _classificadorService.classificarBolha(bytesCandidato);
        }

        final numeroQuestao = (i ~/ 5) + 1;
        respostasDoAluno[numeroQuestao.toString()] = (resultadoIA == 'marcada') ? alternativas[bolhaMarcadaIndex!] : 'N/A';
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
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro na análise: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifique a Foto')),
      // CORREÇÃO 3: Usamos o FutureBuilder para gerenciar o estado da inicialização.
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          // Caso 1: Enquanto o Future está rodando (carregando o modelo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Preparando o classificador...'),
                ],
              ),
            );
          }

          // Caso 2: Se o Future terminou com um erro
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Falha ao carregar o modelo de IA. Erro: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          // Caso 3: O Future terminou com sucesso. Mostramos a tela principal.
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(widget.imagePath), fit: BoxFit.contain),
              if (_isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          'Analisando gabarito...',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              decoration: TextDecoration.none),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      // O botão só será construído e estará disponível após a inicialização bem-sucedida.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isProcessing ? null : _analisarEObterResultado,
        label: _isProcessing ? const Text("Aguarde...") : const Text("Corrigir Prova"),
        icon: _isProcessing ? const SizedBox.shrink() : const Icon(Icons.check_circle),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/correcao.dart';
import '../models/prova.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DetalheQuestao {
  final int numeroQuestao;
  final String respostaAluno;
  final String respostaCorreta;
  final bool acertou;

  DetalheQuestao({
    required this.numeroQuestao,
    required this.respostaAluno,
    required this.respostaCorreta,
    required this.acertou,
  });
}

class TelaResultado extends StatefulWidget {
  final Prova prova;
  final String nomeAluno;
  final VoidCallback onDadosAlterados;
  final Map<String, String> respostasAluno;
  final Map<String, String> gabaritoMestre;
  final int totalQuestoes;

  const TelaResultado({
    super.key,
    required this.respostasAluno,
    required this.gabaritoMestre,
    required this.totalQuestoes,
    required this.prova,
    required this.nomeAluno,
    required this.onDadosAlterados,
  });

  @override
  State<TelaResultado> createState() => _TelaResultadoState();
}

class _TelaResultadoState extends State<TelaResultado> {
  bool _correcaoJaSalva = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _salvarCorrecao());
  }

  void _salvarCorrecao() {
    if (_correcaoJaSalva) return;

    final resultado = _calcularResultado();
    final novaCorrecao = Correcao(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nomeAluno: widget.nomeAluno,
      respostas: widget.respostasAluno,
      acertos: resultado['acertos'],
      nota: resultado['nota'],
      data: DateTime.now(),
    );

    widget.prova.correcoes.add(novaCorrecao);
    setState(() {
      _correcaoJaSalva = true;
    });

    widget.onDadosAlterados();
  }

  Map<String, dynamic> _calcularResultado() {
    if (widget.gabaritoMestre.isEmpty) {
      return {'acertos': 0, 'nota': 0.0};
    }
    int acertos = 0;
    widget.gabaritoMestre.forEach((chaveQuestao, respostaCorreta) {
      if (widget.respostasAluno.containsKey(chaveQuestao) &&
          widget.respostasAluno[chaveQuestao] == respostaCorreta) {
        acertos++;
      }
    });
    double nota = (widget.gabaritoMestre.isNotEmpty)
        ? (acertos / widget.gabaritoMestre.length) * 10
        : 0.0;
    return {'acertos': acertos, 'nota': nota};
  }

  List<DetalheQuestao> _gerarDetalhesDaCorrecao() {
    final List<DetalheQuestao> detalhes = [];
    for (int i = 1; i <= widget.totalQuestoes; i++) {
      final String chaveQuestao = i.toString();
      final String respostaAluno = widget.respostasAluno[chaveQuestao] ?? 'N/A';
      final String respostaCorreta = widget.gabaritoMestre[chaveQuestao] ?? '-';
      final bool acertou = respostaAluno == respostaCorreta && respostaAluno != 'N/A';
      detalhes.add(
        DetalheQuestao(
          numeroQuestao: i,
          respostaAluno: respostaAluno,
          respostaCorreta: respostaCorreta,
          acertou: acertou,
        ),
      );
    }
    return detalhes;
  }

  Future<void> _exportarResultados(BuildContext context, List<DetalheQuestao> detalhes) async {
    List<List<dynamic>> linhas = [];
    linhas.add(["Numero da Questao", "Sua Resposta", "Gabarito", "Resultado"]);
    for (var detalhe in detalhes) {
      linhas.add([
        detalhe.numeroQuestao,
        detalhe.respostaAluno,
        detalhe.respostaCorreta,
        detalhe.acertou ? "Certo" : "Errado"
      ]);
    }
    String csv = const ListToCsvConverter().convert(linhas);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path =
          "${directory.path}/correcao_${widget.nomeAluno.replaceAll(' ', '_')}.csv";
      final file = File(path);
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(path)],
          text: 'Correção de ${widget.nomeAluno}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Erro ao exportar: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resultado = _calcularResultado();
    final int acertos = resultado['acertos'];
    final double nota = resultado['nota'];
    final List<DetalheQuestao> detalhesCorrecao = _gerarDetalhesDaCorrecao();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Correção'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: () {
              // Envia o sinal "true" para iniciar a reação em cadeia de retorno
              Navigator.popUntil(context, ModalRoute.withName('/telaDaProva'));
            },
            icon: const Icon(Icons.check_circle),
            label: const Text('CONCLUIR'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('NOTA',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold)),
                Text(nota.toStringAsFixed(1),
                    style: TextStyle(
                        fontSize: 52,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('ACERTOS',
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey.shade600)),
                Text('$acertos / ${widget.gabaritoMestre.length}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(thickness: 1.5),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 80.0),
              itemCount: detalhesCorrecao.length,
              itemBuilder: (context, index) {
                final detalhe = detalhesCorrecao[index];
                final Color corResultado;
                final IconData iconeResultado;
                if (detalhe.respostaAluno == 'N/A') {
                  corResultado = Colors.grey;
                  iconeResultado = Icons.remove_circle_outline;
                } else if (detalhe.acertou) {
                  corResultado = Colors.green.shade700;
                  iconeResultado = Icons.check_circle;
                } else {
                  corResultado = Colors.red.shade700;
                  iconeResultado = Icons.cancel;
                }
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: corResultado,
                      child: Text(detalhe.numeroQuestao.toString(),
                          style: const TextStyle(color: Color.fromARGB(255, 0, 0, 0))),
                    ),
                    title: Text('Sua resposta: ${detalhe.respostaAluno}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Gabarito: ${detalhe.respostaCorreta}'),
                    trailing: Icon(iconeResultado, color: corResultado),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _exportarResultados(context, detalhesCorrecao);
        },
        label: const Text("Exportar CSV"),
        icon: const Icon(Icons.download),
      ),
    );
  }
}
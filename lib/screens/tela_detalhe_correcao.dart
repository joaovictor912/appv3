import 'package:flutter/material.dart';
import '../models/correcao.dart';
import 'tela_resultado.dart';

class TelaDetalheCorrecao extends StatelessWidget {
  final Correcao correcao;
  final Map<String, String> gabaritoMestre;
  final int totalQuestoes;

  const TelaDetalheCorrecao({
    super.key,
    required this.correcao,
    required this.gabaritoMestre,
    required this.totalQuestoes,
  });

  List<DetalheQuestao> _gerarDetalhesDaCorrecao() {
    final List<DetalheQuestao> detalhes = [];
    for (int i = 1; i <= totalQuestoes; i++) {
      final String chaveQuestao = i.toString();
      final String respostaAluno = correcao.respostas[chaveQuestao] ?? 'N/A';
      final String respostaCorreta = gabaritoMestre[chaveQuestao] ?? '-';
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

  @override
  Widget build(BuildContext context) {
    final List<DetalheQuestao> detalhesCorrecao = _gerarDetalhesDaCorrecao();

    return Scaffold(
      appBar: AppBar(
        title: Text('Correção de ${correcao.nomeAluno}'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('NOTA', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                Text(correcao.nota.toStringAsFixed(1), style: TextStyle(fontSize: 52, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text('ACERTOS', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                Text('${correcao.acertos} / $totalQuestoes', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const Divider(thickness: 1.5, indent: 16, endIndent: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
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
                      child: Text(detalhe.numeroQuestao.toString(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text('Sua resposta: ${detalhe.respostaAluno}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Gabarito: ${detalhe.respostaCorreta}'),
                    trailing: Icon(iconeResultado, color: corResultado),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/prova.dart';

class TelaGabaritoMestre extends StatefulWidget {
  final Prova prova;
  // MUDANÇA 1: Adicionamos o callback.
  final VoidCallback onGabaritoSalvo;

  const TelaGabaritoMestre({
    super.key,
    required this.prova,
    required this.onGabaritoSalvo, // MUDANÇA 2: Tornamos obrigatório.
  });

  @override
  State<TelaGabaritoMestre> createState() => _TelaGabaritoMestreState();
}

class _TelaGabaritoMestreState extends State<TelaGabaritoMestre> {
  late Map<String, String> _respostas;
  final List<String> _alternativas = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    _respostas = Map.from(widget.prova.gabaritoOficial);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gabarito: ${widget.prova.nome}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              setState(() {
                widget.prova.gabaritoOficial = _respostas;
              });

              // MUDANÇA 3: Chamamos a função de callback.
              widget.onGabaritoSalvo();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gabarito salvo com sucesso!')),
              );
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: ListView.builder(
        // O resto do código continua o mesmo...
        itemCount: widget.prova.numeroDeQuestoes,
        itemBuilder: (context, index) {
          final int numeroQuestao = index + 1;
          final String chaveQuestao = numeroQuestao.toString();
          
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Questão $numeroQuestao',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _alternativas.map((alternativa) {
                      return Column(
                        children: [
                          Text(alternativa),
                          Radio<String>(
                            value: alternativa,
                            groupValue: _respostas[chaveQuestao],
                            onChanged: (String? valor) {
                              setState(() {
                                _respostas[chaveQuestao] = valor!;
                              });
                            },
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/prova.dart';
import '../models/turma.dart';
import '../services/database_service.dart';
import 'tela_da_prova.dart';
import 'tela_gabarito_mestre.dart';
import 'tela_gerir_alunos.dart';

class TelaDaTurma extends StatefulWidget {
  // MUDANÇA 1: Agora recebemos apenas o ID da turma.
  final int turmaId;
  final CameraDescription camera;
  final VoidCallback onDadosAlterados;

  const TelaDaTurma({
    super.key,
    required this.turmaId,
    required this.camera,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaTurma> createState() => _TelaDaTurmaState();
}

class _TelaDaTurmaState extends State<TelaDaTurma> {
  // MUDANÇA 2: A função de diálogo agora precisa receber o objeto 'turma'
  // como parâmetro, pois ele não está mais disponível em 'widget.turma'.
  void _mostrarDialogoNovaProva(Turma turma) {
    final TextEditingController nomeController = TextEditingController();
    final TextEditingController questoesController = TextEditingController();
    DateTime dataSelecionada = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nova Prova'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomeController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nome da Prova'),
                  ),
                  TextField(
                    controller: questoesController,
                    decoration: const InputDecoration(labelText: 'Nº de Questões'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('Data: '),
                      Text(
                        DateFormat('dd/MM/yyyy').format(dataSelecionada),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final dataEscolhida = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (dataEscolhida != null) {
                            setDialogState(() => dataSelecionada = dataEscolhida);
                          }
                        },
                      ),
                    ],
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nomeController.text.isNotEmpty) {
                      final int numeroDeQuestoes = int.tryParse(questoesController.text) ?? 10;
                      final novaProva = Prova(
                        nome: nomeController.text,
                        data: DateFormat('dd/MM/yyyy').format(dataSelecionada),
                        numeroDeQuestoes: numeroDeQuestoes,
                      );

                      // Usa o ID da turma recebido como parâmetro.
                      await DatabaseService.instance.createProva(novaProva, turma.id!);
                      
                      if (!mounted) return;
                      Navigator.pop(context);
                      
                      // Força a reconstrução da tela para o FutureBuilder buscar a nova lista.
                      setState(() {});
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // MUDANÇA 3: O widget inteiro agora é um FutureBuilder que busca a turma pelo ID.
    return FutureBuilder<Turma>(
      future: DatabaseService.instance.getTurmaById(widget.turmaId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(), body: Center(child: Text("Erro: ${snapshot.error}")));
        }
        if (!snapshot.hasData) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text("Turma não encontrada.")));
        }

        // A partir daqui, temos o objeto 'turma' sempre fresco e atualizado.
        final turma = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(turma.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add_outlined),
                tooltip: 'Gerir Alunos',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaGerirAlunos(
                        turma: turma, // Passa o objeto 'turma' fresco
                        onDadosAlterados: () {
                          setState(() {}); // Força a atualização ao voltar
                          widget.onDadosAlterados(); // Notifica a tela principal
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            // Usa a lista de provas do objeto 'turma' recém-buscado
            itemCount: turma.provas.length,
            itemBuilder: (context, index) {
              final prova = turma.provas[index];
              return Dismissible(
                key: Key(prova.id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.redAccent,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: const Icon(Icons.delete_sweep, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  await DatabaseService.instance.deleteProva(prova.id!);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${prova.nome}" removida')),
                  );
                  setState(() {});
                },
                child: Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.article_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                    title: Text(prova.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${prova.correcoes.length} correções • ${prova.numeroDeQuestoes} questões"),
                    trailing: IconButton(
                      icon: const Icon(Icons.playlist_add_check),
                      tooltip: 'Editar Gabarito',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaGabaritoMestre(
                              prova: prova,
                              onGabaritoSalvo: () => setState(() {}),
                            ),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TelaDaProva(
                            turma: turma, // Passa o objeto 'turma' fresco
                            prova: prova,
                            camera: widget.camera,
                            onDadosAlterados: () => setState(() {}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _mostrarDialogoNovaProva(turma), // Passa a turma para o diálogo
            label: const Text('Nova Prova'),
            icon: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
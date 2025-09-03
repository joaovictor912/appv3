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
  final Turma turma;
  final CameraDescription camera;
  final VoidCallback onDadosAlterados;

  const TelaDaTurma({
    super.key,
    required this.turma,
    required this.camera,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaTurma> createState() => _TelaDaTurmaState();
}

class _TelaDaTurmaState extends State<TelaDaTurma> {
  // Função para criar uma nova prova, agora salvando no banco de dados.
  void _mostrarDialogoNovaProva() {
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
                          final DateTime? dataEscolhida = await showDatePicker(
                            context: context,
                            initialDate: dataSelecionada,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (dataEscolhida != null) {
                            setDialogState(() {
                              dataSelecionada = dataEscolhida;
                            });
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

                      // Salva a nova prova no banco, associada ao ID da turma atual
                      await DatabaseService.instance.createProva(novaProva, widget.turma.id!);
                      
                      // Atualiza a tela para o FutureBuilder buscar a nova lista
                      setState(() {});
                      
                      Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.turma.nome),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            tooltip: 'Gerir Alunos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TelaGerirAlunos(
                    turma: widget.turma,
                    onDadosAlterados: widget.onDadosAlterados,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Prova>>(
        // O FutureBuilder agora é a fonte de dados, buscando direto do banco
        future: DatabaseService.instance.getProvasParaTurma(widget.turma.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar provas: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma prova cadastrada.\nClique em '+' para adicionar a primeira.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final provas = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: provas.length,
            itemBuilder: (context, index) {
              final prova = provas[index];
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
                  final nomeProvaRemovida = prova.nome;
                  // Deleta a prova permanentemente do banco de dados
                  await DatabaseService.instance.deleteProva(prova.id!);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$nomeProvaRemovida" removida')),
                  );
                  // Atualiza o estado para garantir que a lista seja recarregada
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
                              // O callback aqui pode ser usado para forçar um setState na volta
                              onGabaritoSalvo: () => setState((){}), 
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
                            turma: widget.turma,
                            prova: prova,
                            camera: widget.camera,
                            onDadosAlterados: () => setState((){}),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovaProva,
        label: const Text('Nova Prova'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
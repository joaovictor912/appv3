import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../models/turma.dart';
import '../services/database_service.dart';
import 'tela_da_turma.dart';

class TelaPrincipal extends StatefulWidget {
  final CameraDescription camera;
  const TelaPrincipal({super.key, required this.camera});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  void _mostrarDialogoTurma({Turma? turmaExistente}) {
    final bool isEditing = turmaExistente != null;
    final nomeController = TextEditingController(text: isEditing ? turmaExistente!.nome : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar Turma' : 'Nova Turma'),
          content: TextField(
            controller: nomeController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Nome da Turma'),
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = nomeController.text;
                if (nome.isNotEmpty) {
                  if (isEditing) {
                    final turmaAtualizada = turmaExistente!.copy(nome: nome);
                    await DatabaseService.instance.updateTurma(turmaAtualizada);
                  } else {
                    await DatabaseService.instance.createTurma(nome);
                  }
                  
                  if (!mounted) return;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Turmas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () async {
              // Sua lógica de logout com confirmação pode ser inserida aqui
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirmar Saída'),
                  content: const Text('Deseja realmente sair?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Não')),
                    TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sim')),
                  ],
                )
              );
              
              if (confirmar == true) {
                await FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Turma>>(
  future: DatabaseService.instance.getTurmas(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return Center(child: Text("Erro ao carregar turmas: ${snapshot.error}"));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma turma cadastrada.\nClique no botão + para adicionar.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final turmas = snapshot.data!;
    
    // 1. Envolvemos a lista toda com AnimationLimiter
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: turmas.length,
        itemBuilder: (context, index) {
          final turma = turmas[index];

          // 2. Dentro do itemBuilder, envolvemos o item com a configuração da animação
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation( // 3. Aplicamos os efeitos de deslizar...
              verticalOffset: 50.0,
              child: FadeInAnimation( // 4. ...e de surgir (fade).
                child: Dismissible( // O seu código original começa aqui
                  key: Key(turma.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: const Icon(Icons.delete_sweep, color: Colors.white),
                  ),
                  onDismissed: (direction) async {
                    await DatabaseService.instance.deleteTurma(turma.id!);
                    setState(() {});
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${turma.nome} removida')),
                    );
                  },
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        child: Text(turma.nome.isNotEmpty ? turma.nome.substring(0, 1).toUpperCase() : '?'),
                      ),
                      title: Text(turma.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${turma.numeroDeAlunos} alunos • ${turma.provas.length} provas"),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                        onPressed: () => _mostrarDialogoTurma(turmaExistente: turma),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaDaTurma(
                              turmaId: turma.id!,
                              camera: widget.camera,
                              onDadosAlterados: () => setState(() {}),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  },
),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoTurma,
        tooltip: 'Adicionar Turma',
        child: const Icon(Icons.add),
      ),
    );
  }
}
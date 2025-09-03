import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/turma.dart';

class TelaGerirAlunos extends StatefulWidget {
  final Turma turma;
  final VoidCallback onDadosAlterados;

  const TelaGerirAlunos({
    super.key, 
    required this.turma, 
    required this.onDadosAlterados
  });

  @override
  State<TelaGerirAlunos> createState() => _TelaGerirAlunosState();
}

class _TelaGerirAlunosState extends State<TelaGerirAlunos> {

  void _removerAluno(Aluno alunoParaRemover) {
    setState(() {
      widget.turma.alunos.removeWhere((aluno) => aluno.id == alunoParaRemover.id);
    });
    widget.onDadosAlterados();
  }

  void _mostrarDialogoNovoAluno() {
    final nomeController = TextEditingController();
    final matriculaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo Aluno'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                autofocus: true,
                style: const TextStyle(color: Colors.black),
                decoration: const InputDecoration(hintText: 'Nome do Aluno'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: matriculaController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'ID / Matrícula do Aluno'),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nomeController.text.isNotEmpty && matriculaController.text.isNotEmpty) {
                final novoAluno = Aluno(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nome: nomeController.text,
                  matricula: matriculaController.text,
                );

                setState(() {
                  widget.turma.alunos.add(novoAluno);
                });
                
                widget.onDadosAlterados();
                Navigator.pop(context);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cria uma cópia ordenada da lista de alunos para exibição.
    final alunosOrdenados = List<Aluno>.from(widget.turma.alunos);
    alunosOrdenados.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos de "${widget.turma.nome}"'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Importar Alunos (CSV)',
            onPressed: () {
              // A lógica de importação _importarAlunosDeCsv() seria chamada aqui.
              // Implementação futura.
            },
          ),
        ],
      ),
      body: alunosOrdenados.isEmpty
        ? const Center(
            child: Text(
              'Nenhum aluno cadastrado.\nClique no botão "+" para adicionar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          )
        : ListView.builder(
            itemCount: alunosOrdenados.length,
            itemBuilder: (context, index) {
              final aluno = alunosOrdenados[index];
              return ListTile(
                title: Text(aluno.nome),
                subtitle: Text("Matrícula: ${aluno.matricula}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removerAluno(aluno),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoNovoAluno,
        label: const Text('Novo Aluno'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
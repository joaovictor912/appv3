import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/turma.dart';
import '../services/database_service.dart';

class TelaGerirAlunos extends StatefulWidget {
  final Turma turma;
  final VoidCallback onDadosAlterados;

  const TelaGerirAlunos({
    super.key,
    required this.turma,
    required this.onDadosAlterados,
  });

  @override
  State<TelaGerirAlunos> createState() => _TelaGerirAlunosState();
}

class _TelaGerirAlunosState extends State<TelaGerirAlunos> {
  // Função para adicionar um novo aluno, agora salvando no banco de dados.
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
                decoration: const InputDecoration(hintText: 'Nome do Aluno'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: matriculaController,
                decoration: const InputDecoration(hintText: 'ID / Matrícula do Aluno'),
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty && matriculaController.text.isNotEmpty) {
                // 1. Cria o objeto Aluno SEM o ID (o banco vai gerar)
                final novoAluno = Aluno(
                  nome: nomeController.text,
                  matricula: matriculaController.text,
                );

                // 2. Chama o DatabaseService para salvar o aluno
                await DatabaseService.instance.createAluno(novoAluno, widget.turma.id!);
                
                // 3. Notifica a tela anterior que houve uma mudança
                widget.onDadosAlterados();

                // 4. Apenas atualiza a tela para o FutureBuilder recarregar a lista
                setState(() {});
                
                if (!mounted) return; // Verificação de segurança
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Alunos de "${widget.turma.nome}"'),
        actions: [
          // Seu botão de importar CSV pode continuar aqui
        ],
      ),
      // O corpo agora é um FutureBuilder que busca os alunos da turma no banco
      body: FutureBuilder<List<Aluno>>(
        future: DatabaseService.instance.getAlunosParaTurma(widget.turma.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro ao carregar alunos: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum aluno cadastrado.\nClique no botão "+" para adicionar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final alunos = snapshot.data!;
          // Ordena a lista de alunos para exibição
          alunos.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));

          return ListView.builder(
            itemCount: alunos.length,
            itemBuilder: (context, index) {
              final aluno = alunos[index];
              return ListTile(
                title: Text(aluno.nome),
                subtitle: Text("Matrícula: ${aluno.matricula}"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    // Deleta o aluno diretamente do banco de dados
                    await DatabaseService.instance.deleteAluno(aluno.id!);
                    widget.onDadosAlterados();
                    setState(() {}); // Atualiza a tela para recarregar a lista
                  },
                ),
              );
            },
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
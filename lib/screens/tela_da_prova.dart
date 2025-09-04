import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/aluno.dart';
import '../models/prova.dart';
import '../models/turma.dart';
import '../services/database_service.dart'; // Importa o nosso serviço
import 'tela_da_camera.dart';
import 'tela_lista_correcoes.dart';

class TelaDaProva extends StatefulWidget {
  final Turma turma; // Adiciona a turma aqui
  final Prova prova;
  final CameraDescription camera;
  final VoidCallback onDadosAlterados;

  const TelaDaProva({
    super.key,
    required this.turma, // Torna a turma um parâmetro obrigatório
    required this.prova,
    required this.camera,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaProva> createState() => _TelaDaProvaState();
}

class _TelaDaProvaState extends State<TelaDaProva> {

  Future<void> _iniciarCorrecao() async {
        final alunosDaTurma = await DatabaseService.instance.getAlunosParaTurma(widget.turma.id!);

    // 2. VERIFICA SE A LISTA RECENTE ESTÁ VAZIA
    if (alunosDaTurma.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adicione alunos à turma primeiro!")),
      );
      return;
    }

    // 3. O RESTANTE DA LÓGICA AGORA USA A LISTA 'alunosDaTurma', GARANTINDO DADOS ATUALIZADOS
    final nomesCorrigidos = widget.prova.correcoes.map((c) => c.nomeAluno).toSet();
    final alunosParaCorrigir = alunosDaTurma.where((aluno) => !nomesCorrigidos.contains(aluno.nome)).toList();

    if (alunosParaCorrigir.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Todos os alunos já foram corrigidos!")),
      );
      return;
    }
    
    if (!mounted) return;
    final Aluno? alunoSelecionado = await showDialog<Aluno>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecionar Aluno'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: alunosParaCorrigir.length,
            itemBuilder: (context, index) {
              final aluno = alunosParaCorrigir[index];
              return ListTile(
                title: Text(aluno.nome),
                onTap: () => Navigator.pop(context, aluno),
              );
            },
          ),
        ),
      ),
    );

    if (alunoSelecionado != null) {
      if (!mounted) return;
      final resultadoNavegacao = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => TelaDaCamera(
            prova: widget.prova,
            camera: widget.camera,
            nomeAluno: alunoSelecionado.nome,
            onDadosAlterados: widget.onDadosAlterados,
          ),
        ),
      );
      if (resultadoNavegacao == true) {
        setState(() {});
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prova.nome),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Nova Correção'),
                onPressed: _iniciarCorrecao,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                icon: const Icon(Icons.history),
                label: Text('Ver Correções (${widget.prova.correcoes.length})'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TelaListaCorrecoes(prova: widget.prova),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
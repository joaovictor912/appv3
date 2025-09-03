import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaRegisto extends StatefulWidget {
  const TelaRegisto({super.key});
  @override
  State<TelaRegisto> createState() => _TelaRegistoState();
}

class _TelaRegistoState extends State<TelaRegisto> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _registar() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cria o utilizador no Firebase Auth
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );
      // Se o registo for bem-sucedido, volta para a tela de login
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      print("ERRO DE REGISTO: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? "Ocorreu um erro desconhecido."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Criar Conta")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senhaController,
                decoration: const InputDecoration(
                  labelText: 'Senha (mínimo 6 caracteres)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      )
                    : const Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
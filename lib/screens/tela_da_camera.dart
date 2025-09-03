import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../models/prova.dart';
import 'tela_exibir_foto.dart';

class TelaDaCamera extends StatefulWidget {
  final Prova prova;
  final CameraDescription camera;
  final String nomeAluno;
  final VoidCallback onDadosAlterados;

  const TelaDaCamera({
    super.key,
    required this.camera,
    required this.prova,
    required this.nomeAluno,
    required this.onDadosAlterados,
  });

  @override
  State<TelaDaCamera> createState() => _TelaDaCameraState();
}

class _TelaDaCameraState extends State<TelaDaCamera> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  FlashMode _currentFlashMode = FlashMode.torch;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.setFlashMode(_currentFlashMode);
      _controller.setFocusMode(FocusMode.auto);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    setState(() {
      _currentFlashMode = _currentFlashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
      _controller.setFlashMode(_currentFlashMode);
    });
  }

  IconData _getFlashIcon() {
    return _currentFlashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alinhe o Gabarito'),
        backgroundColor: Color(0xFF00295B),
      ),
      backgroundColor: Color(0xFF00295B),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                _buildOverlayGuide(),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _buildControlBar(),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildOverlayGuide() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 2.0),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_getFlashIcon(), color: Colors.white, size: 30),
            onPressed: _toggleFlash,
          ),
          FloatingActionButton(
            onPressed: () async {
              try {
                await _initializeControllerFuture;
                final image = await _controller.takePicture();
                if (!mounted) return;

                // Espera por um resultado booleano das próximas telas.
                final bool? correcaoConcluida = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (context) => TelaExibirFoto(
                      imagePath: image.path,
                      prova: widget.prova,
                      nomeAluno: widget.nomeAluno,
                      onDadosAlterados: widget.onDadosAlterados,
                    ),
                  ),
                );

                // Se o resultado for 'true', fecha esta tela também.
                if (correcaoConcluida == true) {
                  if(mounted) Navigator.of(context).pop(true);
                }

              } catch (e) {
                print(e);
              }
            },
            child: const Icon(Icons.camera_alt),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
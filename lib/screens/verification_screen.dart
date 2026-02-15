import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../services/face_detector_service.dart';
import '../services/api_service.dart';

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _processingFrame = false;
  bool _verificando = false;
  bool _faceDetected = false;
  String? _nombreReconocido;
  String? _errorMensaje;
  XFile? _fotoCapturada;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _controller = CameraController(
        cameras[1], // Cámara frontal
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21, // Importante para Android
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);

      _startImageStream();
    } catch (e) {
        print('Error inicializando cámara: $e');
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      if (_processingFrame || _verificando || _faceDetected) return;
      _processingFrame = true;

      try {
        final detected = await _faceDetector.detectFaceFromCameraImage(image);

        if (detected && !_faceDetected && !_verificando) {
          _faceDetected = true;
          if (mounted) setState(() {}); // Mostrar que detectó rostro
          await _stopStreamAndVerify();
        }
      } catch (e) {
        print('Error en stream: $e');
      } finally {
        _processingFrame = false;
      }
    });
  }

  Future<void> _stopStreamAndVerify() async {
    try {
      // Detener stream
      await _controller?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));

      // Capturar foto
      final picture = await _controller?.takePicture();
      if (picture == null) {
        _reiniciarEscaneo();
        return;
      }

      if (mounted) {
        setState(() {
          _fotoCapturada = picture;
          _verificando = true;
          _errorMensaje = null;
        });
      }

      // Llamar a la API
      final respuesta = await _apiService.verificarIdentidad(
        imagenPath: picture.path,
      );

      if (!mounted) return;

      if (respuesta['exito'] == true) {
        final data = respuesta['data'];

        if (data['verificado'] == true) {
          // ✅ Persona encontrada
          setState(() {
            _verificando = false;
            _nombreReconocido = data['persona']['nombre'];
          });

          // Volver a escanear después de 3 segundos
          Future.delayed(const Duration(seconds: 3), _reiniciarEscaneo);
        } else {
          // ❌ No encontrado
          setState(() {
            _verificando = false;
            _errorMensaje = 'Rostro no reconocido';
          });
          Future.delayed(const Duration(seconds: 2), _reiniciarEscaneo);
        }
      } else {
        // Error de red o servidor
        setState(() {
          _verificando = false;
          _errorMensaje = respuesta['error'] ?? 'Error al conectar';
        });
        Future.delayed(const Duration(seconds: 3), _reiniciarEscaneo);
      }
    } catch (e) {
      print('Error en verificación: $e');
      if (mounted) {
        setState(() {
          _verificando = false;
          _errorMensaje = 'Error inesperado';
        });
        Future.delayed(const Duration(seconds: 2), _reiniciarEscaneo);
      }
    }
  }

  void _reiniciarEscaneo() {
    if (!mounted) return;
    setState(() {
      _verificando = false;
      _faceDetected = false;
      _nombreReconocido = null;
      _errorMensaje = null;
      _fotoCapturada = null;
      _processingFrame = false;
    });
    _startImageStream();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? Stack(
              fit: StackFit.expand,
              children: [
                // ── Fondo: cámara o foto capturada ──
                _fotoCapturada != null
                    ? Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover)
                    : CameraPreview(_controller!),

                // ── Marco de detección ──
                _buildMarcoDeteccion(),

                // ── Texto superior ──
                _buildTextoSuperior(),

                // ── Overlay de loading (verificando) ──
                if (_verificando) _buildLoadingOverlay(),

                // ── Resultado: reconocido ──
                if (_nombreReconocido != null && !_verificando)
                  _buildResultadoExito(),

                // ── Resultado: no reconocido / error ──
                if (_errorMensaje != null && !_verificando)
                  _buildResultadoError(),

                // ── Botón volver ──
                Positioned(
                  top: 48,
                  left: 16,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }

  // ── Marco animado de detección ──
  Widget _buildMarcoDeteccion() {
    final color = _faceDetected ? Colors.green : Colors.white54;
    return Center(
      child: Container(
        width: 220,
        height: 280,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2.5),
          borderRadius: BorderRadius.circular(120),
        ),
      ),
    );
  }

  // ── Texto superior según estado ──
  Widget _buildTextoSuperior() {
    String texto;
    Color color;

    if (_verificando) {
      texto = 'Procesando...';
      color = Colors.white;
    } else if (_faceDetected &&
        _nombreReconocido == null &&
        _errorMensaje == null) {
      texto = 'Rostro detectado ✓';
      color = Colors.greenAccent;
    } else if (_nombreReconocido != null) {
      texto = '';
      color = Colors.transparent;
    } else if (_errorMensaje != null) {
      texto = '';
      color = Colors.transparent;
    } else {
      texto = 'Coloca tu rostro en el marco';
      color = Colors.white;
    }

    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          texto,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
          ),
        ),
      ),
    );
  }

  // ── Loading overlay ──
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              'Verificando identidad...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Por favor espera',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resultado exitoso ──
  Widget _buildResultadoExito() {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade800.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_user, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            const Text(
              'Bienvenido',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              _nombreReconocido!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Resultado error / no encontrado ──
  Widget _buildResultadoError() {
    final esNoReconocido = _errorMensaje == 'Rostro no reconocido';

    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: (esNoReconocido ? Colors.red.shade800 : Colors.orange.shade800)
              .withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: esNoReconocido ? Colors.redAccent : Colors.orangeAccent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esNoReconocido ? Icons.person_off : Icons.wifi_off,
              color: Colors.white,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMensaje!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Reintentando...',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

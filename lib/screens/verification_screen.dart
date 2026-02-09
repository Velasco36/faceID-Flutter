import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/face_detector_service.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final FaceDetectorService _faceDetector = FaceDetectorService();
  String _verificationResult = 'Esperando...';
  Color _resultColor = Colors.grey;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(cameras[1], ResolutionPreset.medium);

    await _controller!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  Future<void> _verifyFace() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _verificationResult = 'Verificando...';
      _resultColor = Colors.orange;
    });

    try {
      // Capturar imagen actual
      final image = await _controller!.takePicture();

      // Detectar rostro en la imagen capturada
      final currentFaceData = await _faceDetector.detectFace(image.path);

      if (currentFaceData == null) {
        setState(() {
          _verificationResult = 'No se detectó rostro';
          _resultColor = Colors.red;
          _isProcessing = false;
        });
        return;
      }

      // Obtener datos guardados
      final prefs = await SharedPreferences.getInstance();
      final registeredName = prefs.getString('registered_name');
      final savedFaceData = prefs.getString('face_data');

      if (registeredName == null || savedFaceData == null) {
        setState(() {
          _verificationResult = 'No hay persona registrada';
          _resultColor = Colors.red;
          _isProcessing = false;
        });
        return;
      }

      // Comparar rostros
      final isMatch = _faceDetector.compareFaces(
        savedFaceData,
        currentFaceData,
      );

      setState(() {
        if (isMatch) {
          _verificationResult = '✓ Es $registeredName';
          _resultColor = Colors.green;
        } else {
          _verificationResult = '✗ No es $registeredName';
          _resultColor = Colors.red;
        }
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _verificationResult = 'Error en verificación';
        _resultColor = Colors.red;
        _isProcessing = false;
      });
      print('Error: $e');
    }
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
      appBar: AppBar(title: const Text('Verificar Persona')),
      body: _isCameraInitialized
          ? Column(
              children: [
                Expanded(child: CameraPreview(_controller!)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: _resultColor.withOpacity(0.2),
                  child: Text(
                    _verificationResult,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _resultColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _verifyFace,
                    icon: const Icon(Icons.face_retouching_natural),
                    label: Text(
                      _isProcessing ? 'Procesando...' : 'Verificar Rostro',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

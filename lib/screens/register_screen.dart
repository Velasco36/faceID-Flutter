import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../main.dart';
import '../services/face_detector_service.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  CameraController? _controller;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  bool _isCameraInitialized = false;
  bool _isLoading = false;
  XFile? _capturedImage;
  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      cameras[1], // Cámara frontal
      ResolutionPreset.medium,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final image = await _controller!.takePicture();

      // Detectar rostro localmente antes de enviar
      final faceData = await _faceDetector.detectFace(image.path);

      if (faceData == null) {
        if (mounted) {
          _mostrarSnackbar(
            'No se detectó ningún rostro. Intenta con mejor iluminación.',
            error: true,
          );
        }
        return;
      }

      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      _mostrarSnackbar('Error al tomar foto: $e', error: true);
    }
  }

  Future<void> _saveRegistration() async {
    final nombre = _nameController.text.trim();
    final cedula = _cedulaController.text.trim();

    // Validaciones locales
    if (_capturedImage == null) {
      _mostrarSnackbar('Toma una foto primero', error: true);
      return;
    }
    if (nombre.isEmpty) {
      _mostrarSnackbar('El nombre es requerido', error: true);
      return;
    }
    if (cedula.isEmpty) {
      _mostrarSnackbar('La cédula es requerida', error: true);
      return;
    }

    setState(() => _isLoading = true);

    final resultado = await _apiService.registrarPersona(
      cedula: cedula,
      nombre: nombre,
      imagenPath: _capturedImage!.path,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (resultado['exito'] == true) {
      _mostrarSnackbar('✅ ${nombre} registrado exitosamente');
      // Volver a la pantalla anterior después de 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    } else {
      // Mostrar error detallado si hay detalles de validación
      final error = resultado['error'] ?? 'Error desconocido';
      final detalles = resultado['detalles'];
      String mensaje = error;
      if (detalles != null) {
        final msgs = (detalles as Map).values.join('\n');
        mensaje = '$error\n$msgs';
      }
      _mostrarDialogoError(mensaje);
    }
  }

  void _mostrarSnackbar(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarDialogoError(String mensaje) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _cedulaController.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Persona'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                Column(
                  children: [
                    // Vista de cámara o imagen capturada
                    Expanded(
                      flex: 3,
                      child: _capturedImage == null
                          ? CameraPreview(_controller!)
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.file(
                                  File(_capturedImage!.path),
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Rostro detectado',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),

                    // Formulario
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Campo cédula
                            TextField(
                              controller: _cedulaController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Cédula',
                                prefixIcon: const Icon(Icons.badge),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Campo nombre
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nombre completo',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Botones
                            Row(
                              children: [
                                if (_capturedImage == null)
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _takePicture,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Tomar Foto'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else ...[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => setState(
                                              () => _capturedImage = null,
                                            ),
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Reintentar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : _saveRegistration,
                                      icon: const Icon(Icons.cloud_upload),
                                      label: const Text('Registrar'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade700,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Overlay de carga
                if (_isLoading)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Registrando en el servidor...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

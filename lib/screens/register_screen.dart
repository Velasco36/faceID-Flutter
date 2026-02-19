import 'dart:async';
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
  bool _processingFrame = false;
  bool _faceDetected = false;
  XFile? _capturedImage;
  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  // Control del stepper
  int _currentStep = 0;

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
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      _startImageStream();
    } catch (e) {
      print('Error inicializando cámara: $e');
    }
  }

  void _startImageStream() {
    _controller?.startImageStream((CameraImage image) async {
      // Solo procesar si estamos en el paso 0 y no hemos detectado rostro aún
      if (_processingFrame || _faceDetected || _currentStep != 0) return;

      _processingFrame = true;

      try {
        final detected = await _faceDetector.detectFaceFromCameraImage(image);
        if (detected && !_faceDetected && mounted) {
          setState(() {
            _faceDetected = true;
          });
          await _stopStreamAndCapturePhoto();
        }
      } catch (e) {
        print('Error en stream: $e');
      } finally {
        _processingFrame = false;
      }
    });
  }

  Future<void> _stopStreamAndCapturePhoto() async {
    try {
      await _controller?.stopImageStream();
      await Future.delayed(const Duration(milliseconds: 200));

      final picture = await _controller?.takePicture();
      if (picture == null || !mounted) {
        _reiniciarDeteccion();
        return;
      }

      setState(() {
        _capturedImage = picture;
      });

      _mostrarSnackbar('✅ Rostro detectado correctamente');

      // Avanzar al siguiente paso automáticamente
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _currentStep = 1;
        });
      }
    } catch (e) {
      print('Error capturando foto: $e');
      _reiniciarDeteccion();
    }
  }

  void _reiniciarDeteccion() {
    if (!mounted) return;
    setState(() {
      _faceDetected = false;
      _processingFrame = false;
    });
    _startImageStream();
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

  Widget _buildCameraBackground() {
    if (_capturedImage != null) {
      return Image.file(File(_capturedImage!.path), fit: BoxFit.cover);
    }

    // Corrección de aspect ratio: llena la pantalla sin distorsión
    return OverflowBox(
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Persona'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCameraInitialized
          ? Column(
              children: [
                // Barra de progreso (Stepper)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      _buildStepItem(0, 'Tomar Foto', Icons.camera_alt),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: _currentStep > 0
                              ? Colors.green
                              : Colors.grey.shade400,
                        ),
                      ),
                      _buildStepItem(1, 'Completar Datos', Icons.person),
                    ],
                  ),
                ),

                // Contenido según el paso actual
                Expanded(
                  child: _currentStep == 0
                      ? _buildCameraStep()
                      : _buildFormStep(),
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

  Widget _buildStepItem(int step, String label, IconData icon) {
    final isActive = _currentStep >= step;
    final isCompleted = _currentStep > step;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : isActive
                  ? Colors.blue.shade700
                  : Colors.grey.shade400,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '${step + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.black87 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraStep() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Vista de cámara o imagen capturada
        _buildCameraBackground(),

        // Marco ovalado para detección
        Center(
          child: Container(
            width: 220,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(
                color: _faceDetected ? Colors.green : Colors.white54,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(120),
            ),
          ),
        ),

        // Texto superior de instrucciones
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              _faceDetected
                  ? 'Rostro detectado ✓'
                  : 'Coloca tu rostro en el marco',
              style: TextStyle(
                color: _faceDetected ? Colors.greenAccent : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ),
        ),

        // Botón para volver a detectar si es necesario
        if (_faceDetected)
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _faceDetected = false;
                    _capturedImage = null;
                  });
                  _startImageStream();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar detección'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFormStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Mini vista previa de la foto
          if (_capturedImage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(_capturedImage!.path),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Foto capturada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rostro verificado correctamente',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      setState(() {
                        _currentStep = 0;
                        _faceDetected = false;
                        _capturedImage = null;
                      });
                      _startImageStream();
                    },
                  ),
                ],
              ),
            ),

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
          const SizedBox(height: 16),

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
          const SizedBox(height: 24),

          // Botones de navegación
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _currentStep = 0;
                            _faceDetected =
                                true; // Mantener el estado de detección
                          });
                        },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveRegistration,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Registrar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

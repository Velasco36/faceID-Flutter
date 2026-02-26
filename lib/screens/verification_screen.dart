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

class _VerifyScreenState extends State<VerifyScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _processingFrame = false;
  bool _verificando = false;
  bool _faceDetected = false;
  bool _streamActivo = false;
  String? _nombreReconocido;
  String? _errorMensaje;
  XFile? _fotoCapturada;

  // Control de detecciones consecutivas
  int _consecutiveDetections = 0;
  int _consecutiveNoDetections = 0;
  static const int _requiredDetections = 3;
  static const int _requiredNoDetections = 3;

  // Control de cámara
  int _cameraIndex = 0;
  bool _isBackCamera = true;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (_isDisposed) return;

    print('Lifecycle state changed to: $state');

    if (state == AppLifecycleState.paused) {
      _isPaused = true;
      await _detenerStream();
      await _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _streamActivo = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      if (mounted && !_isDisposed) {
        // Pequeña pausa para asegurar que todo está listo
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && !_isDisposed && !_isPaused) {
          await _initializeCamera();
        }
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isDisposed || _isInitializing || _isPaused) return;

    _isInitializing = true;

    try {
      await _controller?.dispose();

      if (_cameraIndex >= cameras.length) {
        _cameraIndex = 0;
      }

      print(
        'Inicializando cámara: ${_cameraIndex == 0 ? "Trasera" : "Frontal"}',
      );

      _controller = CameraController(
        cameras[_cameraIndex],
        ResolutionPreset.high, // Cambiado a high para mejor calidad
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();

      if (!mounted || _isDisposed || _isPaused) {
        _isInitializing = false;
        return;
      }

      setState(() {
        _isCameraInitialized = true;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted && !_isDisposed && !_isPaused) {
        _iniciarStream();
      }
    } catch (e) {
      print('Error inicializando cámara: $e');
      if (mounted && !_isDisposed && !_isPaused) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _cambiarCamara() async {
    if (cameras.length < 2 || _isDisposed || _isPaused) {
      return;
    }

    setState(() {
      _isCameraInitialized = false;
      _processingFrame = false;
      _faceDetected = false;
      _consecutiveDetections = 0;
      _consecutiveNoDetections = 0;
      _verificando = false;
      _nombreReconocido = null;
      _errorMensaje = null;
      _fotoCapturada = null;
      _streamActivo = false;
    });

    await _detenerStream();
    await _controller?.dispose();
    _controller = null;

    if (!mounted || _isDisposed || _isPaused) return;

    setState(() {
      _cameraIndex = _cameraIndex == 0 ? 1 : 0;
      _isBackCamera = _cameraIndex == 0;
    });

    await _initializeCamera();
  }

  void _iniciarStream() {
    if (_streamActivo || _isDisposed || _isPaused) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    _streamActivo = true;
    print(
      'Stream iniciado - Cámara: ${_cameraIndex == 0 ? "Trasera" : "Frontal"}',
    );

    try {
      _controller!.startImageStream((CameraImage image) async {
        if (_processingFrame ||
            _verificando ||
            _faceDetected ||
            _isDisposed ||
            _isPaused ||
            !mounted)
          return;

        _processingFrame = true;

        bool detected = false;
        try {
          detected = await _faceDetector.detectFaceFromCameraImage(
            image,
            cameras[_cameraIndex],
          );
        } catch (e) {
          print('Error en detección: $e');
        }

        if (detected) {
          _consecutiveDetections++;
          _consecutiveNoDetections = 0;

          if (_consecutiveDetections >= _requiredDetections &&
              mounted &&
              !_isDisposed &&
              !_isPaused) {
            print('🎯 Rostro confirmado');
            _faceDetected = true;
            _consecutiveDetections = 0;
            setState(() {});
            await _stopStreamAndVerify();
            _processingFrame = false;
            return;
          }
        } else {
          _consecutiveNoDetections++;
          if (_consecutiveNoDetections >= _requiredNoDetections) {
            _consecutiveDetections = 0;
          }
        }

        _processingFrame = false;
      });
    } catch (e) {
      print('Error iniciando stream: $e');
      _streamActivo = false;
    }
  }

  Future<void> _detenerStream() async {
    if (!_streamActivo) return;
    _streamActivo = false;
    try {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      print('Error deteniendo stream: $e');
    }
  }

  Future<void> _stopStreamAndVerify() async {
    try {
      await _detenerStream();

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted || _isDisposed || _isPaused) return;

      final picture = await _controller?.takePicture();
      if (picture == null) {
        _reiniciarEscaneo();
        return;
      }

      setState(() {
        _fotoCapturada = picture;
        _verificando = true;
        _errorMensaje = null;
      });

      final respuesta = await _apiService.verificarIdentidad(
        imagenPath: picture.path,
      );

      if (!mounted || _isDisposed || _isPaused) return;

      if (respuesta['exito'] == true) {
        final data = respuesta['data'];
        if (data['verificado'] == true) {
          setState(() {
            _verificando = false;
            _nombreReconocido = data['persona']['nombre'];
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isDisposed) {
              _reiniciarEscaneo();
            }
          });
        } else {
          setState(() {
            _verificando = false;
            _errorMensaje = 'Rostro no reconocido';
          });
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted && !_isDisposed) {
              _reiniciarEscaneo();
            }
          });
        }
      } else {
        setState(() {
          _verificando = false;
          _errorMensaje = respuesta['error'] ?? 'Error al conectar';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) {
            _reiniciarEscaneo();
          }
        });
      }
    } catch (e) {
      print('Error en verificación: $e');
      if (mounted && !_isDisposed && !_isPaused) {
        setState(() {
          _verificando = false;
          _errorMensaje = 'Error inesperado';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) {
            _reiniciarEscaneo();
          }
        });
      }
    }
  }

  void _reiniciarEscaneo() {
    if (!mounted || _isDisposed || _isPaused) return;
    setState(() {
      _verificando = false;
      _faceDetected = false;
      _nombreReconocido = null;
      _errorMensaje = null;
      _fotoCapturada = null;
      _processingFrame = false;
      _consecutiveDetections = 0;
      _consecutiveNoDetections = 0;
    });
    _iniciarStream();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _detenerStream();
    _controller?.dispose();
    _faceDetector.dispose();
    super.dispose();
  }

  // ============ MÉTODO CORREGIDO PARA LA CÁMARA ============
  Widget _buildCameraBackground() {
    if (_fotoCapturada != null) {
      return Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    try {
      // Obtener el tamaño de la pantalla
      final size = MediaQuery.of(context).size;

      // Calcular la escala para que la cámara ocupe toda la pantalla
      // sin distorsionarse
      final cameraAspectRatio = _controller!.value.aspectRatio;
      final screenAspectRatio = size.aspectRatio;

      // Calcular la escala basada en la relación de aspecto
      double scale;
      if (cameraAspectRatio > screenAspectRatio) {
        // La cámara es más ancha que la pantalla, ajustar por altura
        scale = size.height / (size.width / cameraAspectRatio);
      } else {
        // La cámara es más alta que la pantalla, ajustar por ancho
        scale = size.width / (size.height * cameraAspectRatio);
      }

      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: SizedBox(
              width: size.width,
              height: size.width * cameraAspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error mostrando preview: $e');
      return Container(color: Colors.black);
    }
  }

  // Método alternativo más simple si el anterior no funciona bien
  Widget _buildCameraBackgroundAlternativo() {
    if (_fotoCapturada != null) {
      return Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    try {
      return Center(
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: CameraPreview(_controller!),
        ),
      );
    } catch (e) {
      print('Error mostrando preview: $e');
      return Container(color: Colors.black);
    }
  }
  // ============ FIN DEL MÉTODO CORREGIDO ============

  bool _mostrarBotonCamara() {
    return !_verificando &&
        _nombreReconocido == null &&
        _errorMensaje == null &&
        _fotoCapturada == null &&
        _isCameraInitialized &&
        !_isPaused &&
        cameras.length > 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo negro
          Container(color: Colors.black),

          // Cámara - Usar el método corregido
          if (_isCameraInitialized && !_isPaused) _buildCameraBackground(),

          // Overlays
          if (_verificando && !_isPaused) _buildLoadingOverlay(),
          if (_nombreReconocido != null && !_verificando && !_isPaused)
            _buildResultadoExito(),
          if (_errorMensaje != null && !_verificando && !_isPaused)
            _buildResultadoError(),

          // Marco de detección
          if (_isCameraInitialized &&
              !_verificando &&
              _fotoCapturada == null &&
              !_isPaused)
            _buildMarcoDeteccion(),

          // Texto superior
          if (_isCameraInitialized && !_isPaused) _buildTextoSuperior(),

          // Botón de regresar
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
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                },
              ),
            ),
          ),

          // Botón de cambio de cámara
          if (_mostrarBotonCamara())
            Positioned(
              bottom: 48,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _cambiarCamara,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),

          // Mensaje de error de inicialización
          if (!_isCameraInitialized && !_isInitializing && !_isPaused)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Error al iniciar cámara',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _initializeCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarcoDeteccion() {
    final progress = _consecutiveDetections / _requiredDetections;
    Color color;
    if (_consecutiveDetections == 0) {
      color = Colors.white54;
    } else if (progress < 0.6) {
      color = Colors.yellowAccent;
    } else {
      color = Colors.greenAccent;
    }

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

  Widget _buildTextoSuperior() {
    String texto;
    Color color;

    if (_verificando) {
      texto = 'Procesando...';
      color = Colors.white;
    } else if (_faceDetected) {
      texto = 'Rostro detectado ✓';
      color = Colors.greenAccent;
    } else if (_consecutiveDetections > 0) {
      texto = 'Mantén el rostro quieto...';
      color = Colors.yellowAccent;
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
          ],
        ),
      ),
    );
  }

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

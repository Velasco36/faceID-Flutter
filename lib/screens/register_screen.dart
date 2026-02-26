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

class _RegisterScreenState extends State<RegisterScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _processingFrame = false;
  bool _faceDetected = false;
  bool _streamActivo = false;
  bool _registrando = false;
  String? _errorMensaje;
  String? _mensajeExito;
  XFile? _fotoCapturada;

  // Control de detecciones consecutivas
  int _consecutiveDetections = 0;
  int _consecutiveNoDetections = 0;
  static const int _requiredDetections = 5;
  static const int _requiredNoDetections = 3;

  // Control de cámara
  int _cameraIndex = 0;
  bool _isBackCamera = true;

  // Control de formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  String _tipoCedula = 'V';
  bool _mostrarFormulario = false;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  // Control de pausa
  bool _isPaused = false;
  bool _isDisposed = false;
  bool _isInitializing = false;

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

      // Solo iniciar el stream si no estamos mostrando formulario ni foto capturada
      if (mounted &&
          !_isDisposed &&
          !_isPaused &&
          !_mostrarFormulario &&
          _fotoCapturada == null &&
          !_faceDetected) {
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
    if (cameras.length < 2 || _isDisposed || _isPaused || _registrando) {
      return;
    }

    // Detener todo antes de cambiar
    setState(() {
      _isCameraInitialized = false;
      _processingFrame = false;
      _faceDetected = false;
      _consecutiveDetections = 0;
      _consecutiveNoDetections = 0;
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
    if (_streamActivo ||
        _isDisposed ||
        _isPaused ||
        _registrando ||
        _mostrarFormulario ||
        _fotoCapturada != null ||
        _faceDetected) {
      return;
    }

    if (_controller == null || !_controller!.value.isInitialized) return;

    _streamActivo = true;

    try {
      _controller!.startImageStream((CameraImage image) async {
        if (_processingFrame ||
            _registrando ||
            _faceDetected ||
            _isDisposed ||
            _isPaused ||
            !mounted ||
            _mostrarFormulario ||
            _fotoCapturada != null)
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
              !_isPaused &&
              !_mostrarFormulario &&
              _fotoCapturada == null) {
            _faceDetected = true;
            _consecutiveDetections = 0;
            setState(() {});
            await _stopStreamAndShowForm();
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

  Future<void> _stopStreamAndShowForm() async {
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
        _mostrarFormulario = true;
      });
    } catch (e) {
      print('Error capturando foto: $e');
      _reiniciarEscaneo();
    }
  }

  Future<void> _registrarUsuario() async {
    if (_nombreController.text.isEmpty || _cedulaController.text.isEmpty) {
      setState(() {
        _errorMensaje = 'Completa todos los campos';
      });
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_cedulaController.text)) {
      setState(() {
        _errorMensaje = 'La cédula debe contener solo números';
      });
      return;
    }

    setState(() {
      _registrando = true;
      _errorMensaje = null;
    });

    try {
      final cedulaCompleta = '$_tipoCedula${_cedulaController.text}';

      final respuesta = await _apiService.registrarPersona(
        nombre: _nombreController.text,
        cedula: cedulaCompleta,
        imagenPath: _fotoCapturada!.path,
      );

      if (!mounted || _isDisposed) return;

      if (respuesta['exito'] == true) {
        setState(() {
          _registrando = false;
          _mensajeExito = 'Registro exitoso';
        });

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) {
            Navigator.pop(context);
          }
        });
      } else {
        setState(() {
          _registrando = false;
          _errorMensaje = respuesta['error'] ?? 'Error al registrar';
        });
      }
    } catch (e) {
      print('Error en registro: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _registrando = false;
          _errorMensaje = 'Error de conexión';
        });
      }
    }
  }

  void _reiniciarEscaneo() {
    if (!mounted || _isDisposed) return;
    setState(() {
      _registrando = false;
      _faceDetected = false;
      _errorMensaje = null;
      _mensajeExito = null;
      _fotoCapturada = null;
      _mostrarFormulario = false;
      _processingFrame = false;
      _consecutiveDetections = 0;
      _consecutiveNoDetections = 0;
      _nombreController.clear();
      _cedulaController.clear();
      _tipoCedula = 'V';
    });
    _iniciarStream();
  }

  bool _mostrarBotonCamara() {
    // El botón se muestra siempre que:
    // 1. No esté registrando
    // 2. La cámara esté inicializada
    // 3. No esté en pausa
    // 4. Tengamos más de 1 cámara disponible
    return !_registrando &&
        _isCameraInitialized &&
        !_isPaused &&
        cameras.length > 1;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _detenerStream();
    _controller?.dispose();
    _faceDetector.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  // ============ MÉTODOS CORREGIDOS PARA LA CÁMARA ============

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
      var scale = size.aspectRatio / _controller!.value.aspectRatio;

      // Si la escala es menor que 1, significa que la pantalla es más alargada
      // que la cámara, entonces necesitamos recortar los lados
      if (scale < 1) {
        scale = 1 / scale;
      }

      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.fitHeight, // Cambiado a fitHeight para mejor ajuste
            child: SizedBox(
              width: size.width,
              height: size.width * _controller!.value.aspectRatio,
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

  // ============ FIN DE MÉTODOS CORREGIDOS ============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Usar el método corregido para la cámara
          if (_isCameraInitialized && !_isPaused) _buildCameraBackground(),

          // Overlays semitransparentes
          if (_registrando) _buildLoadingOverlay(),
          if (_errorMensaje != null && !_registrando && !_isPaused)
            _buildResultadoError(),
          if (_mensajeExito != null && !_registrando && !_isPaused)
            _buildResultadoExito(),

          // Marco de detección (solo cuando corresponde)
          if (_isCameraInitialized &&
              !_mostrarFormulario &&
              !_registrando &&
              _fotoCapturada == null &&
              !_isPaused)
            _buildMarcoDeteccion(),

          // Texto superior
          if (_isCameraInitialized &&
              !_mostrarFormulario &&
              !_registrando &&
              !_isPaused)
            _buildTextoSuperior(),

          // Formulario (cuando corresponde)
          if (_mostrarFormulario) _buildFormulario(),

          // Botón de regresar (siempre visible)
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

          // Botón de cambio de cámara - SIEMPRE VISIBLE cuando corresponde
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

    if (_faceDetected) {
      texto = 'Rostro detectado ✓';
      color = Colors.greenAccent;
    } else if (_consecutiveDetections > 0) {
      texto = 'Mantén el rostro quieto...';
      color = Colors.yellowAccent;
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

  Widget _buildFormulario() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Foto de perfil
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: FileImage(File(_fotoCapturada!.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Completa tus datos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Campo de nombre
              TextField(
                controller: _nombreController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  labelStyle: const TextStyle(color: Colors.white70),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de cédula con selector V/E
              Row(
                children: [
                  // Selector V/E
                  Container(
                    width: 70,
                    height: 56,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tipoCedula,
                        dropdownColor: Colors.grey.shade900,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white70,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.center,
                        items: const [
                          DropdownMenuItem(
                            value: 'V',
                            alignment: AlignmentDirectional.center,
                            child: Text('V', textAlign: TextAlign.center),
                          ),
                          DropdownMenuItem(
                            value: 'E',
                            alignment: AlignmentDirectional.center,
                            child: Text('E', textAlign: TextAlign.center),
                          ),
                        ],
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _tipoCedula = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Campo de número de cédula
                  Expanded(
                    child: TextField(
                      controller: _cedulaController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Número de cédula',
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.blue),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(
                          Icons.badge,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _reiniciarEscaneo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Registrar'),
                    ),
                  ),
                ],
              ),
            ],
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
              'Registrando usuario...',
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 40),
            SizedBox(height: 10),
            Text(
              'Registro exitoso',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoError() {
    return Positioned(
      bottom: 80,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade800.withOpacity(0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.white, size: 40),
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
          ],
        ),
      ),
    );
  }
}

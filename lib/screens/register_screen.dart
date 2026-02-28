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

  int _consecutiveDetections = 0;
  int _consecutiveNoDetections = 0;
  static const int _requiredDetections = 5;
  static const int _requiredNoDetections = 3;

  int _cameraIndex = 0;
  bool _isBackCamera = true;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  String _tipoCedula = 'V';
  bool _mostrarFormulario = false;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

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

      if (_cameraIndex >= cameras.length) _cameraIndex = 0;

      _controller = CameraController(
        cameras[_cameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _controller!.initialize();

      if (!mounted || _isDisposed || _isPaused) {
        _isInitializing = false;
        return;
      }

      setState(() => _isCameraInitialized = true);

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted &&
          !_isDisposed &&
          !_isPaused &&
          !_mostrarFormulario &&
          _fotoCapturada == null &&
          !_faceDetected) {
        _iniciarStream();
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted && !_isDisposed && !_isPaused) {
        setState(() => _isCameraInitialized = false);
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _cambiarCamara() async {
    if (cameras.length < 2 || _isDisposed || _isPaused || _registrando) return;

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
        _faceDetected) return;

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
            _fotoCapturada != null) return;

        _processingFrame = true;

        bool detected = false;
        try {
          detected = await _faceDetector.detectFaceFromCameraImage(
            image,
            cameras[_cameraIndex],
          );
        } catch (e) {
          debugPrint('Error en detección: $e');
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
      debugPrint('Error iniciando stream: $e');
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
      debugPrint('Error deteniendo stream: $e');
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
      debugPrint('Error capturando foto: $e');
      _reiniciarEscaneo();
    }
  }

  Future<void> _registrarUsuario() async {
    if (_nombreController.text.isEmpty || _cedulaController.text.isEmpty) {
      setState(() => _errorMensaje = 'Completa todos los campos');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(_cedulaController.text)) {
      setState(() => _errorMensaje = 'La cédula debe contener solo números');
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
          if (mounted && !_isDisposed) Navigator.pop(context);
        });
      } else {
        setState(() {
          _registrando = false;
          _errorMensaje = respuesta['error'] ?? 'Error al registrar';
        });
      }
    } catch (e) {
      debugPrint('Error en registro: $e');
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

  Widget _buildCameraBackground() {
    if (_fotoCapturada != null) {
      return Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    try {
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio / _controller!.value.aspectRatio;
      if (scale < 1) scale = 1 / scale;

      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: SizedBox(
              width: size.width,
              height: size.width * _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error mostrando preview: $e');
      return Container(color: Colors.black);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Fondo: cámara o foto capturada ──
          if (_isCameraInitialized && !_isPaused) _buildCameraBackground(),

          // ── Marco de detección ──
          if (_isCameraInitialized &&
              !_mostrarFormulario &&
              !_registrando &&
              _fotoCapturada == null &&
              !_isPaused)
            _buildMarcoDeteccion(),

          // ── Texto guía superior ──
          if (_isCameraInitialized &&
              !_mostrarFormulario &&
              !_registrando &&
              !_isPaused)
            _buildTextoSuperior(),

          // ── Formulario de datos ──
          if (_mostrarFormulario && !_registrando) _buildFormulario(),

          // ── Loading overlay: SIEMPRE encima de todo ──
          if (_registrando) _buildLoadingOverlay(),

          // ── Mensajes de resultado ──
          if (_mensajeExito != null && !_registrando && !_isPaused)
            _buildResultadoExito(),
          if (_errorMensaje != null && !_registrando && !_isPaused)
            _buildResultadoError(),

          // ── Botón regresar ──
          if (!_registrando)
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

          // ── Botón cambio de cámara ──
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
      // Fondo sólido oscuro para tapar completamente la cámara
      color: const Color(0xFF121212),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: _reiniciarEscaneo,
                  ),
                  const Expanded(
                    child: Text(
                      'Datos del usuario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // balance del back button
                ],
              ),

              const SizedBox(height: 24),

              // Foto circular con borde de color
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF137FEC), Color(0xFF00C6FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF137FEC).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: ClipOval(
                  child: Image.file(
                    File(_fotoCapturada!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Indicador de foto OK
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.greenAccent, width: 1),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Foto capturada',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Campo nombre
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre completo',
                icon: Icons.person_rounded,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              // Fila cédula
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector V/E
                  Container(
                    width: 72,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _tipoCedula,
                        dropdownColor: const Color(0xFF1E1E2E),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white54,
                          size: 20,
                        ),
                        isExpanded: true,
                        alignment: AlignmentDirectional.center,
                        items: const [
                          DropdownMenuItem(
                            value: 'V',
                            alignment: AlignmentDirectional.center,
                            child: Text('V'),
                          ),
                          DropdownMenuItem(
                            value: 'E',
                            alignment: AlignmentDirectional.center,
                            child: Text('E'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoCedula = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(
                      controller: _cedulaController,
                      label: 'Número de cédula',
                      icon: Icons.badge_rounded,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),

              // Error inline
              if (_errorMensaje != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMensaje!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reiniciarEscaneo,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white30),
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
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _registrarUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF137FEC),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.how_to_reg_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Registrar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E2E),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.8),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Loading overlay: cubre TODO incluyendo el formulario ──
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF137FEC).withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137FEC).withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinner con borde azul
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: const Color(0xFF137FEC),
                  backgroundColor: const Color(0xFF137FEC).withOpacity(0.15),
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Registrando usuario',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Por favor espera...',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
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

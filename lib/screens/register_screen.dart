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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
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

  late AnimationController _formAnimController;
  late Animation<double> _formFadeAnim;
  late Animation<Offset> _formSlideAnim;

  static const Color _primary = Color(0xFF137FEC);
  static const Color _bgDark = Color(0xFFF8FAFC);
  static const Color _bgCard = Color(0xFFFFFFFF);
  static const Color _bgField = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _formAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _formFadeAnim = CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut);
    _formSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _formAnimController, curve: Curves.easeOut));

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
      if (mounted) setState(() { _isCameraInitialized = false; _streamActivo = false; });
    } else if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      if (mounted && !_isDisposed) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && !_isDisposed && !_isPaused) await _initializeCamera();
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
        cameras[_cameraIndex], ResolutionPreset.high,
        enableAudio: false, imageFormatGroup: ImageFormatGroup.nv21,
      );
      await _controller!.initialize();
      if (!mounted || _isDisposed || _isPaused) { _isInitializing = false; return; }
      setState(() => _isCameraInitialized = true);
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted && !_isDisposed && !_isPaused && !_mostrarFormulario && _fotoCapturada == null && !_faceDetected) {
        _iniciarStream();
      }
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted && !_isDisposed && !_isPaused) setState(() => _isCameraInitialized = false);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _cambiarCamara() async {
    if (cameras.length < 2 || _isDisposed || _isPaused || _registrando) return;
    setState(() {
      _isCameraInitialized = false; _processingFrame = false; _faceDetected = false;
      _consecutiveDetections = 0; _consecutiveNoDetections = 0; _streamActivo = false;
    });
    await _detenerStream();
    await _controller?.dispose();
    _controller = null;
    if (!mounted || _isDisposed || _isPaused) return;
    setState(() { _cameraIndex = _cameraIndex == 0 ? 1 : 0; _isBackCamera = _cameraIndex == 0; });
    await _initializeCamera();
  }

  void _iniciarStream() {
    if (_streamActivo || _isDisposed || _isPaused || _registrando || _mostrarFormulario || _fotoCapturada != null || _faceDetected) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    _streamActivo = true;
    try {
      _controller!.startImageStream((CameraImage image) async {
        if (_processingFrame || _registrando || _faceDetected || _isDisposed || _isPaused || !mounted || _mostrarFormulario || _fotoCapturada != null) return;
        _processingFrame = true;
        bool detected = false;
        try {
          detected = await _faceDetector.detectFaceFromCameraImage(image, cameras[_cameraIndex]);
        } catch (e) { debugPrint('Error en detección: $e'); }

        if (detected) {
          _consecutiveDetections++;
          _consecutiveNoDetections = 0;
          if (_consecutiveDetections >= _requiredDetections && mounted && !_isDisposed && !_isPaused && !_mostrarFormulario && _fotoCapturada == null) {
            _faceDetected = true;
            _consecutiveDetections = 0;
            setState(() {});
            await _stopStreamAndShowForm();
            _processingFrame = false;
            return;
          }
        } else {
          _consecutiveNoDetections++;
          if (_consecutiveNoDetections >= _requiredNoDetections) _consecutiveDetections = 0;
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
      if (_controller != null && _controller!.value.isInitialized && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) { debugPrint('Error deteniendo stream: $e'); }
  }

  Future<void> _stopStreamAndShowForm() async {
    try {
      await _detenerStream();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _isDisposed || _isPaused) return;
      final picture = await _controller?.takePicture();
      if (picture == null) { _reiniciarEscaneo(); return; }
      setState(() { _fotoCapturada = picture; _mostrarFormulario = true; });
      _formAnimController.forward();
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
    setState(() { _registrando = true; _errorMensaje = null; });
    try {
      final cedulaCompleta = '$_tipoCedula${_cedulaController.text}';
      final respuesta = await _apiService.registrarPersona(
        nombre: _nombreController.text,
        cedula: cedulaCompleta,
        imagenPath: _fotoCapturada!.path,
      );
      if (!mounted || _isDisposed) return;
      if (respuesta['exito'] == true) {
        setState(() { _registrando = false; _mensajeExito = 'Registro exitoso'; });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) Navigator.pop(context);
        });
      } else {
        setState(() { _registrando = false; _errorMensaje = respuesta['error'] ?? 'Error al registrar'; });
      }
    } catch (e) {
      debugPrint('Error en registro: $e');
      if (mounted && !_isDisposed) setState(() { _registrando = false; _errorMensaje = 'Error de conexión'; });
    }
  }

  void _reiniciarEscaneo() {
    if (!mounted || _isDisposed) return;
    _formAnimController.reset();
    setState(() {
      _registrando = false; _faceDetected = false; _errorMensaje = null; _mensajeExito = null;
      _fotoCapturada = null; _mostrarFormulario = false; _processingFrame = false;
      _consecutiveDetections = 0; _consecutiveNoDetections = 0;
      _nombreController.clear(); _cedulaController.clear(); _tipoCedula = 'V';
    });
    _iniciarStream();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _formAnimController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _detenerStream();
    _controller?.dispose();
    _faceDetector.dispose();
    _nombreController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Widget _buildCameraBackground() {
    if (_fotoCapturada != null) return Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover);
    if (_controller == null || !_controller!.value.isInitialized) return Container(color: Colors.black);
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
    } catch (e) { return Container(color: Colors.black); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Cámara de fondo ──
          if (_isCameraInitialized && !_isPaused) _buildCameraBackground(),

          // ── Gradiente oscuro sobre cámara ──
          if (_isCameraInitialized && !_mostrarFormulario && !_registrando && !_isPaused)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xBB000000), Color(0x33000000), Color(0xBB000000)],
                ),
              ),
            ),

          // ── Marco de detección ──
          if (_isCameraInitialized && !_mostrarFormulario && !_registrando && _fotoCapturada == null && !_isPaused)
            _buildMarcoDeteccion(),

          // ── Texto guía ──
          if (_isCameraInitialized && !_mostrarFormulario && !_registrando && !_isPaused)
            _buildTextoSuperior(),

          // ── Formulario animado ──
          if (_mostrarFormulario && !_registrando)
            FadeTransition(
              opacity: _formFadeAnim,
              child: SlideTransition(position: _formSlideAnim, child: _buildFormulario()),
            ),

          // ── Loading ──
          if (_registrando) _buildLoadingOverlay(),

          // ── Éxito ──
          if (_mensajeExito != null && !_registrando) _buildResultadoExito(),

          // ── Error (solo en modo cámara) ──
          if (_errorMensaje != null && !_registrando && !_mostrarFormulario) _buildResultadoError(),

          // ── Barra superior: UN SOLO botón back + toggle cámara ──
          if (!_registrando)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      _buildIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => _mostrarFormulario ? _reiniciarEscaneo() : Navigator.pop(context),
                      ),
                      const Spacer(),
                      if (!_mostrarFormulario && _isCameraInitialized && !_isPaused && cameras.length > 1)
                        _buildIconBtn(icon: Icons.cameraswitch_rounded, onTap: _cambiarCamara),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildMarcoDeteccion() {
    final progress = _consecutiveDetections / _requiredDetections;
    Color borderColor;
    if (_consecutiveDetections == 0) borderColor = Colors.white38;
    else if (progress < 0.6) borderColor = const Color(0xFFFFD60A);
    else borderColor = const Color(0xFF30D158);

    return Center(
      child: Container(
        width: 220,
        height: 285,
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2.5),
          borderRadius: BorderRadius.circular(120),
        ),
      ),
    );
  }

  Widget _buildTextoSuperior() {
    String texto; Color color; IconData icon;
    if (_faceDetected) {
      texto = 'Rostro detectado'; color = const Color(0xFF30D158); icon = Icons.check_circle_outline_rounded;
    } else if (_consecutiveDetections > 0) {
      texto = 'Mantén el rostro quieto...'; color = const Color(0xFFFFD60A); icon = Icons.face_retouching_natural;
    } else {
      texto = 'Coloca tu rostro en el marco'; color = Colors.white; icon = Icons.face_rounded;
    }

    return Positioned(
      top: 108, left: 0, right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.25), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(texto, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
    return Container(
      color: _bgDark,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 52), // espacio para la barra de navegación
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 4),

                    // Título
                    const Text(
                      'Nuevo registro',
                      style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completa los datos del usuario',
                      style: TextStyle(color: const Color(0xFF64748B), fontSize: 13),
                    ),

                    const SizedBox(height: 26),

                    // Foto con badge de check
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _primary, width: 2.5),
                          ),
                          child: ClipOval(child: Image.file(File(_fotoCapturada!.path), fit: BoxFit.cover)),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF30D158),
                            shape: BoxShape.circle,
                            border: Border.all(color: _bgCard, width: 2.5),
                          ),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 13),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // Campo nombre
                    _buildField(
                      controller: _nombreController,
                      label: 'Nombre completo',
                      hint: 'Ej. Juan Pérez',
                      icon: Icons.person_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),

                    // Cédula
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 66,
                          height: 54,
                          decoration: BoxDecoration(
                            color: _bgField,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _border),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _tipoCedula,
                              dropdownColor: const Color(0xFFFFFFFF),
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w600),
                              icon: const Icon(Icons.expand_more_rounded, color: Color(0xFF94A3B8), size: 16),
                              isExpanded: true,
                              alignment: AlignmentDirectional.center,
                              items: const [
                                DropdownMenuItem(value: 'V', alignment: AlignmentDirectional.center, child: Text('V')),
                                DropdownMenuItem(value: 'E', alignment: AlignmentDirectional.center, child: Text('E')),
                              ],
                              onChanged: (v) { if (v != null) setState(() => _tipoCedula = v); },
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildField(
                            controller: _cedulaController,
                            label: 'Número de cédula',
                            hint: '12345678',
                            icon: Icons.badge_outlined,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                          ),
                        ),
                      ],
                    ),

                    // Error inline en el formulario
                    if (_errorMensaje != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMensaje!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _reiniciarEscaneo,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(color: _border),
                              ),
                              child: const Center(
                                child: Text('Cancelar', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w500, fontSize: 14)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: _registrarUsuario,
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(13),
                                boxShadow: [BoxShadow(color: _primary.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 4))],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.how_to_reg_rounded, color: Colors.white, size: 17),
                                  SizedBox(width: 7),
                                  Text('Registrar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                ],
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      cursorColor: _primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
        floatingLabelStyle: const TextStyle(color: _primary, fontSize: 12),
        filled: true,
        fillColor: _bgField,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: _border), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _primary, width: 1.5), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                color: _primary,
                backgroundColor: _primary.withOpacity(0.12),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Registrando...',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoExito() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color.fromARGB(255, 48, 59, 209).withOpacity(0.35), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF30D158).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: Color(0xFF30D158), size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Registro exitoso', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'El usuario fue registrado correctamente',
              style: TextStyle(color: Colors.black, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoError() {
    return Positioned(
      bottom: 36, left: 18, right: 18,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1010),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(_errorMensaje!, style: const TextStyle(color: Colors.white, fontSize: 13))),
            GestureDetector(
              onTap: () => setState(() => _errorMensaje = null),
              child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.35), size: 16),
            ),
          ],
        ),
      ),
    );
  }
}

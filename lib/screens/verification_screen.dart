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
  String? _mensajeMovimiento;       // 'entrada' o 'salida'
  String? _errorMensaje;
  bool _registroDuplicado = false;
  String? _mensajeDuplicado;        // mensaje_detallado del backend
  String? _tipoUltimoRegistro;      // 'entrada' o 'salida'
  String? _tiempoRestante;          // texto_amigable
  XFile? _fotoCapturada;

  int _consecutiveDetections = 0;
  int _consecutiveNoDetections = 0;
  static const int _requiredDetections = 3;
  static const int _requiredNoDetections = 3;

  int _cameraIndex = 0;
  bool _isBackCamera = true;

  final FaceDetectorService _faceDetector = FaceDetectorService();
  final ApiService _apiService = ApiService();

  bool _isDisposed = false;
  bool _isInitializing = false;
  bool _isPaused = false;

  // ── Mismos colores que RegisterScreen ──
  static const Color _primary  = Color(0xFF137FEC);
  static const Color _bgCard   = Color(0xFFFFFFFF);
  static const Color _green    = Color(0xFF30D158);
  static const Color _yellow   = Color(0xFFFFD60A);

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
      if (mounted && !_isDisposed && !_isPaused) _iniciarStream();
    } catch (e) {
      debugPrint('Error inicializando cámara: $e');
      if (mounted && !_isDisposed && !_isPaused) setState(() => _isCameraInitialized = false);
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _cambiarCamara() async {
    if (cameras.length < 2 || _isDisposed || _isPaused) return;
    setState(() {
      _isCameraInitialized = false; _processingFrame = false; _faceDetected = false;
      _consecutiveDetections = 0; _consecutiveNoDetections = 0;
      _verificando = false; _nombreReconocido = null; _mensajeMovimiento = null;
      _errorMensaje = null; _fotoCapturada = null; _streamActivo = false;
      _registroDuplicado = false; _mensajeDuplicado = null;
      _tipoUltimoRegistro = null; _tiempoRestante = null;
    });
    await _detenerStream();
    await _controller?.dispose();
    _controller = null;
    if (!mounted || _isDisposed || _isPaused) return;
    setState(() { _cameraIndex = _cameraIndex == 0 ? 1 : 0; _isBackCamera = _cameraIndex == 0; });
    await _initializeCamera();
  }

  void _iniciarStream() {
    if (_streamActivo || _isDisposed || _isPaused) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    _streamActivo = true;
    try {
      _controller!.startImageStream((CameraImage image) async {
        if (_processingFrame || _verificando || _faceDetected || _isDisposed || _isPaused || !mounted) return;
        _processingFrame = true;
        bool detected = false;
        try {
          detected = await _faceDetector.detectFaceFromCameraImage(image, cameras[_cameraIndex]);
        } catch (e) { debugPrint('Error en detección: $e'); }

        if (detected) {
          _consecutiveDetections++;
          _consecutiveNoDetections = 0;
          if (_consecutiveDetections >= _requiredDetections && mounted && !_isDisposed && !_isPaused) {
            _faceDetected = true;
            _consecutiveDetections = 0;
            setState(() {});
            await _stopStreamAndVerify();
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

  Future<void> _stopStreamAndVerify() async {
    try {
      await _detenerStream();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted || _isDisposed || _isPaused) return;

      final picture = await _controller?.takePicture();
      if (picture == null) { _reiniciarEscaneo(); return; }

      setState(() { _fotoCapturada = picture; _verificando = true; _errorMensaje = null; });

      final respuesta = await _apiService.verificarIdentidad(imagenPath: picture.path);

      if (!mounted || _isDisposed || _isPaused) return;

      if (respuesta['exito'] == true) {
        final data = respuesta['data'];

        if (data['verificado'] == true && data['registro_duplicado'] == true) {
          // ── Movimiento bloqueado por duplicado ──
          setState(() {
            _verificando = false;
            _registroDuplicado = true;
            _nombreReconocido = data['persona']['nombre'];
            _mensajeDuplicado = data['mensaje_detallado'];
            _tipoUltimoRegistro = data['ultimo_registro']?['tipo'];
            _tiempoRestante = data['tiempo_restante']?['texto_amigable'];
          });
        } else if (data['verificado'] == true) {
          // ── Movimiento registrado correctamente ──
          final tipo = data['movimiento_registrado']?['tipo'] ?? '';
          setState(() {
            _verificando = false;
            _nombreReconocido = data['persona']['nombre'];
            _mensajeMovimiento = tipo;
          });
        } else {
          setState(() { _verificando = false; _errorMensaje = data['mensaje'] ?? 'Rostro no reconocido'; });
        }
      } else {
        setState(() { _verificando = false; _errorMensaje = respuesta['error'] ?? 'Error al conectar'; });
      }

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && !_isDisposed) _reiniciarEscaneo();
      });
    } catch (e) {
      debugPrint('Error en verificación: $e');
      if (mounted && !_isDisposed && !_isPaused) {
        setState(() { _verificando = false; _errorMensaje = 'Error inesperado'; });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isDisposed) _reiniciarEscaneo();
        });
      }
    }
  }

  void _reiniciarEscaneo() {
    if (!mounted || _isDisposed || _isPaused) return;
    setState(() {
      _verificando = false; _faceDetected = false; _nombreReconocido = null;
      _mensajeMovimiento = null; _errorMensaje = null; _fotoCapturada = null;
      _processingFrame = false; _consecutiveDetections = 0; _consecutiveNoDetections = 0;
      _registroDuplicado = false; _mensajeDuplicado = null;
      _tipoUltimoRegistro = null; _tiempoRestante = null;
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
          // ── Cámara ──
          if (_isCameraInitialized && !_isPaused) _buildCameraBackground(),

          // ── Gradiente sobre cámara (igual que RegisterScreen) ──
          if (_isCameraInitialized && !_isPaused)
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
          if (_isCameraInitialized && !_verificando && _fotoCapturada == null && _nombreReconocido == null && _errorMensaje == null && !_isPaused)
            _buildMarcoDeteccion(),

          // ── Texto guía (igual que RegisterScreen) ──
          if (_isCameraInitialized && !_verificando && _nombreReconocido == null && _errorMensaje == null && !_registroDuplicado && !_isPaused)
            _buildTextoSuperior(),

          // ── Loading ──
          if (_verificando) _buildLoadingOverlay(),

          // ── Resultado exitoso ──
          if (_nombreReconocido != null && !_verificando && !_registroDuplicado) _buildResultadoExito(),

          // ── Resultado duplicado ──
          if (_registroDuplicado && !_verificando) _buildResultadoDuplicado(),

          // ── Resultado error ──
          if (_errorMensaje != null && !_verificando) _buildResultadoError(),

          // ── Barra superior: back + toggle cámara (igual que RegisterScreen) ──
          if (!_verificando)
            Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      _buildIconBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false),
                      ),
                      const Spacer(),
                      if (_isCameraInitialized && !_isPaused && _nombreReconocido == null && _errorMensaje == null && cameras.length > 1)
                        _buildIconBtn(icon: Icons.cameraswitch_rounded, onTap: _cambiarCamara),
                    ],
                  ),
                ),
              ),
            ),

          // ── Error de cámara ──
          if (!_isCameraInitialized && !_isInitializing && !_isPaused)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                  const SizedBox(height: 16),
                  const Text('Error al iniciar cámara', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _initializeCamera,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Reintentar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Mismo estilo de botón que RegisterScreen ──
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

  // ── Mismo marco de detección que RegisterScreen ──
  Widget _buildMarcoDeteccion() {
    final progress = _consecutiveDetections / _requiredDetections;
    Color borderColor;
    if (_consecutiveDetections == 0) borderColor = Colors.white38;
    else if (progress < 0.6) borderColor = _yellow;
    else borderColor = _green;

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

  // ── Mismo texto guía pill que RegisterScreen ──
  Widget _buildTextoSuperior() {
    String texto; Color color; IconData icon;
    if (_faceDetected) {
      texto = 'Rostro detectado'; color = _green; icon = Icons.check_circle_outline_rounded;
    } else if (_consecutiveDetections > 0) {
      texto = 'Mantén el rostro quieto...'; color = _yellow; icon = Icons.face_retouching_natural;
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

  // ── Mismo loading que RegisterScreen ──
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
              'Verificando...',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500, letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de éxito con tipo de movimiento ──
  Widget _buildResultadoExito() {
    final esEntrada = _mensajeMovimiento == 'entrada';
    final color = esEntrada ? _green : _primary;
    final icon = esEntrada ? Icons.login_rounded : Icons.logout_rounded;
    final label = esEntrada ? 'Entrada registrada' : 'Salida registrada';

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.2),
            ),
            const SizedBox(height: 4),
            Text(
              _nombreReconocido!,
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // Barra de progreso auto-dismiss
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: null, // indeterminate mientras espera
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tarjeta de movimiento bloqueado por duplicado ──
  Widget _buildResultadoDuplicado() {
    final esEntrada = _tipoUltimoRegistro == 'entrada';
    const Color warningColor = Color(0xFFF59E0B);

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: _bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: warningColor.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono de advertencia
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: warningColor, size: 28),
            ),
            const SizedBox(height: 12),

            // Nombre
            Text(
              _nombreReconocido ?? '',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 20, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Último tipo de registro
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (esEntrada ? _green : _primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    esEntrada ? Icons.login_rounded : Icons.logout_rounded,
                    size: 13,
                    color: esEntrada ? _green : _primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ya registró su ${_tipoUltimoRegistro ?? ''}',
                    style: TextStyle(
                      color: esEntrada ? _green : _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Divider
            Container(height: 1, color: const Color(0xFFE2E8F0)),
            const SizedBox(height: 14),

            // Mensaje detallado
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF94A3B8), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _mensajeDuplicado ?? 'Debe esperar antes del próximo registro.',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),

            if (_tiempoRestante != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: warningColor, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Espera: $_tiempoRestante',
                      style: const TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Mismo toast de error que RegisterScreen ──
  Widget _buildResultadoError() {
    final esNoReconocido = _errorMensaje == 'Rostro no reconocido' ||
        (_errorMensaje?.contains('coincidencia') ?? false);

    return Positioned(
      bottom: 36, left: 18, right: 18,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              esNoReconocido ? Icons.person_off_rounded : Icons.wifi_off_rounded,
              color: Colors.redAccent, size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMensaje!,
                    style: const TextStyle(color: Color(0xFF7F1D1D), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const Text(
                    'Reintentando en breve...',
                    style: TextStyle(color: Color(0xFFEF4444), fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

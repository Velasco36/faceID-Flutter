import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SessionCompany extends StatefulWidget {
  const SessionCompany({super.key});

  @override
  State<SessionCompany> createState() => _SessionCompanyState();
}

class _SessionCompanyState extends State<SessionCompany>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _rifController = TextEditingController();
  String _selectedPrefix = 'J';
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const _primaryColor = Color(0xFF137FEC);
  static const _prefixes = ['J', 'G', 'V', 'E', 'P'];

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _fadeController.forward();
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _rifController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_rifController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      // Navigator.pushNamed(context, '/next-screen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF101922)
            : const Color(0xFFFFFFFF),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 440),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A2535) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 32),
                          const SizedBox(height: 20),
                          // ✅ FIX: RepaintBoundary aísla el repaint de la animación
                          // Evita que el AnimatedBuilder redibuje toda la pantalla
                          RepaintBoundary(child: _buildLottieAnimation()),
                          const SizedBox(height: 24),
                          _buildWelcomeText(isDark),
                          _buildFormSection(isDark),
                          _buildFooter(isDark),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _primaryColor.withOpacity(0.18),
                _primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [_AnimatedScanPlaceholder()],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeText(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            'Bienvenido a FaceID',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Seguridad biométrica de última generación para su empresa. '
            'Por favor, ingrese los datos fiscales para continuar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Identificación Fiscal (RIF)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 88,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: ButtonTheme(
                    alignedDropdown: true,
                    child: DropdownButton<String>(
                      value: _selectedPrefix,
                      borderRadius: BorderRadius.circular(10),
                      dropdownColor: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF94A3B8),
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      items: _prefixes
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPrefix = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextFormField(
                    controller: _rifController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
                      LengthLimitingTextInputFormatter(11),
                    ],
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: '00000000-0',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: _primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: _primaryColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Su información está protegida por encriptación de grado bancario '
                    'y se utiliza únicamente para fines de validación corporativa.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color: _primaryColor.withOpacity(0.85),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primaryColor.withOpacity(0.6),
                elevation: 6,
                shadowColor: _primaryColor.withOpacity(0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continuar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        children: [
          Text(
            'Al continuar, aceptas nuestros Términos de Servicio y Políticas de Privacidad.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 14,
                color: isDark
                    ? const Color(0xFF475569)
                    : const Color(0xFFB0BAC9),
              ),
              const SizedBox(width: 5),
              Text(
                'Powered by FaceID Technologies',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF475569)
                      : const Color(0xFFB0BAC9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ✅ FIX: Convertido a StatefulWidget con const constructor
// El problema original: AnimatedBuilder con width dinámica (110 + 20 * value)
// forzaba al sistema gráfico a crear nuevos buffers en cada frame → BLASTBufferQueue overflow
//
// Solución aplicada:
// 1. Usar Transform.scale en lugar de cambiar width/height dinámicamente
//    → El buffer gráfico se crea UNA sola vez y se reutiliza (solo escala en GPU)
// 2. RepaintBoundary en el padre → aísla repaints al contenedor de la animación
// 3. Animación del scan usa Transform.translate en lugar de Positioned con top dinámico
//    → Mismo beneficio: no recrea buffers, solo transforma en GPU

class _AnimatedScanPlaceholder extends StatefulWidget {
  const _AnimatedScanPlaceholder();

  @override
  State<_AnimatedScanPlaceholder> createState() =>
      _AnimatedScanPlaceholderState();
}

class _AnimatedScanPlaceholderState extends State<_AnimatedScanPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scanAnim,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // ✅ FIX: Transform.scale en lugar de width/height dinámicos
            // Antes: Container(width: 110 + 20 * value) → crea nuevo buffer cada frame
            // Ahora: Transform.scale → reutiliza el buffer existente, solo escala en GPU
            Transform.scale(
              scale: 1.0 + 0.18 * _scanAnim.value,
              child: Opacity(
                opacity: 0.15 + 0.1 * _scanAnim.value,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: const BoxDecoration(
                    color: Color(0xFF137FEC),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Ícono estático — no necesita animarse
            child!,
            // ✅ FIX: Transform.translate en lugar de Positioned con top dinámico
            // Antes: Positioned(top: 20 + 130 * value) → relayout completo cada frame
            // Ahora: Transform.translate → solo mueve en GPU, sin relayout
            Transform.translate(
              offset: Offset(0, -50 + 100 * _scanAnim.value),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        const Color(0xFF137FEC).withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      // ✅ El ícono se pasa como child estático → no se reconstruye en cada frame
      child: const Icon(
        Icons.face_6_rounded,
        color: Color(0xFF137FEC),
        size: 56,
      ),
    );
  }
}

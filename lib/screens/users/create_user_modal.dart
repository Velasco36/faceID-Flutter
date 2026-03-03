// screens/users/create_user_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  // ── Colores ──
  static const Color _primary    = Color(0xFF137FEC);
  static const Color _border     = Color(0xFFE5E7EB);
  static const Color _bg         = Color(0xFFF8FAFC);
  static const Color _textDark   = Color(0xFF0F172A);
  static const Color _textLight  = Color(0xFF94A3B8);
  static const Color _textMedium = Color(0xFF64748B);
  static const Color _adminColor = Color(0xFF7C3AED);
  static const Color _userColor  = Color(0xFF137FEC);

  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController(); // Nuevo controlador

  bool _obscurePassword   = true;
  bool _obscureConfirmPassword = true; // Para el nuevo campo
  bool _isLoading         = false;
  bool _loadingSucursales = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _sucursales          = [];
  Map<String, dynamic>?      _sucursalSeleccionada;
  String                     _rolSeleccionado     = 'user';

  @override
  void initState() {
    super.initState();
    _cargarSucursales();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Dispose del nuevo controlador
    super.dispose();
  }

  // ── API ───────────────────────────────────────────────────────

  Future<void> _cargarSucursales() async {
    final r = await _api.listarSucursales();
    if (!mounted) return;
    if (r['exito'] == true) {
      final data = r['data'];
      List<dynamic> lista = [];
      if (data is List) {
        lista = data;
      } else if (data is Map && data.containsKey('sucursales')) {
        lista = data['sucursales'] as List<dynamic>;
      }
      setState(() {
        _sucursales        = lista.cast<Map<String, dynamic>>();
        _loadingSucursales = false;
      });
    } else {
      setState(() => _loadingSucursales = false);
    }
  }

  Future<void> _crearUsuario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sucursalSeleccionada == null) {
      setState(() => _errorMessage = 'Selecciona una sucursal');
      return;
    }

    setState(() {
      _isLoading    = true;
      _errorMessage = null;
    });

    final resultado = await _api.crearUsuario({
      'username'   : _usernameController.text.trim(),
      'password'   : _passwordController.text,
      'sucursal_id': _sucursalSeleccionada!['id'].toString(),
      'rol'        : _rolSeleccionado,
    });

    if (!mounted) return;

    if (resultado['exito'] == true) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Usuario creado exitosamente'),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      setState(() {
        _errorMessage = resultado['error'] ?? 'Error al crear usuario';
        _isLoading    = false;
      });
    }
  }

  // ── Modal sucursales ──────────────────────────────────────────

  void _abrirModalSucursales() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SucursalPickerSheet(
        sucursales   : _sucursales,
        seleccionada : _sucursalSeleccionada,
        isLoading    : _loadingSucursales,
        onSeleccionar: (s) {
          setState(() => _sucursalSeleccionada = s);
          Navigator.pop(context);
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Username ──────────────────────────────
                      _inputField(
                        controller: _usernameController,
                        label     : 'Usuario',
                        hint      : 'Ej: miguel.garcia',
                        icon      : Icons.person_outline_rounded,
                        validator : (v) {
                          if (v == null || v.trim().isEmpty) return 'El usuario es requerido';
                          if (v.trim().length < 3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // ── Password ──────────────────────────────
                      TextFormField(
                        controller : _passwordController,
                        obscureText: _obscurePassword,
                        style      : const TextStyle(fontSize: 14, color: _textDark),
                        validator  : (v) {
                          if (v == null || v.isEmpty) return 'La contraseña es requerida';
                          if (v.length < 4) return 'Mínimo 4 caracteres';
                          return null;
                        },
                        decoration: _floatingDecoration(
                          label : 'Contraseña',
                          hint  : '••••••••',
                          icon  : Icons.lock_outline_rounded,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textLight,
                              size : 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Confirm Password ──────────────────────────────
                      TextFormField(
                        controller : _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style      : const TextStyle(fontSize: 14, color: _textDark),
                        validator  : (v) {
                          if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                          if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                        decoration: _floatingDecoration(
                          label : 'Confirmar contraseña',
                          hint  : '••••••••',
                          icon  : Icons.lock_outline_rounded,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            child: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _textLight,
                              size : 20,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Sucursal ──────────────────────────────
                      _buildSucursalSelector(),

                      const SizedBox(height: 20),

                      // ── Rol toggle ────────────────────────────
                      _label('Rol'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _rolButton(
                            label: 'Usuario',
                            icon : Icons.person_rounded,
                            value: 'user',
                            color: _userColor,
                          ),
                          const SizedBox(width: 12),
                          _rolButton(
                            label: 'Admin',
                            icon : Icons.admin_panel_settings_rounded,
                            value: 'admin_empresa',
                            color: _adminColor,
                          ),
                        ],
                      ),

                      // ── Error ─────────────────────────────────
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color       : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border      : Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // ── Botón crear ───────────────────────────
                      SizedBox(
                        width : double.infinity,
                        height: 52,
                        child : ElevatedButton(
                          onPressed: _isLoading ? null : _crearUsuario,
                          style: ElevatedButton.styleFrom(
                            backgroundColor        : _primary,
                            foregroundColor        : Colors.white,
                            disabledBackgroundColor: _primary.withOpacity(0.6),
                            shape    : RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width : 22,
                                  height: 22,
                                  child : CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color      : Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Crear usuario',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Selector de sucursal con label flotante ───────────────────

  Widget _buildSucursalSelector() {
    final bool   hasValue = _sucursalSeleccionada != null;
    final String nombre   = hasValue
        ? (_sucursalSeleccionada!['nombre'] ?? _sucursalSeleccionada!['name'] ?? '').toString()
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [

            // ── Campo ────────────────────────────────────────
            GestureDetector(
              onTap: _loadingSucursales ? null : _abrirModalSucursales,
              child: Container(
                height  : 58,
                padding : const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color       : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border      : Border.all(
                    color: hasValue ? _primary : _border,
                    width: hasValue ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store_rounded,
                      size : 20,
                      color: hasValue ? _primary : _textLight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasValue
                            ? nombre
                            : (_loadingSucursales ? '' : 'Seleccionar sucursal'),
                        style: TextStyle(
                          fontSize: 14,
                          color   : hasValue ? _textDark : _textLight,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Flecha estática — sin spinner aquí
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: hasValue ? _primary : _textLight,
                    ),
                  ],
                ),
              ),
            ),

            // ── Label flotante ────────────────────────────────
            Positioned(
              left: 15,
              top : -10,
              child: Container(
                color  : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child  : Text(
                  'Sucursal',
                  style: TextStyle(
                    fontSize  : 12,
                    fontWeight: FontWeight.w500,
                    color     : hasValue ? _primary : _textMedium,
                  ),
                ),
              ),
            ),
          ],
        ),

        // ── Loading debajo del campo ──────────────────────────
        if (_loadingSucursales)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                SizedBox(
                  width : 11,
                  height: 11,
                  child : CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color      : _textLight,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Cargando sucursales...',
                  style: TextStyle(fontSize: 11, color: _textLight),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Widgets helpers ───────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding  : const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color : Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width    : 40,
              height   : 40,
              alignment: Alignment.center,
              child    : const Icon(Icons.arrow_back, color: _textDark, size: 24),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Nuevo usuario',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMedium),
    );
  }

  InputDecoration _floatingDecoration({
    required String  label,
    required String  hint,
    required IconData icon,
    Widget?          suffix,
  }) {
    return InputDecoration(
      labelText          : label,
      labelStyle         : const TextStyle(color: _textMedium, fontSize: 14),
      floatingLabelStyle : const TextStyle(
        color     : _primary,
        fontSize  : 12,
        fontWeight: FontWeight.w500,
      ),
      hintText  : hint,
      hintStyle : const TextStyle(color: _textLight, fontSize: 14),
      prefixIcon: Icon(icon, color: _textLight, size: 20),
      suffixIcon: suffix,
      filled    : true,
      fillColor : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border            : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      enabledBorder     : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
      focusedBorder     : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 1.5)),
      errorBorder       : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String                label,
    required String                hint,
    required IconData              icon,
    String? Function(String?)?     validator,
  }) {
    return TextFormField(
      controller: controller,
      style     : const TextStyle(fontSize: 14, color: _textDark),
      validator : validator,
      decoration: _floatingDecoration(label: label, hint: hint, icon: icon),
    );
  }

  Widget _rolButton({
    required String   label,
    required IconData icon,
    required String   value,
    required Color    color,
  }) {
    final selected = _rolSeleccionado == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _rolSeleccionado = value),
        child: Container(
          padding   : const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color       : selected ? color.withOpacity(0.10) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border      : Border.all(
              color: selected ? color : _border,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : _textLight, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize  : 13,
                  fontWeight: FontWeight.w600,
                  color     : selected ? color : _textMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Modal bottom sheet para seleccionar sucursal
// ═══════════════════════════════════════════════════════════════

class _SucursalPickerSheet extends StatelessWidget {
  final List<Map<String, dynamic>>          sucursales;
  final Map<String, dynamic>?               seleccionada;
  final bool                                isLoading;
  final void Function(Map<String, dynamic>) onSeleccionar;

  static const Color _primary    = Color(0xFF137FEC);
  static const Color _border     = Color(0xFFE5E7EB);
  static const Color _textDark   = Color(0xFF0F172A);
  static const Color _textLight  = Color(0xFF94A3B8);
  static const Color _textMedium = Color(0xFF64748B);

  const _SucursalPickerSheet({
    required this.sucursales,
    required this.seleccionada,
    required this.isLoading,
    required this.onSeleccionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color       : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          // Handle
          Center(
            child: Container(
              margin    : const EdgeInsets.only(top: 12, bottom: 8),
              width     : 40,
              height    : 4,
              decoration: BoxDecoration(
                color       : _border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Container(
                  width     : 36,
                  height    : 36,
                  decoration: BoxDecoration(
                    color       : _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_rounded, color: _primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar sucursal',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    Text(
                      'Elige la sucursal del usuario',
                      style: TextStyle(fontSize: 12, color: _textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Lista
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child  : CircularProgressIndicator(color: _primary, strokeWidth: 2),
            )
          else if (sucursales.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child  : Text(
                'No hay sucursales disponibles',
                style: TextStyle(color: _textLight, fontSize: 14),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics   : const NeverScrollableScrollPhysics(),
              padding   : const EdgeInsets.symmetric(vertical: 8),
              itemCount : sucursales.length,
              separatorBuilder: (_, __) => const Divider(
                height : 1,
                indent : 72,
                color  : Color(0xFFF1F5F9),
              ),
              itemBuilder: (_, i) {
                final s          = sucursales[i];
                final nombre     = (s['nombre'] ?? s['name'] ?? 'Sin nombre').toString();
                final dir        = (s['direccion'] ?? s['address'] ?? '').toString();
                final isSelected = seleccionada?['id'] == s['id'];

                return InkWell(
                  onTap: () => onSeleccionar(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width     : 40,
                          height    : 40,
                          decoration: BoxDecoration(
                            color       : isSelected
                                ? _primary.withOpacity(0.1)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.storefront_outlined,
                            size : 20,
                            color: isSelected ? _primary : _textLight,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: TextStyle(
                                  fontSize  : 14,
                                  fontWeight: FontWeight.w600,
                                  color     : isSelected ? _primary : _textDark,
                                ),
                              ),
                              if (dir.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  dir,
                                  style   : const TextStyle(fontSize: 12, color: _textMedium),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width     : 24,
                            height    : 24,
                            decoration: const BoxDecoration(
                              color : _primary,
                              shape : BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                          )
                        else
                          const Icon(Icons.chevron_right, color: _textLight, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/session_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // FocusNodes necesarios para el autofill
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  final _api = ApiService();

  static const Color _primary = Color(0xFF137FEC);

  String? _rif;
  Map<String, dynamic>? _empresa;
  int? _empresaId;
  List<dynamic>? _sucursales;
  Map<String, dynamic>? _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        try {
          setState(() {
            _rif = args['rif'];
            _empresaId = args['empresaId'];

            final empresaValue = args['empresa'];
            if (empresaValue is String) {
              _empresa = {'nombre': empresaValue};
            } else if (empresaValue is Map) {
              _empresa = empresaValue as Map<String, dynamic>;
            } else {
              _empresa = {'nombre': 'Empresa'};
            }

            if (args['sucursales'] is String) {
              _sucursales = jsonDecode(args['sucursales']);
            } else {
              _sucursales = args['sucursales'];
            }

            if (args['sucursalSeleccionada'] != null) {
              if (args['sucursalSeleccionada'] is String) {
                _sucursalSeleccionada = jsonDecode(args['sucursalSeleccionada']);
              } else {
                _sucursalSeleccionada = args['sucursalSeleccionada'];
              }
            }
          });
        } catch (e) {
          debugPrint('❌ Error parseando argumentos: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Notifica al sistema que el login fue exitoso para que
  /// Android/iOS ofrezca guardar las credenciales (igual que el navegador)
  void _triggerAutofillSave() {
    TextInput.finishAutofillContext(shouldSave: true);
  }

  /// Cancela el guardado si el login falla
  void _cancelAutofillSave() {
    TextInput.finishAutofillContext(shouldSave: false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_empresaId == null) {
      _mostrarError('Error: No se recibió el ID de la empresa');
      return;
    }

    if (_sucursalSeleccionada == null) {
      if (_sucursales != null && _sucursales!.isNotEmpty) {
        setState(() {
          _sucursalSeleccionada = _sucursales!.first as Map<String, dynamic>;
        });
      } else {
        _mostrarError('Error: No hay sucursales disponibles');
        return;
      }
    }

    setState(() => _isLoading = true);

    final int? empresaId = _empresaId;
    final int? sucursalId = _sucursalSeleccionada?['id'];

    if (empresaId == null) {
      setState(() => _isLoading = false);
      _cancelAutofillSave();
      _mostrarError('Error: No se pudo obtener el ID de la empresa');
      return;
    }

    if (sucursalId == null) {
      setState(() => _isLoading = false);
      _cancelAutofillSave();
      _mostrarError('Error: No se pudo obtener el ID de la sucursal');
      return;
    }

    final result = await _api.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      empresaId: empresaId,
      sucursalId: sucursalId,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['exito'] == true) {
      // ✅ Le dice al sistema que guarde las credenciales
      _triggerAutofillSave();

      final data = result['data'] as Map<String, dynamic>;

        await SessionService.saveSession(
        usuario: data['usuario'] as Map<String, dynamic>,
        token: data['token'] as String?, // ← ya normalizado en ApiService
        rif: _rif,
        empresa: _empresa,
        sucursales: _sucursales,
        sucursalSeleccionada:
            (data['sucursal'] as Map<String, dynamic>?) ??
            _sucursalSeleccionada,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('¡Bienvenido! Acceso concedido.'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // ❌ Login fallido: no guardar credenciales
      _cancelAutofillSave();
      _mostrarError(result['error'] ?? 'Error desconocido');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.black87,
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_empresa != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.business, size: 16, color: _primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${_empresa!['nombre'] ?? 'Empresa'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _primary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              if (_sucursalSeleccionada != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.store,
                                      size: 14,
                                      color: _primary.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Sucursal: ${_sucursalSeleccionada!['nombre'] ?? 'Sin nombre'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Hero Icon
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.face_unlock_rounded,
                          color: _primary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Bienvenido de vuelta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Inicia sesión para acceder a tu\npanel de seguridad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      // AutofillGroup: agrupa los campos como un
                      // formulario de login para el sistema.
                      // Android mostrará el chip "Autocompletar"
                      // y iOS mostrará la barra de sugerencias.
                      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      AutofillGroup(
                        child: Column(
                          children: [
                            // Username
                            TextFormField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(color: Colors.black87),
                              autofillHints: const [
                                AutofillHints.username,
                              ],
                              onEditingComplete: () {
                                // Mueve el foco al siguiente campo
                                _usernameFocusNode.nextFocus();
                              },
                              decoration: _floatingLabelInputDecoration(
                                label: 'Nombre de usuario',
                                hint: 'Ej. usuario123',
                                icon: Icons.person_rounded,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'El nombre de usuario es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.password,
                              ],
                              onFieldSubmitted: (_) => _submit(),
                              style: const TextStyle(color: Colors.black87),
                              decoration: _floatingLabelInputDecoration(
                                label: 'Contraseña',
                                hint: 'Ingresa tu contraseña',
                                icon: Icons.lock_rounded,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_rounded
                                        : Icons.visibility_off_rounded,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'La contraseña es requerida';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _primary.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Iniciar Sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Security Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'CONEXIÓN ENCRIPTADA AES-256',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _floatingLabelInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      floatingLabelStyle: const TextStyle(color: _primary, fontSize: 14),
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.8),
      ),
    );
  }
}

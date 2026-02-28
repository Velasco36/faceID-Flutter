import 'dart:convert';
import 'package:flutter/material.dart';
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

  bool _obscurePassword = true;
  bool _isLoading = false;

  final _api = ApiService();

  static const Color _primary = Color(0xFF137FEC);

  // Variables para almacenar los datos recibidos
  String? _rif;
  Map<String, dynamic>? _empresa;
  int? _empresaId;
  List<dynamic>? _sucursales;
  Map<String, dynamic>? _sucursalSeleccionada;

  @override
  void initState() {
    super.initState();
    // Recibir argumentos cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        try {
          setState(() {
            _rif = args['rif'];
            _empresaId = args['empresaId'];

            // ✅ CORREGIDO: Manejar empresa correctamente
            final empresaValue = args['empresa'];
            if (empresaValue is String) {
              // Si es un String simple, crear un mapa con ese nombre
              _empresa = {'nombre': empresaValue};
            } else if (empresaValue is Map) {
              // Si ya es un mapa, usarlo directamente
              _empresa = empresaValue as Map<String, dynamic>;
            } else {
              _empresa = {'nombre': 'Empresa'};
            }

            // ✅ Manejar sucursales - puede ser List o String JSON
            if (args['sucursales'] is String) {
              _sucursales = jsonDecode(args['sucursales']);
            } else {
              _sucursales = args['sucursales'];
            }

            // ✅ Manejar sucursal seleccionada
            if (args['sucursalSeleccionada'] != null) {
              if (args['sucursalSeleccionada'] is String) {
                _sucursalSeleccionada = jsonDecode(
                  args['sucursalSeleccionada'],
                );
              } else {
                _sucursalSeleccionada = args['sucursalSeleccionada'];
              }
            }
          });

          // 👀 IMPRIMIR LOS DATOS RECIBIDOS
          _imprimirDatosRecibidos();
        } catch (e) {
          print('❌ Error parseando argumentos: $e');
        }
      } else {
        print('⚠️ No se recibieron argumentos en LoginScreen');
      }
    });
  }

  void _imprimirDatosRecibidos() {
    print('══════════════════════════════════════════════');
    print('📱 DATOS RECIBIDOS EN LOGIN SCREEN');
    print('══════════════════════════════════════════════');
    print('🔹 RIF: $_rif');
    print('🔹 Empresa ID: $_empresaId');
    print('🔹 Empresa: $_empresa');
    print('🔹 Empresa nombre: ${_empresa?['nombre']}');
    print('🔹 Sucursales: $_sucursales');
    print('🔹 Sucursales length: ${_sucursales?.length}');
    print('🔹 Sucursal Seleccionada: $_sucursalSeleccionada');
    print('══════════════════════════════════════════════');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que tenemos el ID de la empresa
    if (_empresaId == null) {
      _mostrarError('Error: No se recibió el ID de la empresa');
      return;
    }

    // 👀 VERIFICAR SUCURSALES
    print('🔍 VERIFICANDO SUCURSALES:');
    print('══════════════════════════════════════════════');
    print('_sucursales: $_sucursales');
    print('_sucursales.runtimeType: ${_sucursales.runtimeType}');

    if (_sucursales != null) {
      print('_sucursales.length: ${_sucursales!.length}');
      if (_sucursales!.isNotEmpty) {
        print('Primera sucursal: ${_sucursales!.first}');
        print('Primera sucursal id: ${(_sucursales!.first as Map)['id']}');
        print(
          'Primera sucursal nombre: ${(_sucursales!.first as Map)['nombre']}',
        );
      }
    } else {
      print('_sucursales es NULL');
    }
    print('══════════════════════════════════════════════');

    // Si no hay sucursal seleccionada, usar la primera de la lista
    if (_sucursalSeleccionada == null) {
      if (_sucursales != null && _sucursales!.isNotEmpty) {
        setState(() {
          _sucursalSeleccionada = _sucursales!.first as Map<String, dynamic>;
        });
        print(
          '✅ Usando primera sucursal automáticamente: ${_sucursalSeleccionada!['nombre']}',
        );
      } else {
        _mostrarError('Error: No hay sucursales disponibles');
        return;
      }
    }

    setState(() => _isLoading = true);

    // Obtener IDs
    int? empresaId = _empresaId;
    int? sucursalId = _sucursalSeleccionada?['id'];

    // Validar IDs
    if (empresaId == null) {
      setState(() => _isLoading = false);
      _mostrarError('Error: No se pudo obtener el ID de la empresa');
      return;
    }

    if (sucursalId == null) {
      setState(() => _isLoading = false);
      _mostrarError('Error: No se pudo obtener el ID de la sucursal');
      return;
    }

    print('📤 Enviando login con:');
    print('   • Usuario: ${_usernameController.text.trim()}');
    print('   • empresa_id: $empresaId');
    print('   • sucursal_id: $sucursalId');
    print('   • Sucursal: ${_sucursalSeleccionada!['nombre']}');

    final result = await _api.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      empresaId: empresaId,
      sucursalId: sucursalId,
    );

    setState(() => _isLoading = false);
    if (!mounted) return;

    if (result['exito'] == true) {
      // Guardar en sesión después del login exitoso
      await SessionService.saveSession(
        usuario: result['data']['usuario'] ?? result['data'],
        token: result['data']['token'],
        rif: _rif,
        empresa: _empresa,
        sucursales: _sucursales,
        sucursalSeleccionada: _sucursalSeleccionada,
      );

      // Mostrar mensaje de éxito
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Redirigir a home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
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
        title: Text(
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
                      // Información de la empresa (solo informativo)
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
                                  Icon(
                                    Icons.business,
                                    size: 16,
                                    color: _primary,
                                  ),
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
                      Text(
                        'Bienvenido de vuelta',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para acceder a tu\npanel de seguridad',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Username
                      TextFormField(
                        controller: _usernameController,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.black87),
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
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
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
                          Icon(
                            Icons.shield_rounded,
                            size: 14,
                            color: Colors.black38,
                          ),
                          const SizedBox(width: 6),
                          Text(
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
      hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF137FEC), width: 1.8),
      ),
    );
  }
}

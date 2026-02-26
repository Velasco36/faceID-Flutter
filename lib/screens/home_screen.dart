// home_screen.dart
import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'verification_screen.dart';
import 'history_screen.dart';
import 'navigation_footer.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import './auth/login_screen.dart';
import './animate/FaceScanAnimation.dart';

final ApiService _apiService = ApiService();

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _usuario;
  String? _username;
  bool? _esAdmin;
  String? _rol;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

Future<void> _cargarDatosUsuario() async {
    try {
      final usuario = await SessionService.getUsuario();

      setState(() {
        _usuario = usuario;
        _username = usuario?['username'];
        _rol = usuario?['rol'];
        _esAdmin = usuario?['rol'] == 'admin_empresa'; // ✅ derivado del rol
        _isLoading = false;
      });

      print('✅ Usuario cargado:');
      print('   - username: $_username');
      print('   - rol: $_rol');
      print('   - es_admin: $_esAdmin');
    } catch (e) {
      print('❌ Error cargando datos de usuario: $e');
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _logout() async {
    print('🚪 [HomeScreen] Iniciando proceso de logout...');

    try {
      if (!mounted) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(
            color: Colors.blue,
            strokeWidth: 2.5,
          ),
        ),
      );

      // Debug antes del logout
      final usuarioBefore = await SessionService.getUsuario();
      print('📊 Usuario antes del logout: $usuarioBefore');

      // Llamar al API
      print('📤 Llamando a API logout...');
      final respuesta = await _apiService.logout();
      print('📥 Respuesta del logout: $respuesta');

      // Limpiar sesión local siempre
      print('🧹 Limpiando sesión local...');
      await SessionService.clearSession();

      // Debug después del logout
      final usuarioAfter = await SessionService.getUsuario();
      print(
        '🔍 Usuario después del logout: ${usuarioAfter ?? "null (limpiado ✅)"}',
      );

      // Cerrar diálogo de carga
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesión cerrada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error en logout: $e');

      // Cerrar diálogo si está abierto
      if (mounted) Navigator.pop(context);

      // Limpiar sesión local aunque haya error
      await SessionService.clearSession();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cerrar sesión: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF137FEC);
    final backgroundColor = const Color(0xFFF6F7F8);
    final secondaryTextColor = const Color(0xFF617589);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF111418)),
          onPressed: () {
            print('📋 Mostrando datos de usuario:');
            print('   Username: $_username');
            print('   Es Admin: $_esAdmin');
            print('   Rol: $_rol');
          },
        ),
        title: const Text(
          'Reconocimiento Facial',
          style: TextStyle(
            color: Color(0xFF111418),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF111418)),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 2,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Hero Illustration Area - AHORA CON LA ANIMACIÓN REUTILIZABLE
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Animación de rostro (componente reutilizable)
                            const SimpleFaceScanAnimation(
                              size: 0.65,
                              repeat: true,
                            ),

                            const SizedBox(height: 18),

                            Text(
                              'Bienvenido${_username != null ? " $_username" : ""}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111418),
                              ),
                            ),

                            if (_esAdmin != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _esAdmin!
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _esAdmin! ? 'Administrador' : 'Usuario',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _esAdmin!
                                          ? Colors.blue[800]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // Action Buttons
                      Column(
                        children: [
                          // Register Button - Solo visible para administradores
                          if (_esAdmin == true) ...[
                            Material(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  print(
                                    '📝 Navegando a RegisterScreen (Admin: $_esAdmin)',
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_add,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: const [
                                            Text(
                                              'Registrar Persona',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Crear nuevo perfil biométrico',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16), // Espaciado condicional
                          ],

                          // Verify Button
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: primaryColor.withOpacity(0.1),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  print('🔍 Navegando a VerifyScreen');
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const VerifyScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.photo_camera,
                                          color: primaryColor,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Verificar Persona',
                                              style: TextStyle(
                                                color: Color(0xFF111418),
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Validar identidad existente',
                                              style: TextStyle(
                                                color: secondaryTextColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

          // Navigation Footer - Solo visible para administradores
          if (_esAdmin == true) ...[
            NavigationFooter(
              currentIndex: 0,
              onItemTapped: (index) {
                if (index == 1) {
                  print('📋 Admin accediendo a HistoryScreen');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                }
              },
              primaryColor: primaryColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 8),
          ],
          // Sin else - no se muestra nada para usuarios no admin
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

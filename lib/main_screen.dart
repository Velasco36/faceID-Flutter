// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'custom_tab_bar.dart';
import './screens/home_screen.dart';
import './screens/history_screen.dart';
import './screens/brances/branches_screen.dart';
import 'screens/company/session_company.dart';
import 'services/session_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  bool _esAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRol();
  }

Future<void> _cargarRol() async {
    try {
      final rol = await SessionService.getRol();
      print('🔑 [MainScreen] Rol obtenido: $rol');
      print('🔑 [MainScreen] Es admin: ${rol == 'admin_empresa'}');
      setState(() {
        _esAdmin = rol == 'admin_empresa';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ [MainScreen] Error cargando rol: $e');
      setState(() => _isLoading = false);
    }
  }
  void setIndex(int index) {
    setState(() => currentIndex = index);
  }

  List<Widget> get _screens => [
    const HomeScreen(), // tab 0 - Inicio
    const MovimientosScreen(), // tab 1 - Historial
  
    const SucursalesScreen(), // tab 3 - Sucursales


  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _screens[currentIndex],
    bottomNavigationBar: _esAdmin
          ? CustomTabBar(
              currentIndex: currentIndex, // ✅ pasa el índice
              onTap: setIndex, // ✅ pasa el callback
            )
          : null,
    );
  }
}

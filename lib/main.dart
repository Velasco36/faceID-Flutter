import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'screens/home_screen.dart';
import 'screens/verification_screen.dart';
import 'screens/company/session_company.dart';
import 'screens/brances/branches_screen.dart';
import 'screens/animate/FaceScanAnimation.dart';
import 'screens/auth/register_user_screen.dart';
import 'screens/auth/login_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

List<CameraDescription> cameras = [];

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  HttpOverrides.global = MyHttpOverrides();

  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reconocimiento Facial',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/company': (context) => const SessionCompany(),
        '/branches': (context) => const SucursalesScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Remueve splash nativo apenas Flutter esté listo
    FlutterNativeSplash.remove();
  }

  void _navigateToNext() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SimpleFaceScanAnimation(
        size: 0.7,
        repeat: false,
        onFinish: _navigateToNext,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

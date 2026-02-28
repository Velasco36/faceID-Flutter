import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './session_service.dart';
import 'package:flutter/foundation.dart'; // ← para debugPrint


class ApiService {
  // ⚠️ Cambia esta IP por la IP de tu PC donde corre Flask
  // Si pruebas en emulador Android usa: http://10.0.2.2:5000
  // Si pruebas en dispositivo físico usa: http://TU_IP_LOCAL:5000
  // Ejemplo: http://192.168.1.100:5000
  // =======================================================================
  // =======================================================================
  // local
  // local
  // static const String baseUrl = 'http://192.168.1.249:5000';
    static const String baseUrl = 'http://192.168.1.2:5000';
  // =======================================================================
  // =======================================================================

  // server
  // static const String baseUrl = 'https://back-face-id--migue16velasco.replit.app';



  // ─────────────────────────────────────────
  // REGISTRAR PERSONA
  // ─────────────────────────────────────────

Future<Map<String, dynamic>> registrarPersona({
    required String cedula,
    required String nombre,
    required String imagenPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/registrar');
      final request = http.MultipartRequest('POST', uri);

      // ✅ Token de autorización
      final token = await SessionService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['cedula'] = cedula;
      request.fields['nombre'] = nombre;
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenPath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 POST /api/personas/registrar → ${response.statusCode}');
      debugPrint('📥 Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'exito': false, 'error': 'Sesión expirada. Vuelve a iniciar sesión.'};
      } else if (response.statusCode == 404) {
        return {'exito': false, 'error': 'Endpoint no encontrado. Verifica la URL del servidor.'};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? data['mensaje'] ?? 'Error desconocido',
          'detalles': data['detalles'],
        };
      }
    } on SocketException {
      return {
        'exito': false,
        'error': 'No se pudo conectar al servidor. Verifica la IP y que Flask esté corriendo.',
      };
    }

}

  // ─────────────────────────────────────────
  // VERIFICAR IDENTIDAD (contra toda la BD)
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> verificarIdentidad({
    required String imagenPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/verificar');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenPath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error en verificación',
        };
      }
    } on SocketException {
      return {
        'exito': false,
        'error': 'No se pudo conectar al servidor.',
      };
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }

  // ─────────────────────────────────────────
  // VERIFICAR CONTRA UNA CÉDULA ESPECÍFICA
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> verificarContraCedula({
    required String cedula,
    required String imagenPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/verificar/$cedula');
      final request = http.MultipartRequest('POST', uri);

      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenPath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error en verificación',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }

  // ─────────────────────────────────────────
  // LISTAR PERSONAS
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> listarPersonas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/personas'),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else {
        return {'exito': false, 'error': 'Error al obtener personas'};
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }

    Future<Map<String, dynamic>> movimientosPorPersona({
    String? cedula,
    String? nombre,
  }) async {
    if ((cedula == null || cedula.isEmpty) &&
        (nombre == null || nombre.isEmpty)) {
      return {'exito': false, 'error': 'Se requiere cédula o nombre'};
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/movimientos/persona'),
      );

      if (cedula != null && cedula.isNotEmpty) {
        request.fields['cedula'] = cedula;
      } else if (nombre != null && nombre.isNotEmpty) {
        request.fields['nombre'] = nombre;
      }

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 300) {
        // Múltiples resultados encontrados
        return {
          'exito': false,
          'multiples': true,
          'data': data,
        };
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error al obtener movimientos',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }


    // ─────────────────────────────────────────
  // OBTENER ESTADÍSTICAS DE MOVIMIENTOS
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/movimientos'))
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error al obtener estadísticas',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }


  // ─────────────────────────────────────────
  // HEALTH CHECK
  // ─────────────────────────────────────────
  Future<bool> verificarConexion() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

    // ─────────────────────────────────────────
  // REGISTRO DE USUARIO
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> registro({
    required String username,
    required String password,
    String rol = 'user',
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/registro');
      final request = http.MultipartRequest('POST', uri);

      request.fields['username'] = username;
      request.fields['password'] = password;
      request.fields['rol'] = rol;

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? data['message'] ?? 'Error en registro',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }


  // ─────────────────────────────────────────
  // LOGIN DE USUARIO
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    int? empresaId,
    int? sucursalId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');

      final Map<String, dynamic> body = {
        'username': username,
        'password': password,
      };

      if (empresaId != null) body['empresa_id'] = empresaId;
      if (sucursalId != null) body['sucursal_id'] = sucursalId;

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // ✅ Normalizar: el backend retorna "access_token" → lo mapeamos a "token"
        return {
          'exito': true,
          'data': {
            'token': data['access_token'], // ← normalizado
            'usuario': data['usuario'],
            'sucursal': data['sucursal'],
          },
        };
      } else {
        return {
          'exito': false,
          'error':
              data['error'] ?? data['message'] ?? 'Credenciales incorrectas',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    }
  }

  // ──────────────────────────────────────t───
  // Logout DE USUARIO
  // ─────────────────────────────────────────
Future<Map<String, dynamic>> logout() async {
    try {
      final uri = Uri.parse('$baseUrl/api/auth/logout');

      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error al cerrar sesión',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
    }
  }
// ─────────────────────────────────────────
// OBTENER SUCURSALES DE UNA EMPRESA POR RIF
// ─────────────────────────────────────────

Future<Map<String, dynamic>> getSucursalesPorRif(String rif) async {
    try {
      final uri = Uri.parse('$baseUrl/api/empresas/rif/$rif/sucursales');

      final response = await http.get(uri).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);
      print('📥 getSucursalesPorRif - Respuesta completa: $data');

      // 👀 Logs de depuración
      print('🔍 Verificando campos:');
      print('  • data["empresa"]: ${data['empresa']}');
      print('  • data["empresa_id"]: ${data['empresa_id']}');
      print('  • data["sucursales"] es List? ${data['sucursales'] is List}');

      if (data['sucursales'] != null && data['sucursales'] is List) {
        print('  • Primera sucursal: ${data['sucursales'][0]}');
        print(
          '  • empresa_id en sucursal: ${data['sucursales'][0]['empresa_id']}',
        );
      }

      if (response.statusCode == 200) {
        // Intentar obtener empresa_id de la respuesta
        int? empresaId = data['empresa_id'];

        // Si no viene, intentar obtenerlo de la primera sucursal
        if (empresaId == null &&
            data['sucursales'] != null &&
            data['sucursales'] is List &&
            data['sucursales'].isNotEmpty) {
          empresaId = data['sucursales'][0]['empresa_id'] as int?;
          print('✅ empresa_id obtenido de la primera sucursal: $empresaId');
        }

        return {
          'exito': true,
          'data': data['sucursales'],
          'empresa': data['empresa'],
          'empresa_id': empresaId,
          'total_sucursales': data['total_sucursales'],
        };
      } else {
        return {
          'exito': false,
          'error': 'Error del servidor: ${response.statusCode}',
          'codigo': response.statusCode,
        };
      }
    } catch (e) {
      return {'exito': false, 'error': 'Error de conexión: $e'};
    }
  }

}

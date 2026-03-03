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
    static const String baseUrl = 'http://192.168.1.4:5000';
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
// ─────────────────────────────────────────
  // VERIFICAR IDENTIDAD
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> verificarIdentidad({
    required String imagenPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/verificar'); // ← URL corregida
      final request = http.MultipartRequest('POST', uri);

      // ✅ Token de autorización (igual que en registrarPersona)
      final token = await SessionService.getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenPath),
      );

      debugPrint('══════════════════════════════════════════');
      debugPrint('📤 POST ${uri.toString()}');
      debugPrint('🔑 Authorization: Bearer ${token ?? "NULL - sin token"}');
      debugPrint('🖼  imagen = $imagenPath');
      debugPrint('══════════════════════════════════════════');

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 Status: ${response.statusCode}');
      debugPrint('📥 Body:   ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {
          'exito': false,
          'error': 'Sesión expirada. Vuelve a iniciar sesión.',
        };
      } else if (response.statusCode == 404) {
        return {
          'exito': false,
          'error': 'Endpoint no encontrado. Verifica la URL del servidor.',
        };
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error en verificación',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
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



  // LISTAR MOVIMIENTOS — paginado infinito
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> listarMovimientos({
    int page = 1,
    int perPage = 10,
    String? sucursalId,
    String? tipo,
    String? cedula,
    String? fechaInicio,
    String? fechaFin,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
        if (sucursalId != null) 'sucursal_id': sucursalId,
        if (tipo != null) 'tipo': tipo,
        if (cedula != null) 'cedula': cedula,
        if (fechaInicio != null) 'fecha_inicio': fechaInicio,
        if (fechaFin != null) 'fecha_fin': fechaFin,
      };

      final uri = Uri.parse(
        '$baseUrl/api/movimientos',
      ).replace(queryParameters: params);
      final token = await SessionService.getToken();

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📤 GET /api/movimientos?page=$page → ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {
          'exito': false,
          'error': 'Sesión expirada. Vuelve a iniciar sesión.',
        };
      } else {
        return {'exito': false, 'error': data['error'] ?? 'Error desconocido'};
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    }
  }

  // ─────────────────────────────────────────
  // LISTAR SUCURSALES
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> listarSucursales() async {
    try {
      final uri = Uri.parse('$baseUrl/api/sucursales');
      final token = await SessionService.getToken();

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'exito': false, 'error': 'Sesión expirada.'};
      } else {
        return {'exito': false, 'error': data['error'] ?? 'Error desconocido'};
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    }
  }


  // ─────────────────────────────────────────
  // crear SUCURSALES
  // ─────────────────────────────────────────
Future<Map<String, dynamic>> crearSucursal(
    String nombre,
    String direccion,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/api/sucursales');
      final token = await SessionService.getToken();

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'nombre': nombre, 'direccion': direccion}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'exito': true, 'data': data};
      } else if (response.statusCode == 401) {
        return {'exito': false, 'error': 'Sesión expirada.'};
      } else if (response.statusCode == 400) {
        return {'exito': false, 'error': data['error'] ?? 'Datos inválidos'};
      } else if (response.statusCode == 409) {
        return {
          'exito': false,
          'error': data['error'] ?? 'La sucursal ya existe',
        };
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error al crear sucursal',
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on FormatException {
      return {
        'exito': false,
        'error': 'Error al procesar la respuesta del servidor.',
      };
    } catch (e) {
      return {'exito': false, 'error': 'Error inesperado: $e'};
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

      if (response.statusCode == 200) {
        // Intentar obtener empresa_id de la respuesta
        int? empresaId = data['empresa_id'];

        // Si no viene, intentar obtenerlo de la primera sucursal
        if (empresaId == null &&
            data['sucursales'] != null &&
            data['sucursales'] is List &&
            data['sucursales'].isNotEmpty) {
          empresaId = data['sucursales'][0]['empresa_id'] as int?;

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

// ─────────────────────────────────────────
  // OBTENER TODOS LOS USUARIOS
  // ─────────────────────────────────────────

  Future<Map<String, dynamic>> getAllUsers() async {
    try {
      final uri = Uri.parse('$baseUrl/api/all-users');
      final token = await SessionService.getToken();

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'exito': true,
          'data': data,
          'total': data is List ? data.length : (data['total'] ?? 0),
        };
      } else if (response.statusCode == 401) {
        return {'exito': false, 'error': 'Sesión expirada.'};
      } else if (response.statusCode == 403) {
        return {
          'exito': false,
          'error': 'No tienes permisos para ver usuarios',
        };
      } else if (response.statusCode == 404) {
        return {'exito': false, 'error': 'Endpoint no encontrado'};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error al obtener usuarios',
          'codigo': response.statusCode,
        };
      }
    } on SocketException {
      return {'exito': false, 'error': 'No se pudo conectar al servidor.'};
    } on FormatException {
      return {
        'exito': false,
        'error': 'Error al procesar la respuesta del servidor.',
      };
    } catch (e) {
      return {'exito': false, 'error': 'Error inesperado: $e'};
    }
  }

}

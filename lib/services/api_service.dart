import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // ⚠️ Cambia esta IP por la IP de tu PC donde corre Flask
  // Si pruebas en emulador Android usa: http://10.0.2.2:5000
  // Si pruebas en dispositivo físico usa: http://TU_IP_LOCAL:5000
  // Ejemplo: http://192.168.1.100:5000
  static const String baseUrl = 'http://192.168.1.180:5000';



  // ─────────────────────────────────────────
  // REGISTRAR PERSONA
  // ─────────────────────────────────────────
  Future<Map<String, dynamic>> registrarPersona({
    required String cedula,
    required String nombre,
    required String imagenPath,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/registrar');
      final request = http.MultipartRequest('POST', uri);

      request.fields['cedula'] = cedula;
      request.fields['nombre'] = nombre;
      request.files.add(
        await http.MultipartFile.fromPath('imagen', imagenPath),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'exito': true, 'data': data};
      } else {
        return {
          'exito': false,
          'error': data['error'] ?? 'Error desconocido',
          'detalles': data['detalles'],
        };
      }
    } on SocketException {
      return {
        'exito': false,
        'error': 'No se pudo conectar al servidor. Verifica la IP y que Flask esté corriendo.',
      };
    } on Exception catch (e) {
      return {'exito': false, 'error': 'Error: ${e.toString()}'};
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
}

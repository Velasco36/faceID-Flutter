// services/session_service.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyUsuario = 'usuario_data';
  static const _keyToken = 'auth_token';        // 👈 NUEVO: Para el token
  static const _keyRif = 'rif_empresa';         // 👈 NUEVO
  static const _keyEmpresa = 'empresa_data';    // 👈 NUEVO
  static const _keySucursales = 'sucursales_data'; // 👈 NUEVO
  static const _keySucursalSeleccionada = 'sucursal_seleccionada'; // 👈 NUEVO

  // ── Guardar sesión completa ────
  static Future<void> saveSession({
    required Map<String, dynamic> usuario,
    String? token,                    // 👈 NUEVO
    String? rif,                      // 👈 NUEVO
    Map<String, dynamic>? empresa,    // 👈 NUEVO
    List<dynamic>? sucursales,        // 👈 NUEVO
    Map<String, dynamic>? sucursalSeleccionada, // 👈 NUEVO
  }) async {
    // Guardar usuario
    await _storage.write(key: _keyUsuario, value: jsonEncode(usuario));

    // Guardar token si existe
    if (token != null) {
      await _storage.write(key: _keyToken, value: token);
    }

    // Guardar datos adicionales
    if (rif != null) {
      await _storage.write(key: _keyRif, value: rif);
    }

    if (empresa != null) {
      await _storage.write(key: _keyEmpresa, value: jsonEncode(empresa));
    }

    if (sucursales != null) {
      await _storage.write(key: _keySucursales, value: jsonEncode(sucursales));
    }

    if (sucursalSeleccionada != null) {
      await _storage.write(key: _keySucursalSeleccionada, value: jsonEncode(sucursalSeleccionada));
    }
  }

  // ── Leer token ──────────────────────────────
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // ── Leer datos de usuario ──────────────────────────────
  static Future<Map<String, dynamic>?> getUsuario() async {
    final raw = await _storage.read(key: _keyUsuario);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Leer RIF ──────────────────────────────
  static Future<String?> getRif() async {
    return await _storage.read(key: _keyRif);
  }

  // ── Leer empresa ──────────────────────────────
  static Future<Map<String, dynamic>?> getEmpresa() async {
    final raw = await _storage.read(key: _keyEmpresa);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Leer sucursales ──────────────────────────────
  static Future<List<dynamic>?> getSucursales() async {
    final raw = await _storage.read(key: _keySucursales);
    if (raw == null) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  // ── Leer sucursal seleccionada ──────────────────────────────
  static Future<Map<String, dynamic>?> getSucursalSeleccionada() async {
    final raw = await _storage.read(key: _keySucursalSeleccionada);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Accesos rápidos a campos frecuentes ───────────────
  static Future<int?> getEmpresaId() async {
    final empresa = await getEmpresa();
    return empresa?['id'] as int?;
  }

  static Future<int?> getSucursalId() async {
    final sucursal = await getSucursalSeleccionada();
    return sucursal?['id'] as int?;
  }

  static Future<String?> getRol() async {
    final u = await getUsuario();
    return u?['rol'] as String?;
  }

  // ── Verificar si hay sesión activa ─────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _keyToken);
    return token != null && token.isNotEmpty;
  }

  // ── Borrar sesión (logout) ─────────────────────────────
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}

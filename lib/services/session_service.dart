// lib/services/session_service.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ── Keys ──────────────────────────────────────────────
  static const _keyToken   = 'auth_token';
  static const _keyUsuario = 'usuario_data';

  // ── Guardar sesión completa ────────────────────────────
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> usuario,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken,   value: token),
      _storage.write(key: _keyUsuario, value: jsonEncode(usuario)),
    ]);
  }

  // ── Leer token ─────────────────────────────────────────
  static Future<String?> getToken() async {
    return _storage.read(key: _keyToken);
  }

  // ── Leer datos de usuario ──────────────────────────────
  static Future<Map<String, dynamic>?> getUsuario() async {
    final raw = await _storage.read(key: _keyUsuario);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Verificar si hay sesión activa ─────────────────────
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Borrar sesión (logout) ─────────────────────────────
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}

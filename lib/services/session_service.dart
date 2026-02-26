import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _keyUsuario = 'usuario_data';

  // ── Guardar sesión (solo usuario, no hay token JWT) ────
  static Future<void> saveSession({
    required Map<String, dynamic> usuario,
  }) async {
    await _storage.write(key: _keyUsuario, value: jsonEncode(usuario));
  }

  // ── Leer datos de usuario ──────────────────────────────
  static Future<Map<String, dynamic>?> getUsuario() async {
    final raw = await _storage.read(key: _keyUsuario);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Accesos rápidos a campos frecuentes ───────────────
  static Future<int?> getEmpresaId() async {
    final u = await getUsuario();
    return u?['empresa_id'] as int?;
  }

  static Future<int?> getSucursalId() async {
    final u = await getUsuario();
    return u?['sucursal_id'] as int?;
  }

  static Future<String?> getRol() async {
    final u = await getUsuario();
    return u?['rol'] as String?;
  }

  // ── Verificar si hay sesión activa ─────────────────────
  static Future<bool> isLoggedIn() async {
    final raw = await _storage.read(key: _keyUsuario);
    return raw != null && raw.isNotEmpty;
  }

  // ── Borrar sesión (logout) ─────────────────────────────
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}

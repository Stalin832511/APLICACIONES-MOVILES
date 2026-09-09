import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Maneja el login contra la API y el almacenamiento seguro
/// de los datos de sesión.
///
/// El token, correo e IdUsuario se almacenan de forma segura.
/// No se guardan credenciales en SQLite.
class AuthService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _emailKey = 'user_email';
  static const _userIdKey = 'user_id';

  /// Hace login contra POST /api/auth/login.
  ///
  /// Si es exitoso, guarda:
  /// - token JWT
  /// - correo
  /// - IdUsuario
  static Future<bool> login(
    String email,
    String password,
  ) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/login',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'email': email,
            'password': password,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final token = data['token'] as String;

      final idUsuario =
          data['idUsuario'] as int;

      await _storage.write(
        key: _tokenKey,
        value: token,
      );

      await _storage.write(
        key: _emailKey,
        value: email,
      );

      await _storage.write(
        key: _userIdKey,
        value: idUsuario.toString(),
      );

      return true;
    }

    return false;
  }

  /// Revisa si existe una sesión anterior.
  static Future<bool> hasActiveSession() async {
    final token =
        await _storage.read(key: _tokenKey);

    return token != null &&
        token.isNotEmpty;
  }

  /// Obtiene el token JWT.
  static Future<String?> getToken() async {
    return _storage.read(
      key: _tokenKey,
    );
  }

  /// Obtiene el correo del usuario.
  static Future<String?> getUserEmail() async {
    return _storage.read(
      key: _emailKey,
    );
  }

  /// Obtiene el IdUsuario.
  static Future<int?> getUserId() async {
    final value = await _storage.read(
      key: _userIdKey,
    );

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }

  /// Cierra la sesión.
  ///
  /// La limpieza de SQLite y SyncQueue
  /// se agregará posteriormente.
  static Future<void> logout() async {
    await _storage.delete(
      key: _tokenKey,
    );

    await _storage.delete(
      key: _emailKey,
    );

    await _storage.delete(
      key: _userIdKey,
    );
  }
}
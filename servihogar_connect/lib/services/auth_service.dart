import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Maneja la autenticación contra la API y el almacenamiento seguro
/// de los datos de sesión.
///
/// Se almacenan de forma segura:
/// - Access Token
/// - Refresh Token
/// - Correo
/// - IdUsuario
///
/// No se guardan credenciales en SQLite.
class AuthService {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'user_email';
  static const _userIdKey = 'user_id';

  // ==========================================================
  // LOGIN
  // ==========================================================

  /// Hace login contra POST /api/auth/login.
  ///
  /// Si es exitoso, guarda:
  /// - Access Token JWT
  /// - Refresh Token
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

      final refreshToken =
          data['refreshToken'] as String;

      final idUsuario =
          data['idUsuario'] as int;

      // ------------------------------------------------------
      // ACCESS TOKEN
      // ------------------------------------------------------

      await _storage.write(
        key: _tokenKey,
        value: token,
      );

      // ------------------------------------------------------
      // REFRESH TOKEN
      // ------------------------------------------------------

      await _storage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );

      // ------------------------------------------------------
      // DATOS DEL USUARIO
      // ------------------------------------------------------

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

  // ==========================================================
  // SESIÓN
  // ==========================================================

  /// Revisa si existe una sesión anterior.
  static Future<bool> hasActiveSession() async {
    final token =
        await _storage.read(
          key: _tokenKey,
        );

    return token != null &&
        token.isNotEmpty;
  }

  // ==========================================================
  // ACCESS TOKEN
  // ==========================================================

  /// Obtiene el Access Token JWT.
  static Future<String?> getToken() async {
    return _storage.read(
      key: _tokenKey,
    );
  }

  /// Guarda un nuevo Access Token.
  static Future<void> saveToken(
    String token,
  ) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  // ==========================================================
  // REFRESH TOKEN
  // ==========================================================

  /// Obtiene el Refresh Token.
  static Future<String?> getRefreshToken() async {
    return _storage.read(
      key: _refreshTokenKey,
    );
  }

  /// Guarda un nuevo Refresh Token.
  static Future<void> saveRefreshToken(
    String refreshToken,
  ) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: refreshToken,
    );
  }

  /// Solicita nuevos tokens al backend.
  ///
  /// POST /api/auth/refresh
  ///
  /// El backend devuelve:
  /// - nuevo Access Token
  /// - nuevo Refresh Token
  ///
  /// Los dos se almacenan nuevamente de forma segura.
  static Future<bool> refreshToken() async {
    final refreshToken =
        await getRefreshToken();

    if (refreshToken == null ||
        refreshToken.isEmpty) {
      return false;
    }

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/auth/refresh',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'refreshToken': refreshToken,
            }),
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return false;
      }

      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      final newToken =
          data['token'] as String?;

      final newRefreshToken =
          data['refreshToken'] as String?;

      if (newToken == null ||
          newToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return false;
      }

      // ------------------------------------------------------
      // GUARDAR NUEVO ACCESS TOKEN
      // ------------------------------------------------------

      await saveToken(newToken);

      // ------------------------------------------------------
      // GUARDAR NUEVO REFRESH TOKEN
      //
      // El backend utiliza rotación de refresh tokens.
      // Por eso debemos reemplazar el anterior.
      // ------------------------------------------------------

      await saveRefreshToken(
        newRefreshToken,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ==========================================================
  // DATOS DEL USUARIO
  // ==========================================================

  /// Obtiene el correo del usuario.
  static Future<String?> getUserEmail() async {
    return _storage.read(
      key: _emailKey,
    );
  }

  /// Obtiene el IdUsuario.
  static Future<int?> getUserId() async {
    final value =
        await _storage.read(
          key: _userIdKey,
        );

    if (value == null) {
      return null;
    }

    return int.tryParse(value);
  }

  // ==========================================================
  // LOGOUT
  // ==========================================================

  /// Cierra la sesión y elimina los tokens
  /// y datos almacenados localmente.
  static Future<void> logout() async {
    await _storage.delete(
      key: _tokenKey,
    );

    await _storage.delete(
      key: _refreshTokenKey,
    );

    await _storage.delete(
      key: _emailKey,
    );

    await _storage.delete(
      key: _userIdKey,
    );
  }
}
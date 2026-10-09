import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Maneja la autenticación contra la API y el almacenamiento seguro
/// de los datos de sesión.
///
/// Se almacenan de forma segura (flutter_secure_storage):
/// - Access Token (JWT)
/// - Refresh Token
/// - Correo
/// - IdUsuario
/// - Rol
///
/// No se guardan credenciales en SQLite.
class AuthService {
  AuthService._();

  static const _storage = FlutterSecureStorage();
  static const _timeout = Duration(seconds: 35);

  static const _tokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _emailKey = 'user_email';
  static const _userIdKey = 'user_id';
  static const _roleKey = 'user_role';

  static const _sessionKeys = [
    _tokenKey,
    _refreshTokenKey,
    _emailKey,
    _userIdKey,
    _roleKey,
  ];

  // ==========================================================
  // LOGIN / REGISTRO
  // ==========================================================

  /// POST /api/auth/login.
  ///
  /// Si es exitoso guarda Access Token, Refresh Token, correo,
  /// IdUsuario y rol.
  static Future<bool> login(String email, String password) {
    return _authenticate(
      path: '/api/auth/login',
      email: email,
      body: {'email': email, 'password': password},
      successCodes: const {200},
      fallback: (code) => code == 401
          ? 'El correo o la contraseña no son correctos.'
          : 'No fue posible iniciar sesión ($code).',
    );
  }

  /// POST /api/auth/register.
  ///
  /// Registra una cuenta de cliente y guarda la sesión que devuelve el API.
  /// El endpoint no recibe un rol: los registros desde la app son clientes.
  static Future<bool> register({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
  }) {
    return _authenticate(
      path: '/api/auth/register',
      email: email,
      body: {
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'password': password,
      },
      successCodes: const {200, 201},
      fallback: (code) => code == 409
          ? 'Ya existe una cuenta con ese correo electrónico.'
          : 'No fue posible crear la cuenta ($code).',
    );
  }

  /// Flujo común de login y registro: petición, validación y guardado.
  static Future<bool> _authenticate({
    required String path,
    required String email,
    required Map<String, dynamic> body,
    required Set<int> successCodes,
    required String Function(int statusCode) fallback,
  }) async {
    final response = await _post(path, body);

    if (!successCodes.contains(response.statusCode)) {
      throw AuthServiceException(
        _responseMessage(response, fallback: fallback(response.statusCode)),
      );
    }

    await _saveSession(_decodeSession(response), email);
    return true;
  }

  // ==========================================================
  // SESIÓN
  // ==========================================================

  /// Indica si existe una sesión anterior guardada.
  static Future<bool> hasActiveSession() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Guarda los datos de sesión devueltos por el backend.
  static Future<void> _saveSession(
    Map<String, dynamic> data,
    String email,
  ) async {
    final token = data['token'] as String?;
    final refreshToken = data['refreshToken'] as String?;
    final idUsuario = int.tryParse('${data['idUsuario']}');
    final role = (data['rol'] ?? data['tipoUsuario'])?.toString();

    if (token == null ||
        token.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty ||
        idUsuario == null) {
      throw const AuthServiceException(
        'El servidor no devolvió todos los datos de sesión necesarios.',
      );
    }

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _userIdKey, value: idUsuario.toString());
    if (role != null && role.isNotEmpty) {
      await _storage.write(key: _roleKey, value: role);
    }
  }

  /// Cierra la sesión y elimina tokens y datos almacenados localmente.
  static Future<void> logout() async {
    await Future.wait(_sessionKeys.map((key) => _storage.delete(key: key)));
  }

  // ==========================================================
  // ACCESS TOKEN
  // ==========================================================

  /// Obtiene el Access Token JWT.
  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Guarda un nuevo Access Token.
  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  // ==========================================================
  // REFRESH TOKEN
  // ==========================================================

  /// Obtiene el Refresh Token.
  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  /// Guarda un nuevo Refresh Token.
  static Future<void> saveRefreshToken(String refreshToken) =>
      _storage.write(key: _refreshTokenKey, value: refreshToken);

  /// Solicita nuevos tokens al backend (POST /api/auth/refresh).
  ///
  /// El backend rota los refresh tokens: devuelve un nuevo Access Token
  /// y un nuevo Refresh Token, y ambos reemplazan a los anteriores.
  ///
  /// Si el servidor RECHAZA el refresh token (400/401/403) la sesión se
  /// limpia; si solo falló la red, se conserva para reintentar después.
  static Future<bool> refreshToken() async {
    final current = await getRefreshToken();
    if (current == null || current.isEmpty) return false;

    try {
      final response = await _post(
        '/api/auth/refresh',
        {'refreshToken': current},
      );

      if (const {400, 401, 403}.contains(response.statusCode)) {
        await logout();
        return false;
      }
      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newToken = data['token'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;

      if (newToken == null ||
          newToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        return false;
      }

      await saveToken(newToken);
      await saveRefreshToken(newRefreshToken);
      return true;
    } catch (e) {
      debugPrint('AuthService: no se pudo renovar el token: $e');
      return false;
    }
  }

  // ==========================================================
  // DATOS DEL USUARIO
  // ==========================================================

  /// Obtiene el correo del usuario.
  static Future<String?> getUserEmail() => _storage.read(key: _emailKey);

  /// Obtiene el IdUsuario.
  static Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return value == null ? null : int.tryParse(value);
  }

  /// Obtiene el rol incluido en la sesión autenticada.
  static Future<String?> getUserRole() => _storage.read(key: _roleKey);

  // ==========================================================
  // RED Y RESPUESTAS
  // ==========================================================

  /// POST JSON contra la API.
  ///
  /// Convierte los errores de red (timeout, API apagada, IP incorrecta)
  /// en un [AuthServiceException] con un mensaje claro y deja el detalle
  /// técnico en la consola.
  static Future<http.Response> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    debugPrint('AuthService: POST $url');

    try {
      return await http
          .post(
            url,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      debugPrint('AuthService: timeout hacia $url');
      throw const AuthServiceException(
        'El servidor tardó demasiado en responder. Verifica que la API '
        'esté encendida y que el celular esté en la misma red Wi-Fi que la PC.',
      );
    } on SocketException catch (e) {
      debugPrint('AuthService: SocketException hacia $url: $e');
      throw AuthServiceException(
        'No se pudo conectar con el servidor (${ApiConfig.baseUrl}). '
        'Revisa que la API esté corriendo y que la IP sea la actual de tu PC.',
      );
    } on http.ClientException catch (e) {
      debugPrint('AuthService: ClientException hacia $url: $e');
      throw const AuthServiceException(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }
  }

  /// Decodifica la respuesta de sesión validando que sea un objeto JSON.
  static Map<String, dynamic> _decodeSession(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Invalid session response');
      }
      return data;
    } on FormatException {
      throw const AuthServiceException(
        'El servidor devolvió una respuesta de sesión no válida.',
      );
    }
  }

  /// Extrae el mensaje de error del cuerpo de la respuesta (mensaje,
  /// message, error, title o errors de validación). Si no hay uno
  /// utilizable, devuelve [fallback].
  static String _responseMessage(
    http.Response response, {
    required String fallback,
  }) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        for (final key in const ['mensaje', 'message', 'error', 'title']) {
          final value = body[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim();
          }
        }

        final errors = body['errors'];
        if (errors is Map) {
          final messages = errors.values
              .expand((value) => value is List ? value : [value])
              .whereType<String>()
              .where((message) => message.trim().isNotEmpty)
              .toList();
          if (messages.isNotEmpty) return messages.join(' ');
        }
      }
    } on FormatException {
      // Respuesta no JSON: se usa el mensaje por defecto.
    }
    return fallback;
  }
}

/// Error de autenticación con un mensaje listo para mostrar al usuario.
class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => message;
}
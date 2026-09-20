import 'package:dio/dio.dart';

import '../../services/auth_service.dart';

/// Interceptor encargado de agregar automáticamente
/// el token JWT almacenado de forma segura.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await AuthService.getToken();

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] =
            'Bearer $token';
      }
    } catch (_) {
      // La petición continúa.
      // El servidor podrá responder 401.
    }

    handler.next(options);
  }
}
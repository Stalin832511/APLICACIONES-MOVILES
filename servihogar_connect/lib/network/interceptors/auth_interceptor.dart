import 'package:dio/dio.dart';

import '../../services/auth_service.dart';

/// Agrega el token JWT almacenado de forma segura a las peticiones.
class AuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (error) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          message: 'No se pudo leer la sesión segura.',
        ),
      );
      return;
    }

    handler.next(options);
  }
}

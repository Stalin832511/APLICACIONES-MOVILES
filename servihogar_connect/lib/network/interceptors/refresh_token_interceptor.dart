import 'package:dio/dio.dart';

import '../../services/auth_service.dart';
import '../api_client.dart';

/// Interceptor encargado de renovar automáticamente
/// el Access Token cuando la API responde HTTP 401.
///
/// Flujo:
///
/// Petición
///    ↓
/// API
///    ↓
/// 401 Unauthorized
///    ↓
/// Refresh Token
///    ↓
/// Nuevo Access Token
///    ↓
/// Reintentar petición original
class RefreshTokenInterceptor extends Interceptor {
  bool _refreshing = false;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode =
        err.response?.statusCode;

    if (statusCode != 401) {
      handler.next(err);
      return;
    }

    if (err.requestOptions.path.contains(
      '/api/auth/refresh',
    )) {
      handler.next(err);
      return;
    }

    if (_refreshing) {
      handler.next(err);
      return;
    }

    _refreshing = true;

    try {
      print('========================================');
      print('REFRESH TOKEN INTERCEPTOR');
      print('401 DETECTADO');
      print('INTENTANDO RENOVAR ACCESS TOKEN');
      print('========================================');

      final refreshed =
          await AuthService.refreshToken();

      if (!refreshed) {
        print(
          'REFRESH TOKEN INVALIDO O EXPIRADO',
        );

        await AuthService.logout();

        handler.next(err);
        return;
      }

      final newToken =
          await AuthService.getToken();

      if (newToken == null ||
          newToken.isEmpty) {
        await AuthService.logout();

        handler.next(err);
        return;
      }

      print(
        'NUEVO ACCESS TOKEN OBTENIDO',
      );

      final requestOptions =
          err.requestOptions;

      requestOptions.headers['Authorization'] =
          'Bearer $newToken';

      print(
        'REINTENTANDO PETICION ORIGINAL',
      );

      final response =
          await ApiClient.retryDio.fetch(
        requestOptions,
      );

      print(
        'REINTENTO EXITOSO: '
        '${response.statusCode}',
      );

      handler.resolve(response);
    } catch (e) {
      print(
        'ERROR DURANTE REFRESH TOKEN: $e',
      );

      await AuthService.logout();

      handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
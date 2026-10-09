import 'package:dio/dio.dart';

import '../../services/auth_service.dart';
import '../api_client.dart';

/// Renueva el token una sola vez y reintenta peticiones rechazadas con 401.
class RefreshTokenInterceptor extends Interceptor {
  Future<bool>? _refreshFuture;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains('/api/auth/refresh')) {
      handler.next(err);
      return;
    }

    Future<bool>? refreshFuture;
    try {
      final requestOptions = err.requestOptions;
      final currentToken = await AuthService.getToken();
      var tokenToUse = currentToken;

      // If this request used the current token, that token was rejected and
      // must be refreshed. A different request may already have refreshed it.
      if (currentToken == null ||
          currentToken.isEmpty ||
          requestOptions.headers['Authorization'] == 'Bearer $currentToken') {
        refreshFuture = _refreshFuture ??= AuthService.refreshToken();
        if (!await refreshFuture) {
          await _logout();
          handler.next(err);
          return;
        }
        tokenToUse = await AuthService.getToken();
      }

      if (tokenToUse == null || tokenToUse.isEmpty) {
        await _logout();
        handler.next(err);
        return;
      }

      requestOptions.headers['Authorization'] = 'Bearer $tokenToUse';
      final response = await ApiClient.retryDio.fetch(requestOptions);
      handler.resolve(response);
    } catch (_) {
      await _logout();
      handler.next(err);
    } finally {
      if (refreshFuture != null && identical(_refreshFuture, refreshFuture)) {
        _refreshFuture = null;
      }
    }
  }

  Future<void> _logout() async {
    try {
      await AuthService.logout();
    } catch (_) {
      // Preserve the original request failure if secure deletion also fails.
    }
  }
}

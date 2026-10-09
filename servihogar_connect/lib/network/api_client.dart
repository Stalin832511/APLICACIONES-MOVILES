import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/refresh_token_interceptor.dart';

/// Cliente HTTP centralizado de ServiHogar Connect.
///
/// La aplicación utiliza una única instancia de Dio para centralizar:
/// - URL base.
/// - Tiempos de espera.
/// - Interceptores.
/// - Configuración común de las peticiones.
class ApiClient {
  ApiClient._();

  static final Dio instance = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(),
      receiveTimeout: const Duration(),
      sendTimeout: const Duration(),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )
    ..interceptors.add(
      AuthInterceptor(),
    )
    ..interceptors.add(
      ErrorInterceptor(),
    )
    ..interceptors.add(
      RefreshTokenInterceptor(),
    );

  /// Dio independiente utilizado para repetir
  /// una petición después de renovar el Access Token.
  ///
  /// No contiene interceptores para evitar
  /// ciclos infinitos durante el retry.
  static final Dio retryDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(),
      receiveTimeout: const Duration(),
      sendTimeout: const Duration(),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
}
import 'package:dio/dio.dart';

import '../domain/network_failure.dart';

/// Traduce errores HTTP y de transporte a errores
/// pertenecientes al dominio de la aplicación.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    final failure = _mapError(err);

    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: failure,
        message: failure.message,
      ),
    );
  }

  NetworkFailure _mapError(
    DioException error,
  ) {
    final statusCode =
        error.response?.statusCode;

    if (error.type ==
            DioExceptionType.connectionError ||
        error.type ==
            DioExceptionType.connectionTimeout ||
        error.type ==
            DioExceptionType.receiveTimeout ||
        error.type ==
            DioExceptionType.sendTimeout) {
      return const NetworkFailure(
        type: NetworkFailureType.connection,
        message:
            'No se pudo conectar con el servidor. '
            'Verifique su conexión a Internet.',
      );
    }

    if (statusCode == 401) {
      return const NetworkFailure(
        type: NetworkFailureType.authentication,
        statusCode: 401,
        message:
            'La sesión ha expirado. '
            'Por favor, vuelva a iniciar sesión.',
      );
    }

    if (statusCode == 422) {
      return NetworkFailure(
        type: NetworkFailureType.validation,
        statusCode: 422,
        message:
            'Los datos enviados no son válidos. '
            'Revise los campos indicados.',
        details:
            _extractValidationDetails(
          error.response,
        ),
      );
    }

    if (statusCode != null &&
        statusCode >= 500) {
      return NetworkFailure(
        type: NetworkFailureType.server,
        statusCode: statusCode,
        message:
            'El servidor no está disponible en '
            'este momento. Inténtelo nuevamente '
            'más tarde.',
      );
    }

    return NetworkFailure(
      type: NetworkFailureType.server,
      statusCode: statusCode,
      message:
          'No fue posible completar la operación. '
          'Código: '
          '${statusCode ?? 'desconocido'}.',
    );
  }

  Map<String, dynamic>?
      _extractValidationDetails(
    Response<dynamic>? response,
  ) {
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      return data;
    }

    return null;
  }
}
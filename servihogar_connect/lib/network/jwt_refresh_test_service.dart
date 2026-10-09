import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Servicio utilizado exclusivamente para verificar
/// el flujo de renovación automática del JWT.
///
/// No modifica datos del sistema.
/// Utiliza únicamente el endpoint protegido de health.
class JwtRefreshTestService {
  JwtRefreshTestService._();

  static Future<void> ejecutarPrueba() async {
    if (kDebugMode) {
      debugPrint('INICIO PRUEBA JWT REFRESH');
    }

    try {
      if (kDebugMode) {
        debugPrint('Enviando petición a /api/v1/health');
      }

      final response = await ApiClient.instance.get(
        '/api/v1/health',
      );

      if (kDebugMode) {
        debugPrint('Prueba JWT finalizada. HTTP ${response.statusCode}.');
      }
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Prueba JWT fallida. HTTP ${error.response?.statusCode ?? 'sin respuesta'}.',
        );
      }

      rethrow;
    }
  }
}
import 'package:dio/dio.dart';

import 'api_client.dart';

/// Servicio utilizado exclusivamente para verificar
/// el flujo de renovación automática del JWT.
///
/// No modifica datos del sistema.
/// Utiliza únicamente el endpoint protegido de health.
class JwtRefreshTestService {
  JwtRefreshTestService._();

  static Future<void> ejecutarPrueba() async {
    print('========================================');
    print('INICIO PRUEBA JWT REFRESH');
    print('========================================');

    try {
      print('ENVIANDO PETICION A /api/v1/health');

      final response = await ApiClient.instance.get(
        '/api/v1/health',
      );

      print('RESPUESTA API CLIENT');
      print('STATUS: ${response.statusCode}');
      print('DATA: ${response.data}');

      print('========================================');
      print('PRUEBA JWT FINALIZADA');
      print('========================================');
    } on DioException catch (e) {
      print('========================================');
      print('ERROR PRUEBA JWT');
      print('STATUS: ${e.response?.statusCode}');
      print('ERROR: ${e.error}');
      print('========================================');

      rethrow;
    }
  }
}
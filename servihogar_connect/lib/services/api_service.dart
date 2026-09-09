import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/solicitud.dart';

class ApiService {
  static Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/health',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)
          as Map<String, dynamic>;
    } else {
      throw Exception(
        'Error del servidor: ${response.statusCode}',
      );
    }
  }

  static Future<List<SolicitudModel>> fetchSolicitudes() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/Solicitudes',
    );

    final response = await http
        .get(url)
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final List<dynamic> jsonList =
          jsonDecode(response.body) as List<dynamic>;

      return jsonList
          .map(
            (item) => SolicitudModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } else {
      throw Exception(
        'Error del servidor: ${response.statusCode}',
      );
    }
  }

  /// Crea una solicitud en el servidor.
  ///
  /// clientOperationId identifica de forma única
  /// la operación realizada desde el dispositivo.
  static Future<SolicitudModel> crearSolicitud({
    required int idUsuario,
    required int idCategoria,
    required String clientOperationId,
    required String descripcion,
    required double latitud,
    required double longitud,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/Solicitudes',
    );

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'idUsuario': idUsuario,
            'idCategoria': idCategoria,
            'clientOperationId': clientOperationId,
            'descripcion': descripcion,
            'estado': 'publicada',
            'latitud': latitud,
            'longitud': longitud,
          }),
        )
        .timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 201) {
      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      return SolicitudModel.fromJson(data);
    }

    if (response.statusCode == 400) {
      final data =
          jsonDecode(response.body)
              as Map<String, dynamic>;

      throw Exception(
        data['mensaje'] ??
            'Los datos de la solicitud no son válidos.',
      );
    }

    throw Exception(
      'Error creando la solicitud: '
      '${response.statusCode}',
    );
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/solicitud.dart';

class ApiService {
  static Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/health');

    final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }

  static Future<List<SolicitudModel>> fetchSolicitudes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/Solicitudes');

    final response = await http.get(url).timeout(
          const Duration(seconds: 10),
        );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => SolicitudModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error del servidor: ${response.statusCode}');
    }
  }
}
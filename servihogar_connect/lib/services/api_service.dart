import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/categoria.dart';
import '../models/solicitud.dart';
import '../network/api_client.dart';

class ApiService {
  /// Public liveness endpoint; intentionally does not use authenticated Dio.
  static Future<Map<String, dynamic>> checkHealth() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/health');
    final response =
        await http.get(url).timeout(const Duration());

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Error del servidor: ${response.statusCode}');
  }

  static Future<List<SolicitudModel>> fetchSolicitudes() async {
    try {
      final response =
          await ApiClient.instance.get<List<dynamic>>('/api/Solicitudes');
      return (response.data ?? const <dynamic>[])
          .map(
            (item) => SolicitudModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiServiceException(_dioMessage(error));
    }
  }

  static Future<SolicitudesPage> fetchSolicitudesPaginadas({
    int page = 1,
    int pageSize = 20,
    String? estado,
    int? idCategoria,
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (estado != null) {
      queryParameters['estado'] = estado;
    }
    if (idCategoria != null) {
      queryParameters['idCategoria'] = '$idCategoria';
    }

    try {
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/Solicitudes/paginadas',
        queryParameters: queryParameters,
      );
      return SolicitudesPage.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiServiceException(_dioMessage(error));
    }
  }

  /// Public catalog endpoint; intentionally does not use authenticated Dio.
  static Future<List<CategoriaModel>> fetchCategorias() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/categorias');
    final response =
        await http.get(url).timeout(const Duration());

    if (response.statusCode != 200) {
      final responseBody = response.body.trim();
      final messageLength =
          responseBody.length > 300 ? 300 : responseBody.length;
      final serverMessage = responseBody.isEmpty
          ? ''
          : ' ${responseBody.substring(0, messageLength)}';
      throw Exception(
        'Error al cargar categorías: HTTP ${response.statusCode}.$serverMessage',
      );
    }

    final jsonList = jsonDecode(response.body) as List<dynamic>;
    return jsonList
        .map(
          (item) => CategoriaModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// Creates a request through the authenticated client so token refresh
  /// and retry are applied consistently.
  static Future<SolicitudModel> crearSolicitud({
    required int idUsuario,
    required int idCategoria,
    required String clientOperationId,
    required String descripcion,
    required double latitud,
    required double longitud,
  }) async {
    try {
      final response = await ApiClient.instance.post<Map<String, dynamic>>(
        '/api/Solicitudes',
        data: {
          'idUsuario': idUsuario,
          'idCategoria': idCategoria,
          'clientOperationId': clientOperationId,
          'descripcion': descripcion,
          'estado': 'publicada',
          'latitud': latitud,
          'longitud': longitud,
        },
      );
      return SolicitudModel.fromJson(response.data!);
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;
      throw ApiServiceException(
        _dioMessage(
          error,
          fallback: statusCode == 400
              ? 'Los datos de la solicitud no son válidos.'
              : 'Error creando la solicitud'
                  '${statusCode == null ? '' : ': $statusCode'}.',
        ),
        isNetworkFailure: _isNetworkFailure(error),
        statusCode: statusCode,
      );
    }
  }

  static String _dioMessage(
    DioException error, {
    String? fallback,
  }) {
    final data = error.response?.data;
    if (data is Map) {
      for (final key in ['mensaje', 'message', 'error', 'title']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
      final errors = data['errors'];
      if (errors is Map) {
        final messages = errors.values
            .expand((value) => value is List ? value : [value])
            .whereType<String>()
            .where((message) => message.trim().isNotEmpty)
            .toList();
        if (messages.isNotEmpty) return messages.join(' ');
      }
    }

    final interceptorMessage = error.message?.trim();
    if (interceptorMessage != null && interceptorMessage.isNotEmpty) {
      return interceptorMessage;
    }
    final interceptorError = error.error?.toString();
    if (interceptorError != null && interceptorError.trim().isNotEmpty) {
      return interceptorError;
    }
    return fallback ??
        error.message ??
        'No fue posible completar la operación.';
  }

  static bool _isNetworkFailure(DioException error) =>
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout);
}

class ApiServiceException implements Exception {
  final String message;
  final bool isNetworkFailure;
  final int? statusCode;

  const ApiServiceException(
    this.message, {
    this.isNetworkFailure = false,
    this.statusCode,
  });

  @override
  String toString() => message;
}

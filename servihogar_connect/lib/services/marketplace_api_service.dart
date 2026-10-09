import 'package:dio/dio.dart';

import '../models/marketplace_models.dart';
import '../network/api_client.dart';

class MarketplaceApiService {
  MarketplaceApiService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<ProfessionalRequestsPage> getProfessionalRequests({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/marketplace/professional/requests',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ProfessionalRequestsPage.fromJson(response.data ?? const {});
  }

  Future<List<ProfessionalRequest>> getProfessionalAssigned() async {
    final response = await _dio.get<dynamic>(
      '/api/marketplace/professional/assigned',
    );
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
            ? data['items'] as List? ?? const []
            : const [];
    return items
        .whereType<Map>()
        .map((item) => ProfessionalRequest.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> submitQuote({
    required int requestId,
    required double price,
    required String estimatedTime,
  }) async {
    await _dio.post<void>(
      '/api/marketplace/requests/$requestId/quotes',
      data: {'precioOfertado': price, 'tiempoEstimado': estimatedTime},
    );
  }

  Future<MarketplaceQuotesResponse> getQuotes(int requestId) async {
    final response = await _dio.get<dynamic>(
      '/api/marketplace/requests/$requestId/quotes',
    );
    final data = response.data;
    if (data is List) {
      return MarketplaceQuotesResponse.fromJson({'items': data});
    }
    if (data is Map) {
      return MarketplaceQuotesResponse.fromJson(
        Map<String, dynamic>.from(data),
      );
    }
    return const MarketplaceQuotesResponse(items: [], estado: '');
  }

  Future<void> acceptQuote({
    required int requestId,
    required int quoteId,
  }) async {
    await _dio.post<void>(
      '/api/marketplace/requests/$requestId/quotes/$quoteId/accept',
    );
  }

  Future<void> updateRequestStatus({
    required int requestId,
    required String status,
  }) async {
    await _dio.patch<void>(
      '/api/marketplace/requests/$requestId/status',
      data: {'estado': status},
    );
  }

  Future<MarketplaceSummary> getAdminSummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/marketplace/admin/summary',
    );
    return MarketplaceSummary.fromJson(response.data ?? const {});
  }

  Future<List<MarketplaceProfessional>> getAdminProfessionals() async {
    final response = await _dio.get<dynamic>(
      '/api/marketplace/admin/professionals',
    );
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
            ? data['items'] as List? ?? const []
            : const [];
    return items
        .whereType<Map>()
        .map((item) => MarketplaceProfessional.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<MarketplaceAdminUser>> getAdminUsers() async {
    final response =
        await _dio.get<List<dynamic>>('/api/marketplace/admin/users');
    return (response.data ?? const [])
        .whereType<Map>()
        .map(
          (item) => MarketplaceAdminUser.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<void> createProfessional({
    required int userId,
    required String specialty,
    required String description,
    required double hourlyRate,
  }) async {
    await _dio.post<void>(
      '/api/marketplace/admin/professionals',
      data: {
        'idUsuario': userId,
        'especialidad': specialty,
        'descripcion': description,
        'tarifaHora': hourlyRate,
      },
    );
  }

  Future<void> submitRating({
    required int requestId,
    required int professionalId,
    required int score,
    required String comment,
  }) async {
    await _dio.post<void>(
      '/api/marketplace/requests/$requestId/ratings',
      data: {
        'idProfesional': professionalId,
        'puntuacion': score,
        'comentario': comment,
      },
    );
  }

  Future<List<MarketplaceCategory>> getCategories() async {
    final response = await _dio.get<dynamic>('/api/categorias/admin');
    final data = response.data;
    final items = data is List
        ? data
        : data is Map
            ? data['items'] as List? ?? const []
            : const [];
    return items
        .whereType<Map>()
        .map((item) => MarketplaceCategory.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> createCategory({
    required String name,
    required String description,
  }) async {
    await _dio.post<void>(
      '/api/categorias',
      data: {'nombre': name, 'descripcion': description, 'activa': true},
    );
  }

  Future<void> updateCategory(MarketplaceCategory category) async {
    final body = {
      'idCategoria': category.idCategoria,
      'nombre': category.nombre,
      'descripcion': category.descripcion,
      'activa': category.activa,
    };
    try {
      await _dio.put<void>('/api/categorias', data: body);
    } on DioException catch (error) {
      if (error.response?.statusCode != 404 &&
          error.response?.statusCode != 405) {
        rethrow;
      }
      await _dio.put<void>(
        '/api/categorias/${category.idCategoria}',
        data: body,
      );
    }
  }
}

String marketplaceErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      for (final key in ['mensaje', 'message', 'error', 'title']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
      }
    }
    return error.response == null
        ? 'No se pudo conectar con el servidor. Comprueba tu conexión.'
        : 'La operación no se pudo completar '
            '(código ${error.response?.statusCode ?? 'desconocido'}).';
  }
  return 'Ocurrió un error inesperado. Inténtalo de nuevo.';
}

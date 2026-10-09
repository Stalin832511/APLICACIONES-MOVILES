import '../widgets/status_badge.dart';

/// Modelo tipado de una solicitud de servicio, mapeado desde el
/// JSON que devuelve GET /api/Solicitudes.
class SolicitudModel {
  final int id;
  final String descripcion;
  final RequestStatus status;
  final DateTime fechaCreacion;
  final String? categoriaNombre;
  final String? usuarioNombre;
  final String? estadoOriginal;
  final double? latitud;
  final double? longitud;
  final String? clientOperationId;
  final int? idCategoria;
  final bool pendingSync;
  final bool syncFailed;
  final String? localPhotoPath;

  SolicitudModel({
    required this.id,
    required this.descripcion,
    required this.status,
    required this.fechaCreacion,
    this.categoriaNombre,
    this.usuarioNombre,
    this.estadoOriginal,
    this.latitud,
    this.longitud,
    this.clientOperationId,
    this.idCategoria,
    this.pendingSync = false,
    this.syncFailed = false,
    this.localPhotoPath,
  });

  factory SolicitudModel.fromPendingPayload({
    required int localId,
    required Map<String, dynamic> payload,
    required DateTime createdAt,
    required String? categoryName,
    required bool syncFailed,
  }) {
    final latitude = payload['latitud'];
    final longitude = payload['longitud'];
    final categoryId = payload['idCategoria'];
    return SolicitudModel(
      id: localId,
      descripcion: payload['descripcion']?.toString() ?? 'Sin descripción',
      status: RequestStatus.pendiente,
      fechaCreacion: createdAt,
      categoriaNombre: categoryName,
      latitud: latitude is num
          ? latitude.toDouble()
          : double.tryParse(latitude?.toString() ?? ''),
      longitud: longitude is num
          ? longitude.toDouble()
          : double.tryParse(longitude?.toString() ?? ''),
      clientOperationId: payload['clientOperationId']?.toString(),
      idCategoria: categoryId is num
          ? categoryId.toInt()
          : int.tryParse(categoryId?.toString() ?? ''),
      pendingSync: true,
      syncFailed: syncFailed,
      localPhotoPath: payload['fotoPath']?.toString(),
    );
  }

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['usuario'] ?? json['Usuario'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : const <String, dynamic>{};
    final nombreUsuario =
        (user['nombre'] ?? user['Nombre'] ?? '').toString().trim();
    final apellidoUsuario =
        (user['apellido'] ?? user['Apellido'] ?? '').toString().trim();
    return SolicitudModel(
      id: json['idSolicitud'] ?? json['IdSolicitud'] ?? 0,
      descripcion:
          json['descripcion'] ?? json['Descripcion'] ?? 'Sin descripción',
      status: RequestStatusParsing.fromApiValue(
        (json['estado'] ?? json['Estado'] ?? '').toString(),
      ),
      fechaCreacion: DateTime.tryParse(
            (json['fechaCreacion'] ?? json['FechaCreacion'] ?? '')
                .toString(),
          ) ??
          DateTime.now(),
      categoriaNombre: (json['categoria']?['nombre'] ??
              json['Categoria']?['Nombre'])
          ?.toString(),
      usuarioNombre: [nombreUsuario, apellidoUsuario]
          .where((part) => part.isNotEmpty)
          .join(' '),
      estadoOriginal:
          (json['estado'] ?? json['Estado'])?.toString(),
      latitud: (json['latitud'] ?? json['Latitud']) != null
          ? double.tryParse((json['latitud'] ?? json['Latitud']).toString())
          : null,
      longitud: (json['longitud'] ?? json['Longitud']) != null
          ? double.tryParse((json['longitud'] ?? json['Longitud']).toString())
          : null,
      clientOperationId:
          json['clientOperationId'] ?? json['ClientOperationId'],
      idCategoria: int.tryParse(
        (json['idCategoria'] ??
                json['IdCategoria'] ??
                json['categoria']?['idCategoria'] ??
                json['categoria']?['IdCategoria'] ??
                json['Categoria']?['idCategoria'] ??
                json['Categoria']?['IdCategoria'])
            .toString(),
      ),
    );
  }
}

class SolicitudesPage {
  final List<SolicitudModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const SolicitudesPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory SolicitudesPage.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => SolicitudModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
    final page = int.tryParse(json['page'].toString()) ?? 1;
    final pageSize = int.tryParse(json['pageSize'].toString()) ??
        (items.isEmpty ? 20 : items.length);
    final totalCount =
        int.tryParse(json['totalCount'].toString()) ?? items.length;

    return SolicitudesPage(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: int.tryParse(json['totalPages'].toString()) ??
          (pageSize == 0 ? 0 : (totalCount / pageSize).ceil()),
    );
  }
}
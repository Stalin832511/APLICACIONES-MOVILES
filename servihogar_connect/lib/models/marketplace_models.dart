class ProfessionalRequest {
  final int idSolicitud;
  final int? idCategoria;
  final String categoriaNombre;
  final String descripcion;
  final DateTime fechaCreacion;
  final double? latitud;
  final double? longitud;
  final String? estado;
  final double? precioOfertado;
  final String? tiempoEstimado;
  final int? idCotizacion;

  const ProfessionalRequest({
    required this.idSolicitud,
    this.idCategoria,
    required this.categoriaNombre,
    required this.descripcion,
    required this.fechaCreacion,
    this.latitud,
    this.longitud,
    this.estado,
    this.precioOfertado,
    this.tiempoEstimado,
    this.idCotizacion,
  });

  factory ProfessionalRequest.fromJson(Map<String, dynamic> json) {
    final categoria = json['categoria'];
    final categoryMap = categoria is Map
        ? Map<String, dynamic>.from(categoria)
        : const <String, dynamic>{};
    return ProfessionalRequest(
      idSolicitud: _asInt(json['idSolicitud']) ?? 0,
      idCategoria: _asInt(json['idCategoria']),
      categoriaNombre:
          (categoryMap['nombre'] ?? json['categoriaNombre'] ?? 'Sin categoría')
              .toString(),
      descripcion: (json['descripcion'] ?? 'Sin descripción').toString(),
      fechaCreacion: DateTime.tryParse(
            (json['fechaCreacion'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      latitud: _asDouble(json['latitud']),
      longitud: _asDouble(json['longitud']),
      estado: (json['estado'] ?? json['Estado'])?.toString(),
      precioOfertado: _asDouble(json['precioOfertado'] ?? json['PrecioOfertado']),
      tiempoEstimado:
          (json['tiempoEstimado'] ?? json['TiempoEstimado'])?.toString(),
      idCotizacion: _asInt(json['idCotizacion'] ?? json['IdCotizacion']),
    );
  }
}

class ProfessionalRequestsPage {
  final List<ProfessionalRequest> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  const ProfessionalRequestsPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  factory ProfessionalRequestsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => ProfessionalRequest.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <ProfessionalRequest>[];
    final pageSize = _asInt(json['pageSize']) ?? (items.isEmpty ? 20 : items.length);
    final totalCount = _asInt(json['totalCount']) ?? items.length;
    return ProfessionalRequestsPage(
      items: items,
      page: _asInt(json['page']) ?? 1,
      pageSize: pageSize,
      totalCount: totalCount,
      totalPages: _asInt(json['totalPages']) ??
          (pageSize <= 0 ? 0 : (totalCount / pageSize).ceil()),
    );
  }
}

class MarketplaceQuote {
  final int idCotizacion;
  final int idSolicitud;
  final int idProfesional;
  final double precioOfertado;
  final String tiempoEstimado;
  final String estado;
  final String profesionalNombre;
  final String profesionalEspecialidad;
  final double? calificacionPromedio;
  final bool yaCalificado;

  const MarketplaceQuote({
    required this.idCotizacion,
    required this.idSolicitud,
    required this.idProfesional,
    required this.precioOfertado,
    required this.tiempoEstimado,
    required this.estado,
    required this.profesionalNombre,
    required this.profesionalEspecialidad,
    this.calificacionPromedio,
    this.yaCalificado = false,
  });

  factory MarketplaceQuote.fromJson(Map<String, dynamic> json) {
    final rawProfessional = json['profesional'];
    final professional = rawProfessional is Map
        ? Map<String, dynamic>.from(rawProfessional)
        : const <String, dynamic>{};
    return MarketplaceQuote(
      idCotizacion: _asInt(json['idCotizacion']) ?? 0,
      idSolicitud: _asInt(json['idSolicitud']) ?? 0,
      idProfesional: _asInt(json['idProfesional']) ?? 0,
      precioOfertado: _asDouble(json['precioOfertado']) ?? 0,
      tiempoEstimado: (json['tiempoEstimado'] ?? '').toString(),
      estado: (json['estado'] ?? '').toString(),
      profesionalNombre:
          (professional['nombre'] ??
                  json['nombreProfesional'] ??
                  json['NombreProfesional'] ??
                  'Profesional')
              .toString(),
      profesionalEspecialidad:
          (professional['especialidad'] ??
                  json['especialidad'] ??
                  json['Especialidad'] ??
                  'Servicios generales')
              .toString(),
      calificacionPromedio: _asDouble(
        professional['calificacionPromedio'] ??
            json['calificacionPromedio'] ??
            json['CalificacionPromedio'],
      ),
      yaCalificado:
          json['yaCalificado'] == true || json['YaCalificado'] == true,
    );
  }
}

class MarketplaceQuotesResponse {
  final List<MarketplaceQuote> items;
  final String estado;

  const MarketplaceQuotesResponse({
    required this.items,
    required this.estado,
  });

  factory MarketplaceQuotesResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => MarketplaceQuote.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <MarketplaceQuote>[];
    return MarketplaceQuotesResponse(
      items: items,
      estado: (json['estado'] ?? '').toString(),
    );
  }
}

class MarketplaceSummary {
  final int solicitudesPendientes;
  final int solicitudesEnProceso;
  final int solicitudesCompletadas;
  final int profesionalesActivos;
  final int categoriasActivas;

  const MarketplaceSummary({
    required this.solicitudesPendientes,
    required this.solicitudesEnProceso,
    required this.solicitudesCompletadas,
    required this.profesionalesActivos,
    required this.categoriasActivas,
  });

  factory MarketplaceSummary.fromJson(Map<String, dynamic> json) {
    int count(List<String> keys, {int fallback = 0}) {
      for (final key in keys) {
        final value = _asInt(json[key]);
        if (value != null) return value;
      }
      return fallback;
    }

    final stateCounts = <String, int>{};
    final rawStates = json['solicitudesPorEstado'];
    if (rawStates is List) {
      for (final rawState in rawStates.whereType<Map>()) {
        final state = (rawState['estado'] ?? rawState['Estado'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final quantity = _asInt(
              rawState['cantidad'] ?? rawState['Cantidad'],
            ) ??
            0;
        stateCounts[state] = (stateCounts[state] ?? 0) + quantity;
      }
    }

    int sumStates(Set<String> names) => stateCounts.entries
        .where((entry) => names.contains(entry.key))
        .fold(0, (total, entry) => total + entry.value);

    return MarketplaceSummary(
      solicitudesPendientes:
          count(
            ['solicitudesPendientes', 'totalSolicitudesPendientes'],
            fallback: sumStates(
              {'publicada', 'publicado', 'pendiente', 'asignada'},
            ),
          ),
      solicitudesEnProceso:
          count(
            ['solicitudesEnProceso', 'totalSolicitudesEnProceso'],
            fallback: sumStates({'en proceso', 'en_proceso'}),
          ),
      solicitudesCompletadas:
          count(
            ['solicitudesCompletadas', 'totalSolicitudesCompletadas'],
            fallback: sumStates({'completada', 'completado'}),
          ),
      profesionalesActivos:
          count(
            ['profesionalesActivos', 'totalProfesionalesActivos'],
            fallback: count(['totalProfesionales']),
          ),
      categoriasActivas:
          count(
            ['categoriasActivas', 'totalCategoriasActivas'],
            fallback: count(['totalCategorias']),
          ),
    );
  }
}

class MarketplaceCategory {
  final int idCategoria;
  final String nombre;
  final String descripcion;
  final bool activa;

  const MarketplaceCategory({
    required this.idCategoria,
    required this.nombre,
    required this.descripcion,
    required this.activa,
  });

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) {
    final activeValue = json['activa'] ?? json['activo'] ?? json['estado'];
    final active = activeValue is bool
        ? activeValue
        : activeValue is num
            ? activeValue != 0
            : activeValue == null
                ? true
                : !const {'inactiva', 'inactivo', 'false', '0', 'desactivada'}
                    .contains(activeValue.toString().trim().toLowerCase());
    return MarketplaceCategory(
      idCategoria: _asInt(json['idCategoria']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      activa: active,
    );
  }
}

class MarketplaceProfessional {
  final int idProfesional;
  final int idUsuario;
  final String especialidad;
  final String descripcion;
  final double tarifaHora;
  final double? calificacionPromedio;
  final String nombreUsuario;
  final String emailUsuario;

  const MarketplaceProfessional({
    required this.idProfesional,
    required this.idUsuario,
    required this.especialidad,
    required this.descripcion,
    required this.tarifaHora,
    required this.nombreUsuario,
    required this.emailUsuario,
    this.calificacionPromedio,
  });

  factory MarketplaceProfessional.fromJson(Map<String, dynamic> json) {
    final rawUser = json['usuario'] ?? json['Usuario'];
    final user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : const <String, dynamic>{};
    final firstName = (user['nombre'] ?? user['Nombre'] ?? '').toString();
    final lastName = (user['apellido'] ?? user['Apellido'] ?? '').toString();
    return MarketplaceProfessional(
      idProfesional: _asInt(json['idProfesional'] ?? json['IdProfesional']) ?? 0,
      idUsuario: _asInt(json['idUsuario'] ?? json['IdUsuario']) ?? 0,
      especialidad:
          (json['especialidad'] ?? json['Especialidad'] ?? '').toString(),
      descripcion:
          (json['descripcion'] ?? json['Descripcion'] ?? '').toString(),
      tarifaHora:
          _asDouble(json['tarifaHora'] ?? json['TarifaHora']) ?? 0,
      calificacionPromedio: _asDouble(
        json['calificacionPromedio'] ?? json['CalificacionPromedio'],
      ),
      nombreUsuario: [firstName, lastName]
          .where((part) => part.trim().isNotEmpty)
          .join(' '),
      emailUsuario: (user['email'] ?? user['Email'] ?? '').toString(),
    );
  }
}

class MarketplaceAdminUser {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String tipoUsuario;

  const MarketplaceAdminUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.tipoUsuario,
  });

  String get nombreCompleto =>
      [nombre, apellido].where((part) => part.trim().isNotEmpty).join(' ');

  factory MarketplaceAdminUser.fromJson(Map<String, dynamic> json) {
    return MarketplaceAdminUser(
      id: _asInt(json['id'] ?? json['idUsuario']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      apellido: (json['apellido'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      tipoUsuario: (json['tipoUsuario'] ?? '').toString(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  return value == null ? null : int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return value == null ? null : double.tryParse(value.toString());
}

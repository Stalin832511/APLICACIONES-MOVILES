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

  SolicitudModel({
    required this.id,
    required this.descripcion,
    required this.status,
    required this.fechaCreacion,
    this.categoriaNombre,
    this.usuarioNombre,
  });

  factory SolicitudModel.fromJson(Map<String, dynamic> json) {
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
      categoriaNombre: json['categoria']?['nombre'] ??
          json['Categoria']?['Nombre'],
      usuarioNombre: json['usuario']?['nombre'] ?? json['Usuario']?['Nombre'],
    );
  }
}
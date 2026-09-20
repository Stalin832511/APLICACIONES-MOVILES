/// Familias de fallos que pueden producirse
/// durante el consumo de la API.
enum NetworkFailureType {
  connection,
  authentication,
  validation,
  server,
}

/// Error de dominio utilizado por la aplicación
/// para no depender directamente de errores de Dio.
class NetworkFailure implements Exception {
  final NetworkFailureType type;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  const NetworkFailure({
    required this.type,
    required this.message,
    this.statusCode,
    this.details,
  });

  @override
  String toString() {
    return 'NetworkFailure('
        'type: $type, '
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}
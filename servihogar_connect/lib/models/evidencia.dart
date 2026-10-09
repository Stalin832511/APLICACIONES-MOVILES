class EvidenciaModel {
  final int idEvidencia;
  final int idSolicitud;
  final String nombreArchivo;
  final String tipoContenido;
  final int tamanoBytes;
  final DateTime fechaCreacion;
  final String url;

  const EvidenciaModel({
    required this.idEvidencia,
    required this.idSolicitud,
    required this.nombreArchivo,
    required this.tipoContenido,
    required this.tamanoBytes,
    required this.fechaCreacion,
    required this.url,
  });

  factory EvidenciaModel.fromJson(Map<String, dynamic> json) {
    return EvidenciaModel(
      idEvidencia: (json['idEvidencia'] as num).toInt(),
      idSolicitud: (json['idSolicitud'] as num).toInt(),
      nombreArchivo: json['nombreArchivo'] as String,
      tipoContenido: json['tipoContenido'] as String,
      tamanoBytes: (json['tamanoBytes'] as num).toInt(),
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      url: json['url'] as String,
    );
  }
}

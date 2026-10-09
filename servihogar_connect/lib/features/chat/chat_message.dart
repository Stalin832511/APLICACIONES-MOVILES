class ChatMessage {
  const ChatMessage({
    required this.idMensaje,
    required this.idEmisor,
    required this.nombreEmisor,
    required this.apellidoEmisor,
    required this.idReceptor,
    required this.mensaje,
    required this.fechaEnvio,
  });

  final int idMensaje;
  final int idEmisor;
  final String nombreEmisor;
  final String apellidoEmisor;
  final int idReceptor;
  final String mensaje;
  final DateTime fechaEnvio;

  String get nombreCompleto =>
      [nombreEmisor, apellidoEmisor]
          .where((parte) => parte.trim().isNotEmpty)
          .join(' ');

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      idMensaje: _asInt(json['idMensaje'] ?? json['IdMensaje']) ?? 0,
      idEmisor: _asInt(json['idEmisor'] ?? json['IdEmisor']) ?? 0,
      nombreEmisor:
          (json['nombreEmisor'] ?? json['NombreEmisor'] ?? '').toString(),
      apellidoEmisor:
          (json['apellidoEmisor'] ?? json['ApellidoEmisor'] ?? '').toString(),
      idReceptor: _asInt(json['idReceptor'] ?? json['IdReceptor']) ?? 0,
      mensaje: (json['mensaje'] ?? json['Mensaje'] ?? '').toString(),
      fechaEnvio: DateTime.tryParse(
            (json['fechaEnvio'] ?? json['FechaEnvio'] ?? '').toString(),
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    return value == null ? null : int.tryParse(value.toString());
  }
}

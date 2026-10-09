import 'package:flutter_test/flutter_test.dart';
import 'package:servihogar_connect/models/evidencia.dart';

void main() {
  test('parses all evidence metadata fields', () {
    final evidencia = EvidenciaModel.fromJson({
      'idEvidencia': 12,
      'idSolicitud': 34,
      'nombreArchivo': 'fachada.jpg',
      'tipoContenido': 'image/jpeg',
      'tamanoBytes': 2048,
      'fechaCreacion': '2026-10-02T12:30:00Z',
      'url': '/api/solicitudes/34/evidencias/12/archivo',
    });

    expect(evidencia.idEvidencia, 12);
    expect(evidencia.idSolicitud, 34);
    expect(evidencia.nombreArchivo, 'fachada.jpg');
    expect(evidencia.tipoContenido, 'image/jpeg');
    expect(evidencia.tamanoBytes, 2048);
    expect(evidencia.fechaCreacion, DateTime.parse('2026-10-02T12:30:00Z'));
    expect(evidencia.url, '/api/solicitudes/34/evidencias/12/archivo');
  });
}

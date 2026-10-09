import 'package:flutter_test/flutter_test.dart';
import 'package:servihogar_connect/features/chat/chat_message.dart';

void main() {
  test('parses an API chat message and formats the sender name', () {
    final message = ChatMessage.fromJson({
      'idMensaje': 7,
      'idEmisor': 12,
      'nombreEmisor': 'Ana',
      'apellidoEmisor': 'García',
      'idReceptor': 19,
      'mensaje': 'Llego a las 10.',
      'fechaEnvio': '2026-10-06T15:30:00Z',
    });

    expect(message.idMensaje, 7);
    expect(message.idEmisor, 12);
    expect(message.nombreCompleto, 'Ana García');
    expect(message.mensaje, 'Llego a las 10.');
    expect(message.fechaEnvio.isUtc, isTrue);
  });
}

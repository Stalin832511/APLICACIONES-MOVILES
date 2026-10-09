import 'package:dio/dio.dart';

import '../../network/api_client.dart';
import 'chat_message.dart';

class ChatService {
  ChatService({Dio? dio}) : _dio = dio ?? ApiClient.instance;

  final Dio _dio;

  Future<List<ChatMessage>> getMessages({
    required int requestId,
    int afterId = 0,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/api/solicitudes/$requestId/chat',
        queryParameters: {'afterId': afterId},
      );
      return (response.data ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => ChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ChatServiceException(_errorMessage(error));
    }
  }

  Future<ChatMessage> sendMessage({
    required int requestId,
    required String message,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/solicitudes/$requestId/chat',
        data: {'mensaje': message},
      );
      final data = response.data;
      if (data == null) {
        throw const ChatServiceException(
          'El servidor no devolvió el mensaje enviado.',
        );
      }
      return ChatMessage.fromJson(data);
    } on DioException catch (error) {
      throw ChatServiceException(_errorMessage(error));
    }
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['mensaje'] ?? data['message'] ?? data['title'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    if (error.response == null) {
      return 'No se pudo conectar para sincronizar el chat.';
    }
    return 'No se pudo completar la operación de chat '
        '(código ${error.response?.statusCode ?? 'desconocido'}).';
  }
}

class ChatServiceException implements Exception {
  const ChatServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

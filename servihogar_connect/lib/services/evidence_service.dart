import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../models/evidencia.dart';
import '../network/api_client.dart';

/// Authenticated API operations for request evidence.
class EvidenceService {
  static Future<void> upload({
    required int idSolicitud,
    required String filePath,
  }) async {
    await ApiClient.instance.post<void>(
      '/api/solicitudes/$idSolicitud/evidencias',
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      }),
    );
  }

  static Future<List<EvidenciaModel>> list({
    required int idSolicitud,
  }) async {
    final response = await ApiClient.instance.get<List<dynamic>>(
      '/api/solicitudes/$idSolicitud/evidencias',
    );
    return (response.data ?? const <dynamic>[])
        .map(
          (item) => EvidenciaModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  static Future<Uint8List> fetchBytes({
    required int idSolicitud,
    required int evidenciaId,
  }) async {
    final response = await ApiClient.instance.get<List<int>>(
      '/api/solicitudes/$idSolicitud/evidencias/$evidenciaId/archivo',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const <int>[]);
  }
}

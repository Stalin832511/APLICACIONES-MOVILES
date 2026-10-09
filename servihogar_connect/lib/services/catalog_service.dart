import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../config/api_config.dart';
import '../models/categoria.dart';
import 'api_service.dart';

class CatalogService {
  static const _cacheFileName = 'service_categories.json';

  static Future<({List<CategoriaModel> categories, bool fromCache})>
      loadCategories() async {
    try {
      final categories = await ApiService.fetchCategorias();
      await _saveCache(categories);
      return (categories: categories, fromCache: false);
    } on SocketException catch (error) {
      return _loadCacheOrThrow(error);
    } on TimeoutException catch (error) {
      return _loadCacheOrThrow(error);
    } on http.ClientException catch (error) {
      return _loadCacheOrThrow(error);
    }
  }

  static Future<({List<CategoriaModel> categories, bool fromCache})>
      _loadCacheOrThrow(Object cause) async {
    final cacheFile = await _cacheFile();
    if (!await cacheFile.exists()) {
      throw Exception(
        'No se pudo conectar con el servidor y todavía no hay '
        'categorías guardadas en este dispositivo. '
        'La URL configurada es ${ApiConfig.baseUrl}. '
        'En Android físico por USB ejecuta '
        '"adb reverse tcp:5125 tcp:5125" y verifica que la API esté '
        'activa en el puerto 5125. ($cause)',
      );
    }

    final decoded = jsonDecode(await cacheFile.readAsString())
        as List<dynamic>;
    final categories = decoded
        .map(
          (item) => CategoriaModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return (categories: categories, fromCache: true);
  }

  static Future<void> _saveCache(
    List<CategoriaModel> categories,
  ) async {
    try {
      final cacheFile = await _cacheFile();
      await cacheFile.writeAsString(
        jsonEncode(categories.map((category) => category.toJson()).toList()),
        flush: true,
      );
    } on FileSystemException catch (error) {
      debugPrint('No se pudo actualizar la caché del catálogo: $error');
    }
  }

  static Future<File> _cacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$_cacheFileName');
  }
}

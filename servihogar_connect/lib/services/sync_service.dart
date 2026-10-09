import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../database/app_database.dart';
import 'api_service.dart';
import 'evidence_service.dart';

class SyncService {
  final AppDatabase database;

  SyncService(this.database);

  Future<void> processPendingOperations() async {
    debugPrint(
      '========================================',
    );
    debugPrint(
      'INICIANDO SINCRONIZACIÓN',
    );
    debugPrint(
      '========================================',
    );

    final operaciones =
        await database.syncQueueDao
            .getPendingOperations();

    debugPrint(
      'OPERACIONES PENDIENTES: '
      '${operaciones.length}',
    );

    if (operaciones.isEmpty) {
      debugPrint(
        'SYNC: NO HAY OPERACIONES PENDIENTES',
      );
      return;
    }

    for (final operacion
        in operaciones) {
      await _procesarOperacion(
        operacion,
      );
    }

    debugPrint(
      '========================================',
    );
    debugPrint(
      'SINCRONIZACIÓN TERMINADA',
    );
    debugPrint(
      '========================================',
    );
  }

  Future<void> _procesarOperacion(
    SyncQueueData operacion,
  ) async {
    debugPrint(
      '----------------------------------------',
    );
    debugPrint(
      'PROCESANDO OPERACIÓN: '
      '${operacion.operationId}',
    );
    debugPrint(
      'TIPO: '
      '${operacion.operationType}',
    );
    debugPrint(
      'INTENTO ACTUAL: '
      '${operacion.retryCount}',
    );
    debugPrint(
      '----------------------------------------',
    );

    try {
      final payload =
          jsonDecode(
                operacion.payload,
              )
              as Map<String, dynamic>;

      switch (
          operacion.operationType) {
        case 'crear_solicitud':
          await _crearSolicitud(
            payload,
          );
          break;

        default:
          throw Exception(
            'Tipo de operación no soportado: '
            '${operacion.operationType}',
          );
      }

      await database.syncQueueDao
          .deleteOperation(
        operacion.id,
      );

      debugPrint(
        'SYNC OK: operación '
        '${operacion.operationId} '
        'eliminada de la cola.',
      );
    } catch (
        e,
        stackTrace) {
      debugPrint(
        'SYNC ERROR: '
        '${operacion.operationId}',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      if ((e is DioException &&
              (e.response?.statusCode == 400 ||
                  e.response?.statusCode == 422)) ||
          (e is ApiServiceException &&
              (e.statusCode == 400 || e.statusCode == 422))) {
        await database.syncQueueDao.updateRetry(
          operacion.id,
          retryCount: operacion.retryCount + 1,
          status: 'failed',
          nextRetryAt: null,
        );
        return;
      }

      await _registrarReintento(
        operacion,
      );
    }
  }

  Future<void> _crearSolicitud(
    Map<String, dynamic> payload,
  ) async {
    final clientOperationId =
        payload['clientOperationId']
            as String;

    debugPrint(
      'ENVIANDO SOLICITUD AL SERVIDOR...',
    );

    debugPrint(
      'clientOperationId: '
      '$clientOperationId',
    );

    final solicitud =
        await ApiService.crearSolicitud(
      idUsuario:
          payload['idUsuario']
              as int,
      idCategoria:
          payload['idCategoria']
              as int,
      clientOperationId:
          clientOperationId,
      descripcion:
          payload['descripcion']
              as String,
      latitud:
          (payload['latitud'] as num)
              .toDouble(),
      longitud:
          (payload['longitud'] as num)
              .toDouble(),
    );

    final fotoPath = payload['fotoPath'] as String?;
    if (fotoPath != null && fotoPath.isNotEmpty) {
      await EvidenceService.upload(
        idSolicitud: solicitud.id,
        filePath: fotoPath,
      );
    }

    debugPrint(
      'SOLICITUD SINCRONIZADA CORRECTAMENTE',
    );

    debugPrint(
      'ID SERVIDOR: '
      '${solicitud.id}',
    );

    debugPrint(
      'DESCRIPCIÓN: '
      '${solicitud.descripcion}',
    );

    // ==================================================
    // ELIMINAR EL REGISTRO LOCAL TEMPORAL
    // ==================================================

    await database.serviceRequestDao
        .deleteByClientOperationId(
      clientOperationId,
    );

    debugPrint(
      'REGISTRO LOCAL TEMPORAL ELIMINADO',
    );

    // ==================================================
    // GUARDAR EL REGISTRO REAL DEL SERVIDOR
    // ==================================================

    await database.serviceRequestDao
        .upsertRequest(
      ServiceRequestsCompanion.insert(
        id:
            solicitud.id.toString(),
        clientOperationId:
            drift.Value(
          clientOperationId,
        ),
        description:
            solicitud.descripcion,
        status:
            solicitud.status.name,
        createdAt:
            solicitud.fechaCreacion,
        updatedAt:
            drift.Value(
          solicitud.fechaCreacion,
        ),
        serverUpdatedAt:
            drift.Value(
          solicitud.fechaCreacion,
        ),
        cachedAt:
            DateTime.now(),
      ),
    );

    debugPrint(
      'REGISTRO REAL GUARDADO EN SQLITE',
    );

    debugPrint(
      'SOLICITUD OFFLINE -> ONLINE COMPLETADA',
    );
  }

  Future<void> _registrarReintento(
    SyncQueueData operacion,
  ) async {
    final nuevoRetryCount =
        operacion.retryCount + 1;

    const maxRetries = 5;

    if (nuevoRetryCount >=
        maxRetries) {
      await database.syncQueueDao
          .updateRetry(
        operacion.id,
        retryCount:
            nuevoRetryCount,
        status: 'failed',
        nextRetryAt: null,
      );

      debugPrint(
        'SYNC: operación '
        '${operacion.operationId} '
        'alcanzó el máximo de reintentos.',
      );

      return;
    }

    final segundosEspera =
        _calcularBackoff(
      nuevoRetryCount,
    );

    final siguienteIntento =
        DateTime.now().add(
      Duration(
        seconds:
            segundosEspera,
      ),
    );

    await database.syncQueueDao
        .updateRetry(
      operacion.id,
      retryCount:
          nuevoRetryCount,
      status: 'pending',
      nextRetryAt:
          siguienteIntento,
    );

    debugPrint(
      'SYNC: reintento '
      '$nuevoRetryCount '
      'programado en '
      '$segundosEspera segundos.',
    );
  }

  int _calcularBackoff(
    int retryCount,
  ) {
    switch (retryCount) {
      case 1:
        return 5;

      case 2:
        return 10;

      case 3:
        return 20;

      case 4:
        return 40;

      default:
        return 60;
    }
  }
}
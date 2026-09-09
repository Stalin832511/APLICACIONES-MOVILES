import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sync_queue.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  /// Obtiene las operaciones pendientes cuyo momento
  /// de reintento ya ha llegado.
  Future<List<SyncQueueData>> getPendingOperations() {
    final ahora = DateTime.now();

    return (select(syncQueue)
          ..where(
            (table) =>
                table.status.equals('pending') &
                (table.nextRetryAt.isNull() |
                    table.nextRetryAt.isSmallerOrEqualValue(ahora)),
          )
          ..orderBy([
            (table) => OrderingTerm(
                  expression: table.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// Guarda una nueva operación en la cola local.
  Future<void> insertOperation(
    SyncQueueCompanion operation,
  ) {
    return into(syncQueue).insert(operation);
  }

  /// Elimina una operación después de sincronizarla
  /// correctamente con el servidor.
  Future<void> deleteOperation(String id) {
    return (delete(syncQueue)
          ..where((table) => table.id.equals(id)))
        .go();
  }

  /// Elimina toda la cola local.
  ///
  /// Se utilizará al cerrar sesión para cumplir
  /// con el requisito de limpieza de datos locales.
  Future<void> deleteAllOperations() {
    return delete(syncQueue).go();
  }

  /// Actualiza el número de reintentos y el estado
  /// de una operación que no pudo sincronizarse.
  Future<void> updateRetry(
    String id, {
    required int retryCount,
    required String status,
    DateTime? nextRetryAt,
  }) {
    return (update(syncQueue)
          ..where((table) => table.id.equals(id)))
        .write(
      SyncQueueCompanion(
        retryCount: Value(retryCount),
        status: Value(status),
        nextRetryAt: Value(nextRetryAt),
      ),
    );
  }
}
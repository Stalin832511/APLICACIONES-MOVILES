import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/service_requests.dart';

part 'service_request_dao.g.dart';

@DriftAccessor(tables: [ServiceRequests])
class ServiceRequestDao extends DatabaseAccessor<AppDatabase>
    with _$ServiceRequestDaoMixin {
  ServiceRequestDao(super.db);

  Future<List<ServiceRequest>> getAllRequests() {
    return (select(serviceRequests)
          ..orderBy([
            (table) => OrderingTerm(
                  expression: table.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  Stream<List<ServiceRequest>> watchAllRequests() {
    return (select(serviceRequests)
          ..orderBy([
            (table) => OrderingTerm(
                  expression: table.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<void> insertRequest(
    ServiceRequestsCompanion request,
  ) {
    return into(serviceRequests).insert(request);
  }

  Future<void> upsertRequest(
    ServiceRequestsCompanion request,
  ) async {
    final id = request.id.value;

    await (delete(serviceRequests)
          ..where((table) => table.id.equals(id)))
        .go();

    await into(serviceRequests).insert(request);
  }

  /// Elimina una solicitud local usando su
  /// clientOperationId.
  ///
  /// Se utiliza cuando una solicitud creada offline
  /// ya fue sincronizada y ahora debemos reemplazar
  /// el registro local temporal por el registro real
  /// del servidor.
  Future<void> deleteByClientOperationId(
    String clientOperationId,
  ) async {
    await (delete(serviceRequests)
          ..where(
            (table) =>
                table.clientOperationId.equals(clientOperationId),
          ))
        .go();
  }

  /// Elimina todas las solicitudes locales.
  ///
  /// Se utiliza al cerrar sesión.
  Future<void> deleteAllRequests() {
    return delete(serviceRequests).go();
  }
}
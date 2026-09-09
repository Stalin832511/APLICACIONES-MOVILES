// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_request_dao.dart';

// ignore_for_file: type=lint
mixin _$ServiceRequestDaoMixin on DatabaseAccessor<AppDatabase> {
  $ServiceRequestsTable get serviceRequests => attachedDatabase.serviceRequests;
  ServiceRequestDaoManager get managers => ServiceRequestDaoManager(this);
}

class ServiceRequestDaoManager {
  final _$ServiceRequestDaoMixin _db;
  ServiceRequestDaoManager(this._db);
  $$ServiceRequestsTableTableManager get serviceRequests =>
      $$ServiceRequestsTableTableManager(
        _db.attachedDatabase,
        _db.serviceRequests,
      );
}

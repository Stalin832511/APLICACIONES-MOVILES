import 'package:drift/drift.dart';

class SyncQueue extends Table {
  TextColumn get id => text()();

  TextColumn get operationId => text()();

  TextColumn get operationType => text()();

  TextColumn get payload => text()();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  TextColumn get status => text()();
}
import 'package:drift/drift.dart';

class ServiceRequests extends Table {
  TextColumn get id => text()();

  TextColumn get clientOperationId => text().nullable()();

  TextColumn get description => text()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime().nullable()();

  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  DateTimeColumn get cachedAt => dateTime()();
}
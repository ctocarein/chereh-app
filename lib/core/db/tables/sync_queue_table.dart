import 'package:drift/drift.dart';

/// File d'attente des mutations offline (POST/PATCH/DELETE) à rejouer quand le réseau revient.
class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get method => text()(); // POST | PATCH | DELETE
  TextColumn get endpoint => text()();
  TextColumn get payload => text().nullable()(); // JSON encodé
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

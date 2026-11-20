import 'package:drift/drift.dart';

class Vehicles extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get registrationNumber => text()();
  TextColumn get vin => text().nullable()();
  TextColumn get make => text()();
  TextColumn get model => text()();
  TextColumn get bodyType => text()();
  TextColumn get paintCode => text().nullable()();
  IntColumn get odometerKm => integer()();
  IntColumn get fuelLevelPercent => integer().withDefault(const Constant(50))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get name => text()();
  TextColumn get phone => text()();
  BoolColumn get consentWhatsapp =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class JobCards extends Table {
  TextColumn get id => text()(); // Client UUID
  TextColumn get vehicleId => text().references(Vehicles, #id)();
  TextColumn get customerId => text().references(Customers, #id)();
  TextColumn get status => text()(); // RECEIVED, INSPECTION_PENDING, ESTIMATE_SENT, WORK_IN_PROGRESS, DELIVERED
  TextColumn get assignedTechnician => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class JobLineItems extends Table {
  TextColumn get id => text()();
  TextColumn get jobCardId => text().references(JobCards, #id)();
  TextColumn get type => text()(); // labour, part
  TextColumn get description => text()();
  TextColumn get code => text()(); // SAC 998714 or HSN
  IntColumn get quantity => integer()();
  IntColumn get unitRatePaise => integer()(); // Integer paise
  IntColumn get gstRatePercent => integer()(); // 18 or 28
  TextColumn get approvalStatus => text().withDefault(
    const Constant('PENDING'),
  )(); // PENDING, APPROVED, DECLINED

  @override
  Set<Column> get primaryKey => {id};
}

class BayPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get jobCardId => text().references(JobCards, #id)();
  TextColumn get shotType =>
      text()(); // CORNER_FL, CORNER_FR, CORNER_RL, CORNER_RR, PLATE, ODOMETER
  TextColumn get localPath => text()();
  TextColumn get sha256Hash => text()();
  DateTimeColumn get capturedAt => dateTime()();
  BoolColumn get isUploaded => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbox Table: Guarantees 100% offline-first reliability.
/// Every local write inserts an outbox entry.
class OutboxRecords extends Table {
  TextColumn get id => text()(); // Unique mutation UUID
  TextColumn get targetTable => text()(); // e.g. 'vehicles', 'job_cards'
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // 'INSERT', 'UPDATE', 'DELETE'
  TextColumn get payloadJson => text()(); // Serialized record payload
  TextColumn get status => text().withDefault(
    const Constant('PENDING'),
  )(); // PENDING, SYNCING, SYNCED, FAILED
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

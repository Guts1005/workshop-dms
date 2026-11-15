import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:workshop_dms/data/sync/outbox_sync_service.dart';
import '../models/intake_form_state.dart';

class CustomerRecord {
  final String id;
  final String name;
  final String phone;
  final bool consentWhatsapp;
  final DateTime createdAt;

  CustomerRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.consentWhatsapp,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'consentWhatsapp': consentWhatsapp,
        'createdAt': createdAt.toIso8601String(),
      };
}

class VehicleRecord {
  final String id;
  final String registrationNumber;
  final String? vin;
  final String make;
  final String model;
  final String bodyType;
  final int odometerKm;
  final int fuelLevelPercent;
  final DateTime createdAt;

  VehicleRecord({
    required this.id,
    required this.registrationNumber,
    this.vin,
    required this.make,
    required this.model,
    required this.bodyType,
    required this.odometerKm,
    required this.fuelLevelPercent,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'registrationNumber': registrationNumber,
        'vin': vin,
        'make': make,
        'model': model,
        'bodyType': bodyType,
        'odometerKm': odometerKm,
        'fuelLevelPercent': fuelLevelPercent,
        'createdAt': createdAt.toIso8601String(),
      };
}

class JobCardRecord {
  final String id;
  final String vehicleId;
  final String customerId;
  final String status;
  final String requestedWork;
  final DateTime expectedDelivery;
  final Map<String, bool> belongings;
  final DateTime createdAt;

  JobCardRecord({
    required this.id,
    required this.vehicleId,
    required this.customerId,
    required this.status,
    required this.requestedWork,
    required this.expectedDelivery,
    required this.belongings,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'customerId': customerId,
        'status': status,
        'requestedWork': requestedWork,
        'expectedDelivery': expectedDelivery.toIso8601String(),
        'belongings': belongings,
        'createdAt': createdAt.toIso8601String(),
      };
}

abstract class IntakeRepository {
  Future<CustomerRecord?> findCustomerByPhone(String phone);
  Future<VehicleRecord?> findVehicleByRegistration(String registrationNumber);
  Future<List<PreviousServiceSummary>> getVehicleServiceHistory(String vehicleId);
  Future<String> submitIntake(IntakeFormState formState);
}

/// Offline-first In-Memory and SQLite repository backed by OutboxSyncService
class LocalIntakeRepository implements IntakeRepository {
  final OutboxSyncService? outboxSyncService;
  final _uuid = const Uuid();

  // Local persistent stores
  final Map<String, CustomerRecord> _customers = {};
  final Map<String, VehicleRecord> _vehicles = {};
  final Map<String, JobCardRecord> _jobCards = {};
  final Map<String, List<PreviousServiceSummary>> _historyByVehicleId = {};

  LocalIntakeRepository({this.outboxSyncService});

  /// Seed initial demo data (for showroom and existing car testing)
  void seedDemoData() {
    const custId = 'cust-demo-1';
    const vehId = 'veh-demo-1';

    _customers['9829012345'] = CustomerRecord(
      id: custId,
      name: 'Aditya Mehta',
      phone: '9829012345',
      consentWhatsapp: true,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );

    _vehicles['RJ27CA1024'] = VehicleRecord(
      id: vehId,
      registrationNumber: 'RJ27CA1024',
      vin: 'MA3EWA12S00123456',
      make: 'MG MOTOR',
      model: 'HECTOR PLUS SHARP PRO',
      bodyType: 'MID/FULL SUV',
      odometerKm: 27227,
      fuelLevelPercent: 65,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
    );

    _historyByVehicleId[vehId] = [
      PreviousServiceSummary(
        jobCardId: 'jc-prev-1',
        serviceDate: DateTime(2026, 6, 18),
        odometerKm: 27227,
        totalAmountPaise: 747672,
        orderId: 'N330302623',
        feedback: 'Exceptional',
      ),
      PreviousServiceSummary(
        jobCardId: 'jc-prev-2',
        serviceDate: DateTime(2026, 3, 31),
        odometerKm: 23279,
        totalAmountPaise: 0,
        orderId: 'N330301684',
        feedback: 'Exceptional',
      ),
      PreviousServiceSummary(
        jobCardId: 'jc-prev-3',
        serviceDate: DateTime(2026, 2, 9),
        odometerKm: 20711,
        totalAmountPaise: 924582,
        orderId: 'N330301285',
        feedback: 'Exceptional',
      ),
    ];
  }

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final normalized = cleaned.length > 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
    return _customers[normalized];
  }

  @override
  Future<VehicleRecord?> findVehicleByRegistration(String registrationNumber) async {
    final normalized = registrationNumber.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    return _vehicles[normalized];
  }

  @override
  Future<List<PreviousServiceSummary>> getVehicleServiceHistory(String vehicleId) async {
    return _historyByVehicleId[vehicleId] ?? [];
  }

  @override
  Future<String> submitIntake(IntakeFormState formState) async {
    final normalizedReg = formState.registrationNumber.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    final normalizedPhone = formState.customerPhone.replaceAll(RegExp(r'[\s\-]'), '');
    final cleanPhone = normalizedPhone.length > 10 ? normalizedPhone.substring(normalizedPhone.length - 10) : normalizedPhone;

    // 1. Resolve or Create Customer
    var customer = _customers[cleanPhone];
    if (customer == null) {
      final newCustId = _uuid.v4();
      customer = CustomerRecord(
        id: newCustId,
        name: formState.customerName.trim(),
        phone: cleanPhone,
        consentWhatsapp: formState.whatsappConsent,
        createdAt: DateTime.now(),
      );
      _customers[cleanPhone] = customer;

      // Queue Outbox mutation
      outboxSyncService?.enqueue(
        id: _uuid.v4(),
        targetTable: 'customers',
        recordId: newCustId,
        operation: 'INSERT',
        payload: customer.toJson(),
      );
    }

    // 2. Resolve or Create Vehicle
    final km = int.tryParse(formState.odometer) ?? 0;
    var vehicle = _vehicles[normalizedReg];
    final vehId = vehicle?.id ?? _uuid.v4();
    vehicle = VehicleRecord(
      id: vehId,
      registrationNumber: normalizedReg,
      vin: formState.vin.trim().isNotEmpty ? formState.vin.trim().toUpperCase() : null,
      make: formState.make,
      model: formState.model.trim(),
      bodyType: formState.bodyType.label,
      odometerKm: km,
      fuelLevelPercent: formState.fuelLevelPercent,
      createdAt: vehicle?.createdAt ?? DateTime.now(),
    );
    _vehicles[normalizedReg] = vehicle;

    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'vehicles',
      recordId: vehId,
      operation: 'UPSERT',
      payload: vehicle.toJson(),
    );

    // 3. Create Job Card with initial status 'RECEIVED'
    final jobCardId = _uuid.v4();
    final jobCard = JobCardRecord(
      id: jobCardId,
      vehicleId: vehId,
      customerId: customer.id,
      status: 'RECEIVED',
      requestedWork: formState.requestedWork.trim(),
      expectedDelivery: formState.expectedDelivery ?? DateTime.now().add(const Duration(days: 1)),
      belongings: formState.belongings.toMap(),
      createdAt: DateTime.now(),
    );
    _jobCards[jobCardId] = jobCard;

    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'job_cards',
      recordId: jobCardId,
      operation: 'INSERT',
      payload: jobCard.toJson(),
    );

    return jobCardId;
  }
}

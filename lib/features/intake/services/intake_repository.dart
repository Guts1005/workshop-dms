import 'dart:async';
import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:workshop_dms/data/sync/outbox_sync_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase/workshop_database.dart';

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

class _IntakeRequestResult {
  const _IntakeRequestResult({
    required this.jobCardId,
    required this.fingerprint,
  });

  final String jobCardId;
  final String fingerprint;
}

abstract class IntakeRepository {
  Future<CustomerRecord?> findCustomerByPhone(String phone);
  Future<VehicleRecord?> findVehicleByRegistration(String registrationNumber);
  Future<List<PreviousServiceSummary>> getVehicleServiceHistory(
    String vehicleId,
  );
  Future<String> submitIntake(
    IntakeFormState formState, {
    required String requestId,
  });
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
  final Map<String, _IntakeRequestResult> _jobCardByRequestId = {};

  LocalIntakeRepository({this.outboxSyncService});

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    final normalized = cleaned.length > 10
        ? cleaned.substring(cleaned.length - 10)
        : cleaned;
    return _customers[normalized];
  }

  @override
  Future<VehicleRecord?> findVehicleByRegistration(
    String registrationNumber,
  ) async {
    final normalized = registrationNumber.toUpperCase().replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );
    return _vehicles[normalized];
  }

  @override
  Future<List<PreviousServiceSummary>> getVehicleServiceHistory(
    String vehicleId,
  ) async {
    return _historyByVehicleId[vehicleId] ?? [];
  }

  @override
  Future<String> submitIntake(
    IntakeFormState formState, {
    required String requestId,
  }) async {
    final fingerprint = _intakeFingerprint(formState);
    final existing = _jobCardByRequestId[requestId];
    if (existing != null) {
      if (existing.fingerprint != fingerprint) {
        throw StateError(
          'This intake request ID was already used with different details.',
        );
      }
      return existing.jobCardId;
    }

    final normalizedReg = formState.registrationNumber.toUpperCase().replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );
    final normalizedPhone = formState.customerPhone.replaceAll(
      RegExp(r'[\s\-]'),
      '',
    );
    final cleanPhone = normalizedPhone.length > 10
        ? normalizedPhone.substring(normalizedPhone.length - 10)
        : normalizedPhone;

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
      vin: formState.vin.trim().isNotEmpty
          ? formState.vin.trim().toUpperCase()
          : null,
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
      expectedDelivery:
          formState.expectedDelivery ??
          DateTime.now().add(const Duration(days: 1)),
      belongings: formState.belongings.toMap(),
      createdAt: DateTime.now(),
    );
    _jobCards[jobCardId] = jobCard;
    _jobCardByRequestId[requestId] = _IntakeRequestResult(
      jobCardId: jobCardId,
      fingerprint: fingerprint,
    );

    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'job_cards',
      recordId: jobCardId,
      operation: 'INSERT',
      payload: jobCard.toJson(),
    );

    return jobCardId;
  }

  String _intakeFingerprint(IntakeFormState state) {
    final phoneDigits = state.customerPhone.replaceAll(RegExp(r'\D'), '');
    final normalizedPhone = phoneDigits.length > 10
        ? phoneDigits.substring(phoneDigits.length - 10)
        : phoneDigits;
    return jsonEncode({
      'registration_number': state.registrationNumber.toUpperCase().replaceAll(
        RegExp(r'[\s-]'),
        '',
      ),
      'vin': state.vin.trim().isEmpty ? null : state.vin.trim().toUpperCase(),
      'make': state.make.trim(),
      'model': state.model.trim(),
      'body_type': state.bodyType.label,
      'customer_name': state.customerName.trim(),
      'customer_phone': normalizedPhone,
      'whatsapp_consent': state.whatsappConsent,
      'odometer_km': int.tryParse(state.odometer),
      'fuel_level_percent': state.fuelLevelPercent,
      'requested_work': state.requestedWork.trim(),
      'expected_delivery': state.expectedDelivery?.toUtc().toIso8601String(),
      'belongings': state.belongings.toMap(),
    });
  }
}

class SupabaseIntakeRepository implements IntakeRepository {
  SupabaseIntakeRepository(this.client) : _database = WorkshopDatabase(client);

  final SupabaseClient client;
  final WorkshopDatabase _database;

  @override
  Future<CustomerRecord?> findCustomerByPhone(String phone) async {
    final workshopId = await _database.currentWorkshopId();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final normalized = digits.length > 10
        ? digits.substring(digits.length - 10)
        : digits;
    final row = await client
        .from('customers')
        .select('id, name, phone, consent_whatsapp, created_at')
        .eq('workshop_id', workshopId)
        .eq('phone', normalized)
        .maybeSingle();
    if (row == null) return null;
    return CustomerRecord(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      consentWhatsapp: row['consent_whatsapp'] as bool,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<VehicleRecord?> findVehicleByRegistration(
    String registrationNumber,
  ) async {
    final workshopId = await _database.currentWorkshopId();
    final normalized = registrationNumber.toUpperCase().replaceAll(
      RegExp(r'[\s-]'),
      '',
    );
    final row = await client
        .from('vehicles')
        .select(
          'id, registration_number, vin, make, model, body_type, odometer_km, fuel_level_percent, created_at',
        )
        .eq('workshop_id', workshopId)
        .eq('registration_number', normalized)
        .maybeSingle();
    if (row == null) return null;
    return VehicleRecord(
      id: row['id'] as String,
      registrationNumber: row['registration_number'] as String,
      vin: row['vin'] as String?,
      make: row['make'] as String,
      model: row['model'] as String,
      bodyType: row['body_type'] as String,
      odometerKm: row['odometer_km'] as int,
      fuelLevelPercent: row['fuel_level_percent'] as int,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  @override
  Future<List<PreviousServiceSummary>> getVehicleServiceHistory(
    String vehicleId,
  ) async {
    final workshopId = await _database.currentWorkshopId();
    final rows = await client
        .from('job_cards')
        .select('id, created_at, intake_odometer_km, requested_work')
        .eq('workshop_id', workshopId)
        .eq('vehicle_id', vehicleId)
        .neq('status', 'CANCELLED')
        .order('created_at', ascending: false);
    return rows
        .map(
          (row) => PreviousServiceSummary(
            jobCardId: row['id'] as String,
            serviceDate: DateTime.parse(row['created_at'] as String),
            odometerKm: row['intake_odometer_km'] as int,
            orderId: row['id'] as String,
            totalAmountPaise: null,
            feedback: null,
            requestedWork: row['requested_work'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<String> submitIntake(
    IntakeFormState formState, {
    required String requestId,
  }) async {
    final result = await client.rpc(
      'create_application',
      params: {
        'p_registration_number': formState.registrationNumber,
        'p_vin': formState.vin,
        'p_make': formState.make,
        'p_model': formState.model,
        'p_body_type': formState.bodyType.label,
        'p_customer_name': formState.customerName,
        'p_customer_phone': formState.customerPhone,
        'p_whatsapp_consent': formState.whatsappConsent,
        'p_odometer_km': int.parse(formState.odometer),
        'p_fuel_level_percent': formState.fuelLevelPercent,
        'p_requested_work': formState.requestedWork,
        'p_expected_delivery': formState.expectedDelivery
            ?.toUtc()
            .toIso8601String(),
        'p_belongings': formState.belongings.toMap(),
        'p_request_id': requestId,
      },
    );
    if (result is! String || result.isEmpty) {
      throw const FormatException(
        'The database did not return the new application ID.',
      );
    }
    return result;
  }
}

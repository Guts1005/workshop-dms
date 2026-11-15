import 'package:flutter/foundation.dart';
import '../../vehicle/vehicle_silhouettes.dart';
export '../../vehicle/vehicle_silhouettes.dart' show VehicleBodyType;

enum IntakeStatus {
  idle,
  lookingUp,
  saving,
  success,
  error,
}

@immutable
class BelongingsChecklist {
  final bool jackAndToolKit;
  final bool spareTyre;
  final bool bootMat;
  final bool valuablesRemoved;
  final bool pendriveOrAccessories;

  const BelongingsChecklist({
    this.jackAndToolKit = true,
    this.spareTyre = true,
    this.bootMat = true,
    this.valuablesRemoved = true,
    this.pendriveOrAccessories = false,
  });

  BelongingsChecklist copyWith({
    bool? jackAndToolKit,
    bool? spareTyre,
    bool? bootMat,
    bool? valuablesRemoved,
    bool? pendriveOrAccessories,
  }) {
    return BelongingsChecklist(
      jackAndToolKit: jackAndToolKit ?? this.jackAndToolKit,
      spareTyre: spareTyre ?? this.spareTyre,
      bootMat: bootMat ?? this.bootMat,
      valuablesRemoved: valuablesRemoved ?? this.valuablesRemoved,
      pendriveOrAccessories: pendriveOrAccessories ?? this.pendriveOrAccessories,
    );
  }

  Map<String, bool> toMap() => {
        'jackAndToolKit': jackAndToolKit,
        'spareTyre': spareTyre,
        'bootMat': bootMat,
        'valuablesRemoved': valuablesRemoved,
        'pendriveOrAccessories': pendriveOrAccessories,
      };
}

@immutable
class PreviousServiceSummary {
  final String jobCardId;
  final DateTime serviceDate;
  final int odometerKm;
  final int totalAmountPaise;
  final String orderId;
  final String feedback;

  const PreviousServiceSummary({
    required this.jobCardId,
    required this.serviceDate,
    required this.odometerKm,
    required this.totalAmountPaise,
    required this.orderId,
    this.feedback = 'Exceptional',
  });
}

@immutable
class IntakeFormState {
  final IntakeStatus status;
  final String? errorMessage;
  final String? createdJobCardId;

  // Form Fields
  final String registrationNumber;
  final String vin;
  final String make;
  final String model;
  final VehicleBodyType bodyType;
  final String customerName;
  final String customerPhone;
  final String odometer;
  final int fuelLevelPercent;
  final String requestedWork;
  final DateTime? expectedDelivery;
  final bool whatsappConsent;
  final BelongingsChecklist belongings;

  // Existing History
  final bool isExistingCustomer;
  final bool isExistingVehicle;
  final List<PreviousServiceSummary> previousHistory;
  final int? lastRecordedKm;

  // Field validation errors
  final Map<String, String> errors;

  const IntakeFormState({
    this.status = IntakeStatus.idle,
    this.errorMessage,
    this.createdJobCardId,
    this.registrationNumber = '',
    this.vin = '',
    this.make = 'MARUTI SUZUKI',
    this.model = '',
    this.bodyType = VehicleBodyType.hatchback,
    this.customerName = '',
    this.customerPhone = '',
    this.odometer = '',
    this.fuelLevelPercent = 50,
    this.requestedWork = '',
    this.expectedDelivery,
    this.whatsappConsent = true,
    this.belongings = const BelongingsChecklist(),
    this.isExistingCustomer = false,
    this.isExistingVehicle = false,
    this.previousHistory = const [],
    this.lastRecordedKm,
    this.errors = const {},
  });

  IntakeFormState copyWith({
    IntakeStatus? status,
    String? errorMessage,
    String? createdJobCardId,
    String? registrationNumber,
    String? vin,
    String? make,
    String? model,
    VehicleBodyType? bodyType,
    String? customerName,
    String? customerPhone,
    String? odometer,
    int? fuelLevelPercent,
    String? requestedWork,
    DateTime? expectedDelivery,
    bool? whatsappConsent,
    BelongingsChecklist? belongings,
    bool? isExistingCustomer,
    bool? isExistingVehicle,
    List<PreviousServiceSummary>? previousHistory,
    int? lastRecordedKm,
    Map<String, String>? errors,
  }) {
    return IntakeFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      createdJobCardId: createdJobCardId ?? this.createdJobCardId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      vin: vin ?? this.vin,
      make: make ?? this.make,
      model: model ?? this.model,
      bodyType: bodyType ?? this.bodyType,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      odometer: odometer ?? this.odometer,
      fuelLevelPercent: fuelLevelPercent ?? this.fuelLevelPercent,
      requestedWork: requestedWork ?? this.requestedWork,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      whatsappConsent: whatsappConsent ?? this.whatsappConsent,
      belongings: belongings ?? this.belongings,
      isExistingCustomer: isExistingCustomer ?? this.isExistingCustomer,
      isExistingVehicle: isExistingVehicle ?? this.isExistingVehicle,
      previousHistory: previousHistory ?? this.previousHistory,
      lastRecordedKm: lastRecordedKm ?? this.lastRecordedKm,
      errors: errors ?? this.errors,
    );
  }
}

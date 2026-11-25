import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/intake_form_state.dart';
import '../services/intake_repository.dart';
import '../services/intake_validators.dart';

final intakeRepositoryProvider = Provider<IntakeRepository>((ref) {
  return SupabaseIntakeRepository(Supabase.instance.client);
});

final intakeControllerProvider =
    StateNotifierProvider.autoDispose<IntakeController, IntakeFormState>((ref) {
      final repo = ref.watch(intakeRepositoryProvider);
      return IntakeController(repository: repo);
    });

class IntakeController extends StateNotifier<IntakeFormState> {
  final IntakeRepository repository;
  int _vehicleLookupRequest = 0;
  int _customerLookupRequest = 0;
  String _submissionRequestId = const Uuid().v4();
  String? _lastSubmissionFingerprint;

  IntakeController({required this.repository}) : super(const IntakeFormState());

  void onRegistrationChanged(String value) {
    final resetVehicle = state.isExistingVehicle;
    state = state.copyWith(
      registrationNumber: value,
      make: resetVehicle ? '' : state.make,
      model: resetVehicle ? '' : state.model,
      bodyTypeConfirmed: resetVehicle ? false : state.bodyTypeConfirmed,
      fuelLevelObserved: false,
      vin: resetVehicle ? '' : state.vin,
      isExistingVehicle: resetVehicle ? false : state.isExistingVehicle,
      previousHistory: resetVehicle ? const [] : state.previousHistory,
      lastRecordedKm: resetVehicle ? null : state.lastRecordedKm,
      errors: Map.from(state.errors)..remove('registration'),
    );

    // Auto-lookup if registration reaches valid structure
    final error = IntakeValidators.validateRegistration(value);
    if (error == null) {
      lookupVehicle(value);
    } else {
      _vehicleLookupRequest++;
      state = state.copyWith(status: IntakeStatus.idle, errorMessage: null);
    }
  }

  Future<void> lookupVehicle(String registration) async {
    final request = ++_vehicleLookupRequest;
    state = state.copyWith(status: IntakeStatus.lookingUp);
    try {
      final vehicle = await repository.findVehicleByRegistration(registration);
      if (request != _vehicleLookupRequest ||
          state.registrationNumber.toUpperCase().replaceAll(
                RegExp(r'[\s-]'),
                '',
              ) !=
              registration.toUpperCase().replaceAll(RegExp(r'[\s-]'), '')) {
        return;
      }
      if (vehicle != null) {
        final history = await repository.getVehicleServiceHistory(vehicle.id);
        if (request != _vehicleLookupRequest) return;
        final lastKm = history.isNotEmpty
            ? history.first.odometerKm
            : vehicle.odometerKm;

        // Auto-match body type
        final matchingBodyType = VehicleBodyType.values.firstWhere(
          (b) => b.label.toUpperCase() == vehicle.bodyType.toUpperCase(),
          orElse: () => VehicleBodyType.hatchback,
        );

        state = state.copyWith(
          status: IntakeStatus.idle,
          isExistingVehicle: true,
          make: vehicle.make,
          model: vehicle.model,
          vin: vehicle.vin ?? state.vin,
          bodyType: matchingBodyType,
          bodyTypeConfirmed: true,
          // Saved fuel is historical; require a fresh slider adjustment.
          fuelLevelObserved: false,
          lastRecordedKm: lastKm,
          previousHistory: history,
          fuelLevelPercent: vehicle.fuelLevelPercent,
        );
      } else {
        state = state.copyWith(
          status: IntakeStatus.idle,
          isExistingVehicle: false,
          previousHistory: const [],
          lastRecordedKm: null,
        );
      }
    } catch (e) {
      if (request != _vehicleLookupRequest) return;
      state = state.copyWith(
        status: IntakeStatus.idle,
        errorMessage: 'Failed to look up vehicle: $e',
      );
    }
  }

  void onPhoneChanged(String value) {
    final previousPhone = IntakeValidators.normalizeMobile(state.customerPhone);
    final normalized = IntakeValidators.normalizeMobile(value);
    final phoneChanged = previousPhone != normalized;
    final resetCustomer = state.isExistingCustomer;
    state = state.copyWith(
      customerPhone: value,
      customerName: resetCustomer ? '' : state.customerName,
      isExistingCustomer: resetCustomer ? false : state.isExistingCustomer,
      whatsappConsent: phoneChanged ? false : state.whatsappConsent,
      errors: Map.from(state.errors)..remove('phone'),
    );

    if (normalized.length == 10) {
      lookupCustomer(normalized);
    }
  }

  Future<void> lookupCustomer(String phone) async {
    final request = ++_customerLookupRequest;
    try {
      final customer = await repository.findCustomerByPhone(phone);
      if (request != _customerLookupRequest ||
          IntakeValidators.normalizeMobile(state.customerPhone) !=
              IntakeValidators.normalizeMobile(phone)) {
        return;
      }
      if (customer != null) {
        state = state.copyWith(
          isExistingCustomer: true,
          customerName: customer.name,
          whatsappConsent: customer.consentWhatsapp,
        );
      } else {
        state = state.copyWith(
          isExistingCustomer: false,
          customerName: state.isExistingCustomer ? '' : state.customerName,
        );
      }
    } catch (e) {
      if (request == _customerLookupRequest) {
        state = state.copyWith(
          errorMessage: 'Could not look up this customer. You can still enter their details.',
        );
      }
    }
  }

  void onNameChanged(String value) {
    state = state.copyWith(
      customerName: value,
      isExistingCustomer: false,
      errors: Map.from(state.errors)..remove('name'),
    );
  }

  void onVinChanged(String value) {
    state = state.copyWith(
      vin: value,
      errors: Map.from(state.errors)..remove('vin'),
    );
  }

  void onMakeChanged(String value) {
    state = state.copyWith(
      make: value,
      errors: Map.from(state.errors)..remove('make'),
    );
  }

  void onModelChanged(String value) {
    state = state.copyWith(
      model: value,
      errors: Map.from(state.errors)..remove('model'),
    );
  }

  void onBodyTypeChanged(VehicleBodyType type) {
    state = state.copyWith(
      bodyType: type,
      bodyTypeConfirmed: true,
      errors: Map.from(state.errors)..remove('bodyType'),
    );
  }

  void onOdometerChanged(String value) {
    state = state.copyWith(
      odometer: value,
      errors: Map.from(state.errors)..remove('odometer'),
    );
  }

  void onFuelLevelChanged(int percent) {
    state = state.copyWith(
      fuelLevelPercent: percent,
      fuelLevelObserved: true,
      errors: Map.from(state.errors)..remove('fuelLevel'),
    );
  }

  void onRequestedWorkChanged(String value) {
    state = state.copyWith(
      requestedWork: value,
      errors: Map.from(state.errors)..remove('requestedWork'),
    );
  }

  void onExpectedDeliveryChanged(DateTime date) {
    state = state.copyWith(
      expectedDelivery: date,
      errors: Map.from(state.errors)..remove('expectedDelivery'),
    );
  }

  void onWhatsappConsentChanged(bool value) {
    state = state.copyWith(whatsappConsent: value);
  }

  void onBelongingsChanged(BelongingsChecklist belongings) {
    state = state.copyWith(belongings: belongings);
  }

  void onBelongingItemToggled(String itemKey, bool value) {
    final cur = state.belongings;
    BelongingsChecklist updated;
    switch (itemKey) {
      case 'jackAndToolKit':
        updated = cur.copyWith(jackAndToolKit: value);
        break;
      case 'spareTyre':
        updated = cur.copyWith(spareTyre: value);
        break;
      case 'bootMat':
        updated = cur.copyWith(bootMat: value);
        break;
      case 'valuablesRemoved':
        updated = cur.copyWith(valuablesRemoved: value);
        break;
      case 'pendriveOrAccessories':
        updated = cur.copyWith(pendriveOrAccessories: value);
        break;
      default:
        updated = cur;
    }
    state = state.copyWith(belongings: updated);
  }

  bool validateForm() {
    final errors = <String, String>{};

    final regErr = IntakeValidators.validateRegistration(
      state.registrationNumber,
    );
    if (regErr != null) errors['registration'] = regErr;

    if (state.make.trim().isEmpty) errors['make'] = 'Select the vehicle make';

    final phoneErr = IntakeValidators.validateMobile(state.customerPhone);
    if (phoneErr != null) errors['phone'] = phoneErr;

    final nameErr = IntakeValidators.validateCustomerName(state.customerName);
    if (nameErr != null) errors['name'] = nameErr;

    if (state.model.trim().isEmpty) {
      errors['model'] = 'Vehicle model is required';
    }
    if (!state.bodyTypeConfirmed) {
      errors['bodyType'] = 'Select the vehicle body type';
    }
    if (!state.fuelLevelObserved) {
      errors['fuelLevel'] = 'Select the observed fuel level';
    }

    final odoErr = IntakeValidators.validateOdometer(
      state.odometer,
      previousKm: state.lastRecordedKm,
    );
    if (odoErr != null) errors['odometer'] = odoErr;

    final vinErr = IntakeValidators.validateVin(state.vin);
    if (vinErr != null) errors['vin'] = vinErr;

    if (state.requestedWork.trim().isEmpty) {
      errors['requestedWork'] =
          'Please specify customer requested work / complaints';
    }

    final deliveryErr = IntakeValidators.validateExpectedDelivery(
      state.expectedDelivery,
    );
    if (deliveryErr != null) errors['expectedDelivery'] = deliveryErr;

    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  String? validateStep(int step) {
    final errors = <String, String>{};
    if (step == 0) {
      final registrationError = IntakeValidators.validateRegistration(
        state.registrationNumber,
      );
      if (registrationError != null) {
        errors['registration'] = registrationError;
      }
      if (state.make.trim().isEmpty) {
        errors['make'] = 'Select the vehicle make';
      }
      if (state.model.trim().isEmpty) {
        errors['model'] = 'Enter the vehicle model';
      }
      if (!state.bodyTypeConfirmed) {
        errors['bodyType'] = 'Select the vehicle body type';
      }
    } else if (step == 1) {
      final phoneError = IntakeValidators.validateMobile(state.customerPhone);
      if (phoneError != null) {
        errors['phone'] = phoneError;
      }
      final nameError = IntakeValidators.validateCustomerName(
        state.customerName,
      );
      if (nameError != null) {
        errors['name'] = nameError;
      }
    } else if (step == 2) {
      final odometerError = IntakeValidators.validateOdometer(
        state.odometer,
        previousKm: state.lastRecordedKm,
      );
      if (odometerError != null) {
        errors['odometer'] = odometerError;
      }
      if (!state.fuelLevelObserved) {
        errors['fuelLevel'] = 'Select the observed fuel level';
      }
    } else if (step == 3) {
      if (state.requestedWork.trim().isEmpty) {
        errors['requestedWork'] = 'Describe the work requested';
      }
      final deliveryError = IntakeValidators.validateExpectedDelivery(
        state.expectedDelivery,
      );
      if (deliveryError != null) {
        errors['expectedDelivery'] = deliveryError;
      }
    }
    state = state.copyWith(errors: errors, errorMessage: null);
    return errors.values.firstOrNull;
  }

  Future<bool> submitIntake() async {
    if (state.status == IntakeStatus.saving) return false;
    if (state.status == IntakeStatus.success) return true;
    if (!validateForm()) {
      return false;
    }

    final submittedForm = state;
    final fingerprint = _submissionFingerprint(submittedForm);
    if (_lastSubmissionFingerprint != null &&
        _lastSubmissionFingerprint != fingerprint) {
      _submissionRequestId = const Uuid().v4();
    }
    _lastSubmissionFingerprint = fingerprint;

    state = state.copyWith(status: IntakeStatus.saving, errorMessage: null);

    try {
      final jobCardId = await repository.submitIntake(
        submittedForm,
        requestId: _submissionRequestId,
      );
      state = state.copyWith(
        status: IntakeStatus.success,
        createdJobCardId: jobCardId,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: IntakeStatus.error,
        errorMessage: 'Failed to record intake: $e',
      );
      return false;
    }
  }

  String _submissionFingerprint(IntakeFormState form) => jsonEncode({
    'registration_number': form.registrationNumber.toUpperCase().replaceAll(
      RegExp(r'[\s-]'),
      '',
    ),
    'vin': form.vin.trim().isEmpty ? null : form.vin.trim().toUpperCase(),
    'make': form.make.trim(),
    'model': form.model.trim(),
    'body_type': form.bodyType.label.trim(),
    'customer_name': form.customerName.trim(),
    'customer_phone': IntakeValidators.normalizeMobile(form.customerPhone),
    'whatsapp_consent': form.whatsappConsent,
    'odometer_km': int.parse(form.odometer),
    'fuel_level_percent': form.fuelLevelPercent,
    'requested_work': form.requestedWork.trim(),
    'expected_delivery': form.expectedDelivery?.toUtc().toIso8601String(),
    'belongings': form.belongings.toMap(),
  });
}

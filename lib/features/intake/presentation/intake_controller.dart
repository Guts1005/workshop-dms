import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/intake_form_state.dart';
import '../services/intake_repository.dart';
import '../services/intake_validators.dart';

final intakeRepositoryProvider = Provider<IntakeRepository>((ref) {
  final repo = LocalIntakeRepository();
  repo.seedDemoData();
  return repo;
});

final intakeControllerProvider =
    StateNotifierProvider.autoDispose<IntakeController, IntakeFormState>((ref) {
  final repo = ref.watch(intakeRepositoryProvider);
  return IntakeController(repository: repo);
});

class IntakeController extends StateNotifier<IntakeFormState> {
  final IntakeRepository repository;

  IntakeController({required this.repository}) : super(const IntakeFormState());

  void onRegistrationChanged(String value) {
    state = state.copyWith(
      registrationNumber: value,
      errors: Map.from(state.errors)..remove('registration'),
    );

    // Auto-lookup if registration reaches valid structure
    final error = IntakeValidators.validateRegistration(value);
    if (error == null) {
      lookupVehicle(value);
    }
  }

  Future<void> lookupVehicle(String registration) async {
    state = state.copyWith(status: IntakeStatus.lookingUp);
    try {
      final vehicle = await repository.findVehicleByRegistration(registration);
      if (vehicle != null) {
        final history = await repository.getVehicleServiceHistory(vehicle.id);
        final lastKm = history.isNotEmpty ? history.first.odometerKm : vehicle.odometerKm;

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
      state = state.copyWith(
        status: IntakeStatus.idle,
        errorMessage: 'Failed to look up vehicle: $e',
      );
    }
  }

  void onPhoneChanged(String value) {
    state = state.copyWith(
      customerPhone: value,
      errors: Map.from(state.errors)..remove('phone'),
    );

    final normalized = IntakeValidators.normalizeMobile(value);
    if (normalized.length == 10) {
      lookupCustomer(normalized);
    }
  }

  Future<void> lookupCustomer(String phone) async {
    try {
      final customer = await repository.findCustomerByPhone(phone);
      if (customer != null) {
        state = state.copyWith(
          isExistingCustomer: true,
          customerName: customer.name,
          whatsappConsent: customer.consentWhatsapp,
        );
      } else {
        state = state.copyWith(isExistingCustomer: false);
      }
    } catch (_) {}
  }

  void onNameChanged(String value) {
    state = state.copyWith(
      customerName: value,
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
    state = state.copyWith(make: value);
  }

  void onModelChanged(String value) {
    state = state.copyWith(
      model: value,
      errors: Map.from(state.errors)..remove('model'),
    );
  }

  void onBodyTypeChanged(VehicleBodyType type) {
    state = state.copyWith(bodyType: type);
  }

  void onOdometerChanged(String value) {
    state = state.copyWith(
      odometer: value,
      errors: Map.from(state.errors)..remove('odometer'),
    );
  }

  void onFuelLevelChanged(int percent) {
    state = state.copyWith(fuelLevelPercent: percent);
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

    final regErr = IntakeValidators.validateRegistration(state.registrationNumber);
    if (regErr != null) errors['registration'] = regErr;

    final phoneErr = IntakeValidators.validateMobile(state.customerPhone);
    if (phoneErr != null) errors['phone'] = phoneErr;

    final nameErr = IntakeValidators.validateCustomerName(state.customerName);
    if (nameErr != null) errors['name'] = nameErr;

    if (state.model.trim().isEmpty) {
      errors['model'] = 'Vehicle model is required';
    }

    final odoErr = IntakeValidators.validateOdometer(
      state.odometer,
      previousKm: state.lastRecordedKm,
    );
    if (odoErr != null) errors['odometer'] = odoErr;

    final vinErr = IntakeValidators.validateVin(state.vin);
    if (vinErr != null) errors['vin'] = vinErr;

    if (state.requestedWork.trim().isEmpty) {
      errors['requestedWork'] = 'Please specify customer requested work / complaints';
    }

    final deliveryErr = IntakeValidators.validateExpectedDelivery(state.expectedDelivery);
    if (deliveryErr != null) errors['expectedDelivery'] = deliveryErr;

    state = state.copyWith(errors: errors);
    return errors.isEmpty;
  }

  Future<bool> submitIntake() async {
    if (!validateForm()) {
      return false;
    }

    state = state.copyWith(status: IntakeStatus.saving, errorMessage: null);

    try {
      final jobCardId = await repository.submitIntake(state);
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
}

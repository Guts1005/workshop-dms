import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/intake/models/intake_form_state.dart';
import 'package:workshop_dms/features/intake/presentation/intake_controller.dart';
import 'package:workshop_dms/features/intake/services/intake_repository.dart';

void main() {
  group('IntakeController Unit Tests', () {
    late LocalIntakeRepository repository;
    late IntakeController controller;

    setUp(() {
      repository = LocalIntakeRepository();
      repository.seedDemoData();
      controller = IntakeController(repository: repository);
    });

    test('Initial state is idle with default values', () {
      final state = controller.state;
      expect(state.status, IntakeStatus.idle);
      expect(state.make, 'MARUTI SUZUKI');
      expect(state.fuelLevelPercent, 50);
      expect(state.whatsappConsent, isTrue);
      expect(state.belongings.jackAndToolKit, isTrue);
      expect(state.belongings.spareTyre, isTrue);
      expect(state.isExistingVehicle, isFalse);
      expect(state.isExistingCustomer, isFalse);
    });

    test('Auto-looks up existing vehicle and populates history and lastRecordedKm', () async {
      controller.onRegistrationChanged('RJ27CA1024');
      await pumpEventQueue();

      final state = controller.state;
      expect(state.isExistingVehicle, isTrue);
      expect(state.make, 'MG MOTOR');
      expect(state.model, 'HECTOR PLUS SHARP PRO');
      expect(state.vin, 'MA3EWA12S00123456');
      expect(state.lastRecordedKm, 27227);
      expect(state.previousHistory.length, 3);
      expect(state.previousHistory.first.orderId, 'N330302623');
    });

    test('Auto-looks up existing customer by 10-digit phone', () async {
      controller.onPhoneChanged('+91 98290 12345');
      await pumpEventQueue();

      final state = controller.state;
      expect(state.isExistingCustomer, isTrue);
      expect(state.customerName, 'Aditya Mehta');
      expect(state.whatsappConsent, isTrue);
    });

    test('Validation fails when required fields are missing', () {
      final isValid = controller.validateForm();
      expect(isValid, isFalse);
      expect(controller.state.errors.containsKey('registration'), isTrue);
      expect(controller.state.errors.containsKey('phone'), isTrue);
      expect(controller.state.errors.containsKey('name'), isTrue);
      expect(controller.state.errors.containsKey('model'), isTrue);
      expect(controller.state.errors.containsKey('odometer'), isTrue);
    });

    test('Validation catches odometer rollback against previous recorded service', () async {
      controller.onRegistrationChanged('RJ27CA1024');
      await pumpEventQueue();

      // Hector was last recorded at 27,227 KM. Try entering 25,000 KM.
      controller.onOdometerChanged('25000');
      final isValid = controller.validateForm();

      expect(isValid, isFalse);
      expect(controller.state.errors['odometer'], contains('rollback'));
    });

    test('Successfully submits intake when all fields are valid', () async {
      controller.onRegistrationChanged('MH12DE1432');
      controller.onPhoneChanged('9876543210');
      controller.onNameChanged('Ramesh Patel');
      controller.onMakeChanged('HYUNDAI');
      controller.onModelChanged('CRETA SX');
      controller.onBodyTypeChanged(VehicleBodyType.sub4mSuv);
      controller.onOdometerChanged('15420');
      controller.onFuelLevelChanged(75);
      controller.onRequestedWorkChanged('1st Periodic Service, Brake pad inspection');
      controller.onExpectedDeliveryChanged(DateTime.now().add(const Duration(days: 1)));

      final success = await controller.submitIntake();

      expect(success, isTrue);
      expect(controller.state.status, IntakeStatus.success);
      expect(controller.state.createdJobCardId, isNotNull);
      expect(controller.state.errorMessage, isNull);
    });
  });
}

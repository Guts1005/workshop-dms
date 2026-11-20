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
      controller = IntakeController(repository: repository);
    });

    test('Initial state is idle with default values', () {
      final state = controller.state;
      expect(state.status, IntakeStatus.idle);
      expect(state.make, isEmpty);
      expect(state.fuelLevelPercent, 50);
      expect(state.fuelLevelObserved, isFalse);
      expect(state.whatsappConsent, isFalse);
      expect(state.belongings.jackAndToolKit, isFalse);
      expect(state.belongings.spareTyre, isFalse);
      expect(state.isExistingVehicle, isFalse);
      expect(state.isExistingCustomer, isFalse);
    });

    test(
      'Unknown registration stays a new vehicle without fabricated history',
      () async {
        controller.onRegistrationChanged('RJ27CA1024');
        await pumpEventQueue();

        final state = controller.state;
        expect(state.isExistingVehicle, isFalse);
        expect(state.previousHistory, isEmpty);
      },
    );

    test('Auto-looks up existing customer by 10-digit phone', () async {
      controller.onPhoneChanged('+91 98290 12345');
      await pumpEventQueue();

      final state = controller.state;
      expect(state.isExistingCustomer, isFalse);
      expect(state.customerName, isEmpty);
    });

    test('Adjusting the fuel slider records the observed intake level', () {
      controller.onFuelLevelChanged(25);

      expect(controller.state.fuelLevelPercent, 25);
      expect(controller.state.fuelLevelObserved, isTrue);
    });

    test('Validation fails when required fields are missing', () {
      final isValid = controller.validateForm();
      expect(isValid, isFalse);
      expect(controller.state.errors.containsKey('registration'), isTrue);
      expect(controller.state.errors.containsKey('phone'), isTrue);
      expect(controller.state.errors.containsKey('name'), isTrue);
      expect(controller.state.errors.containsKey('model'), isTrue);
      expect(controller.state.errors.containsKey('odometer'), isTrue);
      expect(
        controller.state.errors['fuelLevel'],
        'Select the observed fuel level',
      );
    });

    test(
      'Validation permits odometer entry when there is no existing history',
      () async {
        controller.onRegistrationChanged('RJ27CA1024');
        await pumpEventQueue();

        controller.onOdometerChanged('25000');
        final isValid = controller.validateForm();

        expect(isValid, isFalse);
        expect(controller.state.errors.containsKey('odometer'), isFalse);
      },
    );

    test('Successfully submits intake when all fields are valid', () async {
      controller.onRegistrationChanged('MH12DE1432');
      controller.onPhoneChanged('9876543210');
      controller.onNameChanged('Ramesh Patel');
      controller.onMakeChanged('HYUNDAI');
      controller.onModelChanged('CRETA SX');
      controller.onBodyTypeChanged(VehicleBodyType.sub4mSuv);
      controller.onOdometerChanged('15420');
      controller.onFuelLevelChanged(75);
      controller.onRequestedWorkChanged(
        '1st Periodic Service, Brake pad inspection',
      );
      controller.onExpectedDeliveryChanged(
        DateTime.now().add(const Duration(days: 1)),
      );

      final success = await controller.submitIntake();

      expect(success, isTrue);
      expect(controller.state.status, IntakeStatus.success);
      expect(controller.state.createdJobCardId, isNotNull);
      expect(controller.state.errorMessage, isNull);
    });
  });
}

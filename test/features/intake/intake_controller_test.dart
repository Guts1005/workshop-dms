import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/intake/models/intake_form_state.dart';
import 'package:workshop_dms/features/intake/presentation/intake_controller.dart';
import 'package:workshop_dms/features/intake/services/intake_repository.dart';

class _LostResponseIntakeRepository extends LocalIntakeRepository {
  final requestIds = <String>[];
  String? committedJobCardId;
  bool loseFirstResponse = true;

  @override
  Future<String> submitIntake(
    IntakeFormState formState, {
    required String requestId,
  }) async {
    requestIds.add(requestId);
    final result = await super.submitIntake(formState, requestId: requestId);
    if (loseFirstResponse) {
      loseFirstResponse = false;
      committedJobCardId = result;
      throw StateError('The response was lost after the server committed.');
    }
    return result;
  }
}

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

    test(
      'Changing a matched customer phone clears inherited consent',
      () async {
        await repository.submitIntake(
          IntakeFormState(
            registrationNumber: 'KA01AB1234',
            customerPhone: '9876543210',
            customerName: 'Consent Test Customer',
            make: 'TOYOTA',
            model: 'ETIOS',
            odometer: '25000',
            requestedWork: 'Inspect brakes',
            expectedDelivery: DateTime(2026, 11, 26),
            whatsappConsent: true,
          ),
          requestId: 'seed-consent-customer',
        );

        controller.onPhoneChanged('9876543210');
        await pumpEventQueue();
        expect(controller.state.isExistingCustomer, isTrue);
        expect(controller.state.whatsappConsent, isTrue);

        controller.onPhoneChanged('9876543211');
        expect(controller.state.whatsappConsent, isFalse);
        await pumpEventQueue();
        expect(controller.state.isExistingCustomer, isFalse);
        expect(controller.state.whatsappConsent, isFalse);
      },
    );

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

    test(
      'Local intake retry rejects a reused ID with edited details',
      () async {
        final intake = IntakeFormState(
          registrationNumber: 'KA01AB1234',
          customerPhone: '9876543210',
          customerName: 'Asha Rao',
          make: 'TOYOTA',
          model: 'ETIOS',
          odometer: '25000',
          requestedWork: 'Inspect brakes',
          expectedDelivery: DateTime(2026, 11, 22),
        );

        final jobId = await repository.submitIntake(
          intake,
          requestId: 'same-request',
        );
        expect(
          await repository.submitIntake(intake, requestId: 'same-request'),
          jobId,
        );
        await expectLater(
          repository.submitIntake(
            intake.copyWith(requestedWork: 'Replace brake pads'),
            requestId: 'same-request',
          ),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'Retries an intake with the same request ID after a lost response',
      () async {
        final retryRepository = _LostResponseIntakeRepository();
        final retryController = IntakeController(repository: retryRepository);
        retryController.onRegistrationChanged('MH12DE1432');
        retryController.onPhoneChanged('9876543210');
        retryController.onNameChanged('Ramesh Patel');
        retryController.onMakeChanged('HYUNDAI');
        retryController.onModelChanged('CRETA SX');
        retryController.onBodyTypeChanged(VehicleBodyType.sub4mSuv);
        retryController.onOdometerChanged('15420');
        retryController.onFuelLevelChanged(75);
        retryController.onRequestedWorkChanged('First service');
        retryController.onExpectedDeliveryChanged(
          DateTime.now().add(const Duration(days: 1)),
        );

        expect(await retryController.submitIntake(), isFalse);
        expect(await retryController.submitIntake(), isTrue);
        expect(retryRepository.requestIds, hasLength(2));
        expect(
          retryRepository.requestIds.first,
          retryRepository.requestIds.last,
        );
        expect(
          retryController.state.createdJobCardId,
          retryRepository.committedJobCardId,
        );
        expect(await retryController.submitIntake(), isTrue);
        expect(retryRepository.requestIds, hasLength(2));
      },
    );

    test(
      'Edited intake starts a new request after a failed submission',
      () async {
        final retryRepository = _LostResponseIntakeRepository();
        final retryController = IntakeController(repository: retryRepository);
        retryController.onRegistrationChanged('MH12DE1432');
        retryController.onPhoneChanged('9876543210');
        retryController.onNameChanged('Ramesh Patel');
        retryController.onMakeChanged('HYUNDAI');
        retryController.onModelChanged('CRETA SX');
        retryController.onBodyTypeChanged(VehicleBodyType.sub4mSuv);
        retryController.onOdometerChanged('15420');
        retryController.onFuelLevelChanged(75);
        retryController.onRequestedWorkChanged('First service');
        retryController.onExpectedDeliveryChanged(
          DateTime.now().add(const Duration(days: 1)),
        );

        expect(await retryController.submitIntake(), isFalse);
        retryController.onRequestedWorkChanged('First service and brake check');

        expect(await retryController.submitIntake(), isTrue);
        expect(retryRepository.requestIds, hasLength(2));
        expect(
          retryRepository.requestIds.last,
          isNot(retryRepository.requestIds.first),
        );
      },
    );
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/intake/presentation/intake_controller.dart';
import 'package:workshop_dms/features/intake/presentation/intake_screen.dart';
import 'package:workshop_dms/features/intake/models/intake_form_state.dart';
import 'package:workshop_dms/features/intake/services/intake_repository.dart';

void main() {
  Widget createIntakeScreen({LocalIntakeRepository? customRepo}) {
    final repo = customRepo ?? LocalIntakeRepository();

    return ProviderScope(
      overrides: [intakeRepositoryProvider.overrideWithValue(repo)],
      child: const MaterialApp(home: IntakeScreen()),
    );
  }

  group('IntakeScreen Widget Tests', () {
    testWidgets('Renders all intake sections and input fields', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createIntakeScreen());
      await tester.pumpAndSettle();

      expect(find.text('NEW APPLICATION: VEHICLE CHECK-IN'), findsOneWidget);
      expect(find.byKey(const Key('input_registration')), findsOneWidget);
      expect(find.byKey(const Key('input_phone')), findsOneWidget);
      expect(find.byKey(const Key('input_name')), findsOneWidget);
      expect(find.byKey(const Key('input_odometer')), findsOneWidget);
      expect(find.byKey(const Key('input_requested_work')), findsOneWidget);
      expect(
        find.text('GENERATE INTAKE & PROCEED TO BAY CHECK-IN'),
        findsOneWidget,
      );
    });

    testWidgets('Displays validation errors when submitting blank form', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createIntakeScreen());
      await tester.pumpAndSettle();

      // Tap submit button without filling fields
      final submitBtn = find.text('GENERATE INTAKE & PROCEED TO BAY CHECK-IN');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Registration number is required'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Customer name is required'), findsOneWidget);
      expect(find.text('Vehicle model is required'), findsOneWidget);
      expect(find.text('Odometer reading is required'), findsOneWidget);
    });

    testWidgets(
      'Unknown vehicle does not show invented customer or service records',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createIntakeScreen());
        await tester.pumpAndSettle();

        // Enter known registration plate
        await tester.enterText(
          find.byKey(const Key('input_registration')),
          'RJ27CA1024',
        );
        await tester.pumpAndSettle();

        expect(find.text('RECOGNISED IN SYSTEM'), findsNothing);
        expect(find.textContaining('PREVIOUS SERVICE RECORDS'), findsNothing);
        expect(find.textContaining('ORDER #'), findsNothing);
      },
    );

    testWidgets(
      'Completes intake and displays Job Card confirmation on valid submission',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final repo = LocalIntakeRepository();
        final container = ProviderContainer(
          overrides: [intakeRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(home: IntakeScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Enter valid fields
        await tester.enterText(
          find.byKey(const Key('input_registration')),
          'DL01AB1234',
        );
        await tester.enterText(
          find.byKey(const Key('input_model')),
          'SWIFT VXI',
        );
        await tester.enterText(
          find.byKey(const Key('input_phone')),
          '9876543210',
        );
        await tester.enterText(
          find.byKey(const Key('input_name')),
          'Vikram Singhal',
        );
        await tester.enterText(
          find.byKey(const Key('input_odometer')),
          '35000',
        );
        await tester.enterText(
          find.byKey(const Key('input_requested_work')),
          'Oil filter replacement & general service',
        );
        container
            .read(intakeControllerProvider.notifier)
            .onMakeChanged('MARUTI SUZUKI');
        container
            .read(intakeControllerProvider.notifier)
            .onBodyTypeChanged(VehicleBodyType.hatchback);
        container
            .read(intakeControllerProvider.notifier)
            .onFuelLevelChanged(50);
        container
            .read(intakeControllerProvider.notifier)
            .onFuelLevelConfirmationChanged(true);

        // Pick expected delivery via controller
        container
            .read(intakeControllerProvider.notifier)
            .onExpectedDeliveryChanged(
              DateTime.now().add(const Duration(days: 2)),
            );
        await tester.pumpAndSettle();

        // Submit
        final submitBtn = find.text(
          'GENERATE INTAKE & PROCEED TO BAY CHECK-IN',
        );
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Check success screen
        expect(find.text('VEHICLE INTAKE LOGGED SUCCESSFULLY'), findsOneWidget);
        expect(find.text('JOB CARD CREATED'), findsOneWidget);
        expect(find.text('CONTINUE CHECK-IN'), findsOneWidget);
      },
    );
  });
}

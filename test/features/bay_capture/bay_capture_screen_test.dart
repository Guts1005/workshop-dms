import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_controller.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_models.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_screen.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_repository.dart';

void main() {
  group('BayCaptureScreen Widget Tests', () {
    testWidgets(
      'Renders Page 2 header, 6-slot status, and locked check-in gate button',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bayCaptureRepositoryProvider.overrideWithValue(
                LocalBayCaptureRepository(),
              ),
            ],
            child: const MaterialApp(
              home: BayCaptureScreen(
                jobCardId: 'JC-1001',
                registrationNumber: 'RJ27CA1024',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Page 2 Header & Telemetry
        expect(find.text('PHOTO INSPECTION'), findsOneWidget);
        expect(find.textContaining('RJ27CA1024'), findsOneWidget);
        expect(find.text('0/6 MANDATORY'), findsOneWidget);

        // Verify Shot Slots
        expect(find.text('FRONT-LEFT 45° CORNER (HERO)'), findsWidgets);
        expect(find.text('FRONT-RIGHT 45° CORNER'), findsWidgets);
        expect(find.text('REAR-LEFT 45° CORNER'), findsWidgets);
        expect(find.text('REAR-RIGHT 45° CORNER'), findsWidgets);
        expect(find.text('NUMBER PLATE CLOSE-UP'), findsWidgets);
        expect(find.text('ODOMETER / CLUSTER'), findsWidgets);

        // Mandatory evidence keeps the next action visibly gated.
        expect(find.text('CAPTURE 6 REQUIRED PHOTOS'), findsOneWidget);
        expect(find.text('MANAGER OVERRIDE'), findsOneWidget);
      },
    );

    testWidgets('Check-in layout fits a phone viewport without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bayCaptureRepositoryProvider.overrideWithValue(
              LocalBayCaptureRepository(),
            ),
          ],
          child: const MaterialApp(
            home: BayCaptureScreen(
              jobCardId: 'JC-MOBILE-LAYOUT',
              registrationNumber: 'RJ27CA1024',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/6 MANDATORY'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Recording a shot capture updates progress counter and slot status',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));

        final container = ProviderContainer(
          overrides: [
            bayCaptureRepositoryProvider.overrideWithValue(
              LocalBayCaptureRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: BayCaptureScreen(
                jobCardId: 'JC-1002',
                registrationNumber: 'RJ27CA1024',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('0/6 MANDATORY'), findsOneWidget);

        // Record a real shot capture into the controller
        await container
            .read(bayCaptureControllerProvider.notifier)
            .recordCapturedPhoto(
              shotType: CheckInShotType.frontLeft45,
              filePath: '/sandbox/real_capture_fl45.jpg',
              sha256Hash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
              fileSizeBytes: 24500,
            );
        await tester.pumpAndSettle();

        // Progress counter incremented to 1/6
        expect(find.text('1/6 MANDATORY'), findsOneWidget);
        expect(find.text('CAPTURE 5 REQUIRED PHOTOS'), findsOneWidget);
      },
    );

    testWidgets(
      'Manager Override dialog opens, validates fields, and unlocks gate',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              bayCaptureRepositoryProvider.overrideWithValue(
                LocalBayCaptureRepository(),
              ),
            ],
            child: const MaterialApp(
              home: BayCaptureScreen(
                jobCardId: 'JC-1003',
                registrationNumber: 'RJ27CA1024',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap MANAGER OVERRIDE button
        await tester.tap(find.text('MANAGER OVERRIDE'));
        await tester.pumpAndSettle();

        // Verify dialog is visible
        expect(find.text('MANAGER OVERRIDE AUTHORIZATION'), findsOneWidget);
        expect(
          find.textContaining('MISSING MANDATORY SHOTS (6)'),
          findsOneWidget,
        );

        // Try authorizing without entering fields
        await tester.tap(find.text('AUTHORIZE OVERRIDE'));
        await tester.pumpAndSettle();

        // Error shown
        expect(
          find.textContaining(
            'Manager name or ID must be at least 2 characters',
          ),
          findsOneWidget,
        );

        // Enter valid manager details
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'Mahesh Patel');
        await tester.enterText(
          textFields.at(1),
          'Front-end completely burned in transit fire',
        );
        await tester.pumpAndSettle();

        // Authorize
        await tester.tap(find.text('AUTHORIZE OVERRIDE'));
        await tester.pumpAndSettle();

        // Verify dialog closed and override chip appears
        expect(find.text('MANAGER OVERRIDE AUTHORIZATION'), findsNothing);
        expect(find.text('OVERRIDE: MAHESH PATEL'), findsOneWidget);

        // Check that gate button is now UNLOCKED!
        expect(find.text('CONTINUE TO CONDITION REPORT'), findsOneWidget);
      },
    );
  });
}

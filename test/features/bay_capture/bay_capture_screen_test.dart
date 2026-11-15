import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_screen.dart';

void main() {
  group('BayCaptureScreen Widget Tests', () {
    testWidgets('Renders Page 2 header, 6-slot status, and locked check-in gate button', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BayCaptureScreen(
              jobCardId: 'JC-1001',
              registrationNumber: 'RJ27CA1024',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Page 2 Header & Telemetry
      expect(find.text('PAGE 2: BAY CHECK-IN CAPTURE'), findsOneWidget);
      expect(find.textContaining('RJ27CA1024'), findsOneWidget);
      expect(find.text('0/6 MANDATORY'), findsOneWidget);

      // Verify Shot Slots
      expect(find.text('FRONT-LEFT 45° CORNER (HERO)'), findsWidgets);
      expect(find.text('FRONT-RIGHT 45° CORNER'), findsWidgets);
      expect(find.text('REAR-LEFT 45° CORNER'), findsWidgets);
      expect(find.text('REAR-RIGHT 45° CORNER'), findsWidgets);
      expect(find.text('NUMBER PLATE CLOSE-UP'), findsWidgets);
      expect(find.text('ODOMETER / CLUSTER'), findsWidgets);

      // Verify Gated Locked Bottom Action
      expect(find.text('LOCKED: 0/6 SHOTS REQUIRED TO OPEN JOB CARD'), findsOneWidget);
      expect(find.text('MANAGER OVERRIDE'), findsOneWidget);
    });

    testWidgets('Simulating a shot capture increments progress counter', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BayCaptureScreen(
              jobCardId: 'JC-1002',
              registrationNumber: 'RJ27CA1024',
              initialSimulationMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/6 MANDATORY'), findsOneWidget);

      // Tap CAPTURE SHOT NOW
      final captureBtn = find.text('CAPTURE SHOT NOW');
      expect(captureBtn, findsOneWidget);
      await tester.tap(captureBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Progress counter incremented to 1/6
      expect(find.text('1/6 MANDATORY'), findsOneWidget);
      expect(find.text('LOCKED: 1/6 SHOTS REQUIRED TO OPEN JOB CARD'), findsOneWidget);
    });

    testWidgets('Manager Override dialog opens, validates fields, and unlocks gate', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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
      expect(find.textContaining('MISSING MANDATORY SHOTS (6)'), findsOneWidget);

      // Try authorizing without entering fields
      await tester.tap(find.text('AUTHORIZE OVERRIDE'));
      await tester.pumpAndSettle();

      // Error shown
      expect(find.textContaining('Manager name or ID must be at least 2 characters'), findsOneWidget);

      // Enter valid manager details
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Mahesh Patel');
      await tester.enterText(textFields.at(1), 'Front-end completely burned in transit fire');
      await tester.pumpAndSettle();

      // Authorize
      await tester.tap(find.text('AUTHORIZE OVERRIDE'));
      await tester.pumpAndSettle();

      // Verify dialog closed and override chip appears
      expect(find.text('MANAGER OVERRIDE AUTHORIZATION'), findsNothing);
      expect(find.text('OVERRIDE: MAHESH PATEL'), findsOneWidget);

      // Check that gate button is now UNLOCKED!
      expect(find.text('FINALIZE CHECK-IN & OPEN 360° CONDITION MAP'), findsOneWidget);
    });
  });
}

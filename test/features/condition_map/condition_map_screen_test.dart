import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/condition_map/condition_map_controller.dart';
import 'package:workshop_dms/features/condition_map/condition_map_models.dart';
import 'package:workshop_dms/features/condition_map/condition_map_screen.dart';

void main() {
  group('ConditionMapScreen Widget Tests', () {
    testWidgets('Renders Page 3 header, 5 view tabs, and pre-work sign-off button', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-101',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Telemetry
      expect(find.text('PAGE 3: 360° CONDITION MAP & PRE-WORK SIGN-OFF'), findsOneWidget);
      expect(find.textContaining('DL01AB9988'), findsOneWidget);
      expect(find.text('0 DEFECTS LOGGED'), findsOneWidget);

      // Verify View Tabs
      expect(find.text('LEFT PROFILE'), findsOneWidget);
      expect(find.text('RIGHT PROFILE'), findsOneWidget);
      expect(find.text('FRONT NOSE'), findsOneWidget);
      expect(find.text('REAR TAIL'), findsOneWidget);
      expect(find.text('ROOF / TOP'), findsOneWidget);

      // Verify Bottom Sign-Off Trigger
      expect(find.text('INITIATE CUSTOMER PRE-WORK SIGN-OFF (0 DEFECTS LOGGED)'), findsOneWidget);
    });

    testWidgets('Adding pins updates defect ledger and canvas pin badges', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-102',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Programmatically add a pin to the controller
      await container.read(conditionMapControllerProvider.notifier).addPin(
        view: ConditionViewDirection.sideLeft,
        nx: 0.45,
        ny: 0.50,
        type: DefectType.dent,
        severity: DefectSeverity.severe,
        note: 'Left door dent',
      );
      await tester.pumpAndSettle();

      // Verify pin #1 appears on canvas and in ledger
      expect(find.text('1'), findsWidgets);
      expect(find.text('1 DEFECTS LOGGED'), findsOneWidget);
      expect(find.text('DENT (LEFT PROFILE)'), findsOneWidget);
      expect(find.text('L3 - SEVERE'), findsWidgets);
    });

    testWidgets('Pre-Work Sign-Off Modal validates fields and locks condition map on confirmation', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-103',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Add 1 minor scratch
      await container.read(conditionMapControllerProvider.notifier).addPin(
        view: ConditionViewDirection.sideLeft,
        nx: 0.2,
        ny: 0.5,
        type: DefectType.deepScratch,
        severity: DefectSeverity.minor,
      );
      await tester.pumpAndSettle();

      // Tap Initiate Sign-Off Button
      await tester.tap(find.text('INITIATE CUSTOMER PRE-WORK SIGN-OFF (1 DEFECTS LOGGED)'));
      await tester.pumpAndSettle();

      // Verify modal is open
      expect(find.text('CUSTOMER PRE-WORK CONDITION SIGN-OFF'), findsOneWidget);
      expect(find.text('SWIPE TO CONFIRM PRE-WORK SIGN-OFF'), findsOneWidget);

      // Perform swipe on the slider thumb
      final thumbFinder = find.byIcon(Icons.arrow_forward);
      expect(thumbFinder, findsOneWidget);

      await tester.drag(thumbFinder, const Offset(600.0, 0.0));
      await tester.pumpAndSettle();

      // Modal closed, screen now locked
      expect(find.text('CUSTOMER PRE-WORK CONDITION SIGN-OFF'), findsNothing);
      expect(find.text('PRE-WORK SIGNED OFF'), findsOneWidget);
      expect(find.textContaining('SIGNED OFF BY ROHAN SHARMA'), findsOneWidget);
      expect(find.text('ADVANCE TO MECHANICAL INSPECTION'), findsOneWidget);
    });
  });
}

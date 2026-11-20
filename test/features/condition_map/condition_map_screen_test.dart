import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/condition_map/condition_map_controller.dart';
import 'package:workshop_dms/features/condition_map/condition_map_models.dart';
import 'package:workshop_dms/features/condition_map/condition_map_screen.dart';
import 'package:workshop_dms/features/condition_map/condition_map_repository.dart';

void main() {
  group('ConditionMapScreen Widget Tests', () {
    testWidgets('Renders vehicle condition areas and sign-off progress', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-101',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Vehicle condition'), findsOneWidget);
      expect(find.text('Exterior check'), findsOneWidget);
      expect(find.textContaining('DL01AB9988'), findsOneWidget);
      expect(find.text('0/5 checked'), findsOneWidget);

      // Verify View Tabs
      expect(find.text('Left side'), findsOneWidget);
      expect(find.text('Right side'), findsOneWidget);
      expect(find.text('Front'), findsOneWidget);
      expect(find.text('Rear'), findsOneWidget);

      expect(find.text('Check 5 more areas'), findsOneWidget);
    });

    testWidgets('Adding pins updates defect ledger and canvas pin badges', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));

      final container = ProviderContainer(
        overrides: [
          conditionMapRepositoryProvider.overrideWithValue(
            LocalConditionMapRepository(),
          ),
        ],
      );
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
      await container
          .read(conditionMapControllerProvider.notifier)
          .addPin(
            view: ConditionViewDirection.sideLeft,
            nx: 0.45,
            ny: 0.50,
            type: DefectType.dent,
            severity: DefectSeverity.severe,
            note: 'Left door dent',
          );
      await tester.pumpAndSettle();

      expect(container.read(conditionMapControllerProvider).totalPinCount, 1);
      expect(
        container.read(conditionMapControllerProvider).pins.single.note,
        'Left door dent',
      );
    });

    testWidgets('Finding form offers an optional photo attachment', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
          child: const MaterialApp(
            home: ConditionMapScreen(
              jobCardId: 'JC-MAP-PHOTO',
              registrationNumber: 'DL01AB9988',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add finding').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Finding:'), findsOneWidget);
      expect(find.text('Add a photo (optional)'), findsOneWidget);
    });

    testWidgets(
      'Pre-Work Sign-Off Modal validates fields and locks condition map on confirmation',
      (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(1280, 900));

        final container = ProviderContainer(
          overrides: [
            conditionMapRepositoryProvider.overrideWithValue(
              LocalConditionMapRepository(),
            ),
          ],
        );
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
        await container
            .read(conditionMapControllerProvider.notifier)
            .addPin(
              view: ConditionViewDirection.sideLeft,
              nx: 0.2,
              ny: 0.5,
              type: DefectType.deepScratch,
              severity: DefectSeverity.minor,
            );
        for (final view in ConditionViewDirection.values) {
          await container
              .read(conditionMapControllerProvider.notifier)
              .markViewReviewed(view);
        }
        await tester.pumpAndSettle();

        await tester.tap(find.text('Review and save report'));
        await tester.pumpAndSettle();

        expect(find.text('Save condition report'), findsOneWidget);
        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'Rohan Sharma');
        await tester.enterText(fields.at(1), '9876543210');
        await tester.enterText(fields.at(2), 'Manish Verma');
        await tester.tap(find.text('Customer reviewed this report'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Confirm and save'));
        await tester.pumpAndSettle();
        expect(find.text('Save condition report'), findsNothing);
        expect(find.textContaining('Report saved'), findsOneWidget);
      },
    );
  });
}

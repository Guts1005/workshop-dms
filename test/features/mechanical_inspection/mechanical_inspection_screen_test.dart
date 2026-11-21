import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_controller.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_models.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_repository.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_screen.dart';

class _ScreenInspectionRepository implements MechanicalInspectionRepository {
  @override
  Future<int> getIntakeOdometer(String jobCardId) async => 24000;

  @override
  Future<MechanicalInspectionRecord?> getInspection(String jobCardId) async =>
      null;

  @override
  Future<void> saveInspection({
    required String jobCardId,
    required MechanicalInspectionRecord inspection,
  }) async {}
}

class _FlakyScreenInspectionRepository extends _ScreenInspectionRepository {
  bool failFirstLoad = true;

  @override
  Future<int> getIntakeOdometer(String jobCardId) async {
    if (failFirstLoad) {
      failFirstLoad = false;
      throw StateError('Temporary network failure');
    }
    return super.getIntakeOdometer(jobCardId);
  }
}

void main() {
  testWidgets('shows inspection measurements and vehicle context', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mechanicalInspectionRepositoryProvider.overrideWithValue(
            _ScreenInspectionRepository(),
          ),
        ],
        child: const MaterialApp(
          home: MechanicalInspectionScreen(
            jobCardId: 'job-1',
            registrationNumber: 'KA01AB1234',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('KA01AB1234'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Battery measured CCA'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Mechanical inspection'), findsOneWidget);
    expect(find.text('Battery measured CCA'), findsOneWidget);
    expect(find.text('Save inspection and continue'), findsOneWidget);
  });

  testWidgets(
    'offers retry and hides inspection form if application load fails',
    (tester) async {
      final repository = _FlakyScreenInspectionRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mechanicalInspectionRepositoryProvider.overrideWithValue(
              repository,
            ),
          ],
          child: const MaterialApp(
            home: MechanicalInspectionScreen(
              jobCardId: 'job-1',
              registrationNumber: 'KA01AB1234',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Could not load this application'), findsOneWidget);
      expect(find.text('Inspector name'), findsNothing);
      expect(find.text('Retry loading'), findsOneWidget);

      await tester.tap(find.text('Retry loading'));
      await tester.pumpAndSettle();

      expect(find.text('Could not load this application'), findsNothing);
      expect(find.text('Inspector name'), findsOneWidget);
      expect(
        find.text('Must be at least 24000 km from check-in'),
        findsOneWidget,
      );
    },
  );
}

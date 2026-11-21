import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/supabase/workshop_database.dart';

void main() {
  group('next application action for the intake workflow', () {
    test('requires bay photos before the condition report', () {
      final intake = nextApplicationAction(
        jobStatus: 'RECEIVED',
        mandatoryPhotoCount: 0,
        hasManagerOverride: false,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );
      final checkedIn = nextApplicationAction(
        jobStatus: 'INSPECTION_PENDING',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );

      expect(intake.route, '/bay-capture');
      expect(intake.label, 'Open photo check-in');
      expect(checkedIn.route, '/condition-map');
      expect(checkedIn.label, 'Open vehicle condition');
    });

    test('allows condition report after the authorized photo override', () {
      final action = nextApplicationAction(
        jobStatus: 'RECEIVED',
        mandatoryPhotoCount: 2,
        hasManagerOverride: true,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );

      expect(action.route, '/condition-map');
    });

    test('moves to mechanical inspection only after condition sign-off', () {
      final action = nextApplicationAction(
        jobStatus: 'INSPECTION_PENDING',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: false,
      );

      expect(action.route, '/mechanical-inspection');
      expect(action.label, 'Record mechanical inspection');
    });
  });
}

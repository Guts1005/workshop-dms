import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/supabase/workshop_database.dart';

void main() {
  group('nextApplicationAction', () {
    test('sends incomplete check-in to photo capture', () {
      final action = nextApplicationAction(
        mandatoryPhotoCount: 3,
        hasManagerOverride: false,
        hasConditionReport: false,
      );

      expect(action.route, '/bay-capture');
      expect(action.label, 'Open photo check-in');
    });

    test('opens condition report once mandatory photo gate is satisfied', () {
      final action = nextApplicationAction(
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: false,
      );

      expect(action.route, '/condition-map');
    });

    test('manager override allows condition report with missing photos', () {
      final action = nextApplicationAction(
        mandatoryPhotoCount: 2,
        hasManagerOverride: true,
        hasConditionReport: false,
      );

      expect(action.route, '/condition-map');
    });

    test('opens job card after signed condition report', () {
      final action = nextApplicationAction(
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
      );

      expect(action.route, '/job-card');
      expect(action.label, 'Open job card and estimate');
    });
  });
}

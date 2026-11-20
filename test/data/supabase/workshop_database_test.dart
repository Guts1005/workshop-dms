import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/supabase/workshop_database.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_models.dart';

void main() {
  group('nextApplicationAction', () {
    test('sends incomplete check-in to photo capture', () {
      final action = nextApplicationAction(
        jobStatus: 'RECEIVED',
        mandatoryPhotoCount: 3,
        hasManagerOverride: false,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );

      expect(action.route, '/bay-capture');
      expect(action.label, 'Open photo check-in');
    });

    test('opens condition report once mandatory photo gate is satisfied', () {
      final action = nextApplicationAction(
        jobStatus: 'RECEIVED',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );

      expect(action.route, '/condition-map');
    });

    test('manager override allows condition report with missing photos', () {
      final action = nextApplicationAction(
        jobStatus: 'RECEIVED',
        mandatoryPhotoCount: 2,
        hasManagerOverride: true,
        hasConditionReport: false,
        hasMechanicalInspection: false,
      );

      expect(action.route, '/condition-map');
    });

    test('opens inspection after condition report is signed', () {
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

    test('opens estimate after inspection is saved', () {
      final action = nextApplicationAction(
        jobStatus: 'INSPECTION_PENDING',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/job-card');
      expect(action.label, 'Open job card and estimate');
    });

    test('routes sent estimates to customer response entry', () {
      final action = nextApplicationAction(
        jobStatus: 'ESTIMATE_SENT',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/whatsapp-dispatch');
      expect(action.label, 'Record customer response');
    });

    test('routes declined estimates to revision', () {
      final action = nextApplicationAction(
        jobStatus: 'ESTIMATE_REVISION_REQUIRED',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/job-card');
      expect(action.label, 'Revise estimate');
    });

    test('routes approved work to technician progress updates', () {
      final action = nextApplicationAction(
        jobStatus: 'WORK_IN_PROGRESS',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/work-in-progress');
      expect(action.label, 'Update work progress');
    });

    test('routes passed QC to invoice preparation', () {
      final action = nextApplicationAction(
        jobStatus: 'QC_PASSED',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/gst-invoicing');
      expect(action.label, 'Prepare invoice');
    });

    test('routes issued invoices to payment and delivery gate', () {
      final action = nextApplicationAction(
        jobStatus: 'READY_FOR_PICKUP',
        mandatoryPhotoCount: 6,
        hasManagerOverride: false,
        hasConditionReport: true,
        hasMechanicalInspection: true,
      );

      expect(action.route, '/payment-gate');
      expect(action.label, 'Record payment and delivery');
    });
  });

  group('validateMechanicalInspection', () {
    test('requires each item to be measured or marked not applicable', () {
      final error = validateMechanicalInspection(
        inspectorName: 'Tech One',
        odometerKm: 1001,
        minimumOdometerKm: 1000,
        measurementTexts: {'front_brake_pad_mm': '5'},
        notApplicable: const {},
      );

      expect(error, contains('rear brake pad thickness'));
    });

    test(
      'accepts a complete record with measured and not applicable items',
      () {
        final texts = {
          for (final spec in mechanicalMeasurementSpecs) spec.id: '5.5',
        };
        final notApplicable = {mechanicalMeasurementSpecs.last.id};

        final error = validateMechanicalInspection(
          inspectorName: 'Tech One',
          odometerKm: 1000,
          minimumOdometerKm: 1000,
          measurementTexts: texts,
          notApplicable: notApplicable,
        );

        expect(error, isNull);
      },
    );

    test('rejects an odometer reading below check-in', () {
      final texts = {
        for (final spec in mechanicalMeasurementSpecs) spec.id: '5.5',
      };

      final error = validateMechanicalInspection(
        inspectorName: 'Tech One',
        odometerKm: 999,
        minimumOdometerKm: 1000,
        measurementTexts: texts,
        notApplicable: const {},
      );

      expect(error, contains('at least 1000 km'));
    });

    test('rejects measurement values outside the field range', () {
      final texts = {
        for (final spec in mechanicalMeasurementSpecs) spec.id: '5.5',
      }..['battery_cca'] = '5001';

      final error = validateMechanicalInspection(
        inspectorName: 'Tech One',
        odometerKm: 1000,
        minimumOdometerKm: 1000,
        measurementTexts: texts,
        notApplicable: const {},
      );

      expect(error, contains('no greater than 5000 A'));
    });
  });
}

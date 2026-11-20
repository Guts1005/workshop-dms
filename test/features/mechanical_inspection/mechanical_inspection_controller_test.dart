import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_controller.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_models.dart';
import 'package:workshop_dms/features/mechanical_inspection/mechanical_inspection_repository.dart';

class _MemoryInspectionRepository implements MechanicalInspectionRepository {
  MechanicalInspectionRecord? saved;

  @override
  Future<int> getIntakeOdometer(String jobCardId) async => 35000;

  @override
  Future<MechanicalInspectionRecord?> getInspection(String jobCardId) async =>
      saved;

  @override
  Future<void> saveInspection({
    required String jobCardId,
    required MechanicalInspectionRecord inspection,
  }) async {
    saved = inspection;
  }
}

void main() {
  group('MechanicalInspectionController', () {
    late _MemoryInspectionRepository repository;
    late MechanicalInspectionController controller;

    setUp(() {
      repository = _MemoryInspectionRepository();
      controller = MechanicalInspectionController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test(
      'loads current record and allows completing a measured checklist',
      () async {
        await controller.initSession(
          jobCardId: 'job-1',
          registrationNumber: 'KA01AB1234',
        );
        controller.setInspectorName('Workshop Technician');
        controller.setOdometer('35010');
        for (final spec in mechanicalMeasurementSpecs) {
          if (spec.id == 'battery_cca') {
            controller.setNotApplicable(spec.id, true);
          } else {
            controller.setMeasurement(spec.id, '4.5');
          }
        }

        final saved = await controller.save();

        expect(saved, isTrue);
        expect(repository.saved?.odometerKm, 35010);
        expect(repository.saved?.measurements['battery_voltage_v'], 4.5);
        expect(repository.saved?.notApplicable, contains('battery_cca'));
        expect(controller.state.saved, isTrue);
      },
    );

    test('does not save an incomplete checklist', () async {
      await controller.initSession(
        jobCardId: 'job-1',
        registrationNumber: 'KA01AB1234',
      );
      controller.setInspectorName('Workshop Technician');
      controller.setOdometer('35010');

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(repository.saved, isNull);
      expect(controller.state.errorMessage, contains('front brake pad'));
    });

    test('restores persisted values for corrections', () async {
      repository.saved = MechanicalInspectionRecord(
        inspectorName: 'Workshop Technician',
        odometerKm: 35015,
        measurements: const {'front_brake_pad_mm': 6},
        notApplicable: {
          'rear_brake_pad_mm',
          'minimum_tyre_tread_mm',
          'battery_voltage_v',
          'battery_cca',
        },
        notes: 'Normal wear',
        completedAt: DateTime.utc(2026, 11, 20),
      );

      await controller.initSession(
        jobCardId: 'job-1',
        registrationNumber: 'KA01AB1234',
      );

      expect(controller.state.saved, isTrue);
      expect(controller.state.measurementTexts['front_brake_pad_mm'], '6.0');
      expect(controller.state.notes, 'Normal wear');
    });
  });
}

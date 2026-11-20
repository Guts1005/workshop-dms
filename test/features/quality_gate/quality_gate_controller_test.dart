import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/quality_gate/quality_gate_controller.dart';
import 'package:workshop_dms/features/quality_gate/quality_gate_models.dart';
import 'package:workshop_dms/features/quality_gate/quality_gate_repository.dart';

class _MemoryQualityRepository implements QualityGateRepository {
  String? savedResult;

  @override
  Future<QualityGateWorkspace> load(String jobCardId) async =>
      QualityGateWorkspace(
        jobCardId: jobCardId,
        registrationNumber: 'KA01AB1234',
      );

  @override
  Future<String> save({
    required String jobCardId,
    required String inspectorName,
    required bool workCompleted,
    required Map<String, bool> checks,
    required RoadTestResult roadTestResult,
    required String roadTestNote,
    required String notes,
  }) async {
    savedResult =
        checks.values.every((passed) => passed) &&
            roadTestResult == RoadTestResult.passed
        ? 'PASSED'
        : 'FAILED';
    return savedResult!;
  }
}

void main() {
  group('QualityGateController', () {
    late _MemoryQualityRepository repository;
    late QualityGateController controller;

    setUp(() {
      repository = _MemoryQualityRepository();
      controller = QualityGateController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test('requires work completion before quality sign-off', () async {
      await controller.load('job-1');
      controller.setInspectorName('Inspector One');

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(repository.savedResult, isNull);
      expect(controller.state.errorMessage, contains('work is complete'));
    });

    test('requires an explicit result for each check', () async {
      await controller.load('job-1');
      controller.setInspectorName('Inspector One');
      controller.setWorkCompleted(true);

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(controller.state.errorMessage, contains('each quality check'));
    });

    test('moves to passed only when all checks pass', () async {
      await controller.load('job-1');
      controller.setInspectorName('Inspector One');
      controller.setWorkCompleted(true);
      for (final spec in qualityCheckSpecs) {
        controller.setCheck(spec.id, true);
      }

      final saved = await controller.save();

      expect(saved, isTrue);
      expect(repository.savedResult, 'PASSED');
      expect(controller.state.result, 'PASSED');
    });

    test('a failed check is persisted as a failed quality result', () async {
      await controller.load('job-1');
      controller.setInspectorName('Inspector One');
      controller.setWorkCompleted(true);
      for (final spec in qualityCheckSpecs) {
        controller.setCheck(spec.id, spec.id != 'brakes_ok');
      }

      final saved = await controller.save();

      expect(saved, isTrue);
      expect(repository.savedResult, 'FAILED');
    });
  });
}

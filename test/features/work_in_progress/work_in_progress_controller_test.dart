import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/work_in_progress/work_in_progress_controller.dart';
import 'package:workshop_dms/features/work_in_progress/work_in_progress_models.dart';
import 'package:workshop_dms/features/work_in_progress/work_in_progress_repository.dart';

class _MemoryWorkRepository implements WorkInProgressRepository {
  final updates = <JobWorkUpdate>[];
  String? savedNote;
  WorkUpdateType? savedType;

  @override
  Future<WorkInProgressWorkspace> load(String jobCardId) async =>
      WorkInProgressWorkspace(
        jobCardId: jobCardId,
        registrationNumber: 'KA01AB1234',
        scope: const [
          WorkScopeItem(
            description: 'Replace front brake pads',
            itemType: 'part',
            quantity: 1,
          ),
        ],
        updates: List.unmodifiable(updates),
      );

  @override
  Future<void> addUpdate({
    required String jobCardId,
    required WorkUpdateType type,
    required String note,
  }) async {
    savedNote = note;
    savedType = type;
    updates.insert(
      0,
      JobWorkUpdate(
        type: type,
        note: note,
        createdBy: 'tech@example.test',
        createdAt: DateTime.utc(2026, 11, 20),
      ),
    );
  }
}

void main() {
  group('WorkInProgressController', () {
    late _MemoryWorkRepository repository;
    late WorkInProgressController controller;

    setUp(() {
      repository = _MemoryWorkRepository();
      controller = WorkInProgressController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test('loads approved job scope and vehicle context', () async {
      await controller.load('job-1');

      expect(controller.state.workspace?.registrationNumber, 'KA01AB1234');
      expect(controller.state.workspace?.scope, hasLength(1));
    });

    test('rejects a blank progress note', () async {
      await controller.load('job-1');

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(repository.savedNote, isNull);
      expect(controller.state.errorMessage, contains('2 and 1000'));
    });

    test('records and reloads a progress update', () async {
      await controller.load('job-1');
      controller.setType(WorkUpdateType.waitingForParts);
      controller.setNote('Waiting for the approved brake pad shipment.');

      final saved = await controller.save();

      expect(saved, isTrue);
      expect(repository.savedType, WorkUpdateType.waitingForParts);
      expect(
        repository.savedNote,
        'Waiting for the approved brake pad shipment.',
      );
      expect(controller.state.workspace?.updates, hasLength(1));
      expect(controller.state.note, isEmpty);
    });
  });
}

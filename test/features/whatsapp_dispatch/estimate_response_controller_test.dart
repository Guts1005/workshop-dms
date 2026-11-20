import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_controller.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_models.dart';
import 'package:workshop_dms/features/whatsapp_dispatch/estimate_response_repository.dart';

class _MemoryEstimateResponseRepository implements EstimateResponseRepository {
  String? recordedStatus;
  List<EstimateResponseItem>? recordedItems;
  bool loseNextResponse = false;

  @override
  Future<EstimateResponseWorkspace> getWorkspace(String jobCardId) async =>
      const EstimateResponseWorkspace(
        jobCardId: 'job-1',
        registrationNumber: 'KA01AB1234',
        customerName: 'Customer One',
        customerPhone: '9876543210',
        whatsappConsent: true,
        status: 'ESTIMATE_SENT',
        items: [
          EstimateResponseItem(
            id: 'item-1',
            description: 'Brake pads',
            itemType: 'part',
            code: '8708',
            quantity: 1,
            unitRatePaise: 120000,
            gstRatePercent: 18,
            decision: EstimateItemDecision.pending,
            note: '',
          ),
          EstimateResponseItem(
            id: 'item-2',
            description: 'Brake service',
            itemType: 'labour',
            code: '998714',
            quantity: 1,
            unitRatePaise: 50000,
            gstRatePercent: 18,
            decision: EstimateItemDecision.pending,
            note: '',
          ),
        ],
      );

  @override
  Future<String> recordResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  }) async {
    recordedItems = items;
    recordedStatus =
        items.every((item) => item.decision == EstimateItemDecision.approved)
        ? 'WORK_IN_PROGRESS'
        : 'ESTIMATE_REVISION_REQUIRED';
    if (loseNextResponse) {
      loseNextResponse = false;
      throw StateError('RPC response was lost after commit');
    }
    return recordedStatus!;
  }

  @override
  Future<String?> confirmRecordedResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  }) async => recordedItems?.length == items.length ? recordedStatus : null;
}

void main() {
  group('EstimateResponseController', () {
    late _MemoryEstimateResponseRepository repository;
    late EstimateResponseController controller;

    setUp(() {
      repository = _MemoryEstimateResponseRepository();
      controller = EstimateResponseController(repository: repository);
    });

    tearDown(() => controller.dispose());

    test('requires a decision for every line item', () async {
      await controller.load('job-1');
      controller.setDecision('item-1', EstimateItemDecision.approved);

      final saved = await controller.save();

      expect(saved, isFalse);
      expect(repository.recordedItems, isNull);
      expect(controller.state.errorMessage, contains('every estimate item'));
    });

    test('moves the job forward only when every item is approved', () async {
      await controller.load('job-1');
      controller.setDecision('item-1', EstimateItemDecision.approved);
      controller.setDecision('item-2', EstimateItemDecision.approved);

      final saved = await controller.save();

      expect(saved, isTrue);
      expect(controller.state.completedStatus, 'WORK_IN_PROGRESS');
      expect(repository.recordedItems, hasLength(2));
    });

    test('confirms saved decisions after an uncertain RPC response', () async {
      repository.loseNextResponse = true;
      await controller.load('job-1');
      controller.setDecision('item-1', EstimateItemDecision.approved);
      controller.setDecision('item-2', EstimateItemDecision.approved);

      expect(await controller.save(), isTrue);
      expect(controller.state.completedStatus, 'WORK_IN_PROGRESS');
      expect(controller.state.errorMessage, isNull);
    });

    test(
      'declines are stored and send the estimate back for revision',
      () async {
        await controller.load('job-1');
        controller.setDecision('item-1', EstimateItemDecision.declined);
        controller.setNote('item-1', 'Customer will supply this part.');
        controller.setDecision('item-2', EstimateItemDecision.approved);

        final saved = await controller.save();

        expect(saved, isTrue);
        expect(controller.state.completedStatus, 'ESTIMATE_REVISION_REQUIRED');
        expect(
          repository.recordedItems?.first.note,
          'Customer will supply this part.',
        );
      },
    );
  });
}

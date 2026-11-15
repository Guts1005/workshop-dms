import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/sync/outbox_sync_service.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_controller.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_models.dart';
import 'package:workshop_dms/features/bay_capture/bay_capture_repository.dart';

class MockRemoteSyncClient implements RemoteSyncClient {
  final List<OutboxItem> receivedItems = [];

  @override
  Future<bool> pushMutation(OutboxItem item) async {
    receivedItems.add(item);
    return true;
  }
}

void main() {
  group('BayCaptureController & Repository Unit Tests', () {
    late MockRemoteSyncClient mockRemoteClient;
    late OutboxSyncService outboxService;
    late LocalBayCaptureRepository repository;
    late BayCaptureController controller;

    setUp(() {
      mockRemoteClient = MockRemoteSyncClient();
      outboxService = OutboxSyncService(remoteClient: mockRemoteClient);
      repository = LocalBayCaptureRepository(outboxSyncService: outboxService);
      controller = BayCaptureController(
        repository: repository,
        initialJobCardId: 'JC-TEST-001',
        initialRegistration: 'RJ27CA1024',
      );
    });

    test('Initial state: 0/6 mandatory shots, cannot finalize check-in', () {
      final state = controller.state;
      expect(state.jobCardId, 'JC-TEST-001');
      expect(state.registrationNumber, 'RJ27CA1024');
      expect(state.mandatoryCompletedCount, 0);
      expect(state.totalMandatoryCount, 6);
      expect(state.isAllMandatoryCaptured, isFalse);
      expect(state.isOverrideActive, isFalse);
      expect(state.canFinalizeCheckIn, isFalse);
      expect(state.missingMandatoryShots.length, 6);
      expect(state.activeShotType, CheckInShotType.frontLeft45);
    });

    test('Recording captured photo increments count, computes hash, auto-advances slot', () async {
      const shot = CheckInShotType.frontLeft45;
      final bytes = [10, 20, 30, 40, 50];
      final hash = CapturedCheckInPhoto.computeHash(bytes);

      await controller.recordCapturedPhoto(
        shotType: shot,
        filePath: '/sandbox/bay_captures/fl45.jpg',
        sha256Hash: hash,
        fileSizeBytes: bytes.length,
      );

      final state = controller.state;
      expect(state.mandatoryCompletedCount, 1);
      expect(state.capturedPhotos.containsKey(shot), isTrue);
      expect(state.capturedPhotos[shot]!.sha256Hash, hash);
      expect(state.capturedPhotos[shot]!.fileSizeBytes, 5);

      // Auto-advanced to next uncaptured mandatory shot
      expect(state.activeShotType, CheckInShotType.frontRight45);

      // Verify Outbox record queued
      expect(outboxService.allItems.length, 1);
      final outboxItem = outboxService.allItems.first;
      expect(outboxItem.targetTable, 'bay_photos');
      expect(outboxItem.payload['shotType'], 'frontLeft45');
      expect(outboxItem.payload['sha256Hash'], hash);
    });

    test('Capturing all 6 mandatory shots unlocks check-in finalization without override', () async {
      final mandatoryShots = CheckInShotType.values.where((s) => s.isMandatory).toList();

      for (int i = 0; i < mandatoryShots.length; i++) {
        final shot = mandatoryShots[i];
        final bytes = List<int>.generate(32, (j) => i * 10 + j);
        await controller.recordCapturedPhoto(
          shotType: shot,
          filePath: '/sandbox/bay_captures/${shot.name}.jpg',
          sha256Hash: CapturedCheckInPhoto.computeHash(bytes),
          fileSizeBytes: bytes.length,
        );
      }

      final state = controller.state;
      expect(state.mandatoryCompletedCount, 6);
      expect(state.totalMandatoryCount, 6);
      expect(state.isAllMandatoryCaptured, isTrue);
      expect(state.missingMandatoryShots, isEmpty);
      expect(state.canFinalizeCheckIn, isTrue);

      // Finalize check-in
      final finalized = await controller.finalizeCheckIn();
      expect(finalized, isTrue);
      expect(controller.state.status, BayCaptureStatus.completed);

      // Verify JobCard status in repository advanced to INSPECTION_PENDING
      expect(repository.getJobCardStatus('JC-TEST-001'), 'INSPECTION_PENDING');

      // Verify JobCard update mutation in Outbox
      final jobCardUpdates = outboxService.allItems.where((i) => i.targetTable == 'job_cards').toList();
      expect(jobCardUpdates.length, 1);
      expect(jobCardUpdates.first.payload['status'], 'INSPECTION_PENDING');
      expect(jobCardUpdates.first.payload['photosCount'], 6);
    });

    test('Retake replaces only target shot and keeps other 5 intact', () async {
      // 1. Capture first 2 shots
      await controller.recordCapturedPhoto(
        shotType: CheckInShotType.frontLeft45,
        filePath: '/sandbox/fl45_v1.jpg',
        sha256Hash: 'hash-v1',
        fileSizeBytes: 100,
      );
      await controller.recordCapturedPhoto(
        shotType: CheckInShotType.frontRight45,
        filePath: '/sandbox/fr45_v1.jpg',
        sha256Hash: 'hash-fr-v1',
        fileSizeBytes: 150,
      );

      expect(controller.state.mandatoryCompletedCount, 2);

      // 2. Retake frontLeft45 with a new shot
      controller.retakeShot(CheckInShotType.frontLeft45);
      expect(controller.state.activeShotType, CheckInShotType.frontLeft45);

      await controller.recordCapturedPhoto(
        shotType: CheckInShotType.frontLeft45,
        filePath: '/sandbox/fl45_v2_retake.jpg',
        sha256Hash: 'hash-v2-sharp',
        fileSizeBytes: 120,
      );

      final state = controller.state;
      expect(state.mandatoryCompletedCount, 2);
      expect(state.capturedPhotos[CheckInShotType.frontLeft45]!.sha256Hash, 'hash-v2-sharp');
      expect(state.capturedPhotos[CheckInShotType.frontRight45]!.sha256Hash, 'hash-fr-v1');
    });

    test('Strict Gating: finalization blocked when < 6 mandatory shots without override', () async {
      // Only 2 shots captured
      await controller.recordCapturedPhoto(
        shotType: CheckInShotType.frontLeft45,
        filePath: '/sandbox/fl45.jpg',
        sha256Hash: 'hash-1',
        fileSizeBytes: 10,
      );

      expect(controller.state.canFinalizeCheckIn, isFalse);

      final finalized = await controller.finalizeCheckIn();
      expect(finalized, isFalse);
      expect(controller.state.status, BayCaptureStatus.idle);
      expect(controller.state.errorMessage, contains('Gating Error'));
      expect(repository.getJobCardStatus('JC-TEST-001'), isNull);
    });

    test('Manager Override: rejects invalid input (<2 char manager, <5 char reason)', () async {
      // Blank manager name
      var ok = await controller.applyManagerOverride(
        authorizedBy: ' ',
        reason: 'Front bumper crushed in accident',
      );
      expect(ok, isFalse);
      expect(controller.state.errorMessage, contains('at least 2 characters'));

      // Too short reason
      ok = await controller.applyManagerOverride(
        authorizedBy: 'Kunal (Mgr)',
        reason: 'bad',
      );
      expect(ok, isFalse);
      expect(controller.state.errorMessage, contains('at least 5 characters'));
    });

    test('Manager Override: unlocks finalization and records audit log with missing shots', () async {
      // 0 shots captured
      expect(controller.state.canFinalizeCheckIn, isFalse);

      final ok = await controller.applyManagerOverride(
        authorizedBy: 'Vikram Joshi (Floor Manager)',
        reason: 'Vehicle towed in post-collision, front fascia and plate missing',
      );

      expect(ok, isTrue);
      final state = controller.state;
      expect(state.isOverrideActive, isTrue);
      expect(state.canFinalizeCheckIn, isTrue);
      expect(state.managerOverride!.authorizedBy, 'Vikram Joshi (Floor Manager)');
      expect(state.managerOverride!.missingShots.length, 6);

      // Verify manager override recorded in outbox
      final overrideMutations = outboxService.allItems.where((i) => i.targetTable == 'manager_overrides').toList();
      expect(overrideMutations.length, 1);
      expect(overrideMutations.first.payload['authorizedBy'], 'Vikram Joshi (Floor Manager)');

      // Can now finalize check-in
      final finalized = await controller.finalizeCheckIn();
      expect(finalized, isTrue);
      expect(repository.getJobCardStatus('JC-TEST-001'), 'INSPECTION_PENDING');
    });

    test('Revoking Manager Override re-locks finalization if mandatory photos are missing', () async {
      await controller.applyManagerOverride(
        authorizedBy: 'Vikram Joshi',
        reason: 'Temporary override',
      );
      expect(controller.state.canFinalizeCheckIn, isTrue);

      controller.removeManagerOverride();
      expect(controller.state.isOverrideActive, isFalse);
      expect(controller.state.canFinalizeCheckIn, isFalse);
    });
  });
}

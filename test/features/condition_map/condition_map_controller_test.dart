import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:workshop_dms/data/sync/outbox_sync_service.dart';
import 'package:workshop_dms/features/condition_map/condition_map_controller.dart';
import 'package:workshop_dms/features/condition_map/condition_map_models.dart';
import 'package:workshop_dms/features/condition_map/condition_map_repository.dart';

class MockRemoteSyncClient implements RemoteSyncClient {
  final List<OutboxItem> receivedItems = [];

  @override
  Future<bool> pushMutation(OutboxItem item) async {
    receivedItems.add(item);
    return true;
  }
}

class LoseFirstSignOffResponseRepository extends LocalConditionMapRepository {
  LoseFirstSignOffResponseRepository() : super();

  final List<PreWorkSignOff> submittedSignOffs = [];
  bool _loseFirstResponse = true;

  @override
  Future<void> saveSignOff({
    required String jobCardId,
    required PreWorkSignOff signOff,
  }) async {
    submittedSignOffs.add(signOff);
    await super.saveSignOff(jobCardId: jobCardId, signOff: signOff);
    if (_loseFirstResponse) {
      _loseFirstResponse = false;
      throw Exception('Simulated response lost after server commit');
    }
  }
}

class LoseFirstFindingResponseRepository extends LocalConditionMapRepository {
  final List<ConditionPin> submittedPins = [];
  bool _loseFirstResponse = true;

  @override
  Future<ConditionPin> savePin({
    required String jobCardId,
    required ConditionPin pin,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    submittedPins.add(pin);
    final saved = await super.savePin(
      jobCardId: jobCardId,
      pin: pin,
      photoBytes: photoBytes,
      photoContentType: photoContentType,
    );
    if (_loseFirstResponse) {
      _loseFirstResponse = false;
      throw Exception('Simulated response lost after server commit');
    }
    return saved;
  }
}

void main() {
  group('PreWorkSignOff checksum', () {
    final signedAt = DateTime.utc(2026, 11, 21, 10);

    ConditionPin finding({String? note, String? photoPath}) => ConditionPin(
      id: 42,
      view: ConditionViewDirection.front,
      normalizedX: .25,
      normalizedY: .75,
      type: DefectType.dent,
      severity: DefectSeverity.moderate,
      note: note,
      photoPath: photoPath,
      createdAt: signedAt,
    );

    String checksum(ConditionPin pin) => PreWorkSignOff.generateChecksum(
      jobCardId: 'job-42',
      registrationNumber: 'KA01AB1234',
      pins: [pin],
      customerPhone: '9876543210',
      timestamp: signedAt,
    );

    test('covers finding notes and attached photo paths', () {
      final original = checksum(
        finding(
          note: 'Small dent near headlamp',
          photoPath: 'photo/hash-a.jpg',
        ),
      );

      expect(
        checksum(
          finding(note: 'Small dent at bumper', photoPath: 'photo/hash-a.jpg'),
        ),
        isNot(original),
      );
      expect(
        checksum(
          finding(
            note: 'Small dent near headlamp',
            photoPath: 'photo/hash-b.jpg',
          ),
        ),
        isNot(original),
      );
    });

    test('is independent of finding list order', () {
      final first = finding(note: 'First');
      final second = ConditionPin(
        id: 8,
        view: ConditionViewDirection.rear,
        normalizedX: .5,
        normalizedY: .4,
        type: DefectType.surfaceScuff,
        severity: DefectSeverity.minor,
        note: 'Second',
        createdAt: signedAt,
      );

      String hash(List<ConditionPin> pins) => PreWorkSignOff.generateChecksum(
        jobCardId: 'job-42',
        registrationNumber: 'KA01AB1234',
        pins: pins,
        customerPhone: '9876543210',
        timestamp: signedAt,
      );

      expect(hash([first, second]), hash([second, first]));
    });
  });

  group('ConditionMapController & Repository Unit Tests', () {
    late MockRemoteSyncClient mockRemoteClient;
    late OutboxSyncService outboxService;
    late LocalConditionMapRepository repository;
    late ConditionMapController controller;

    setUp(() {
      mockRemoteClient = MockRemoteSyncClient();
      outboxService = OutboxSyncService(remoteClient: mockRemoteClient);
      repository = LocalConditionMapRepository(
        outboxSyncService: outboxService,
      );
      controller = ConditionMapController(
        repository: repository,
        initialJobCardId: 'JC-MAP-001',
        initialRegistration: 'DL01AB9988',
      );
    });

    test('Initial State: empty pins, unlocked, sideLeft active', () {
      final state = controller.state;
      expect(state.jobCardId, 'JC-MAP-001');
      expect(state.registrationNumber, 'DL01AB9988');
      expect(state.pins, isEmpty);
      expect(state.totalPinCount, 0);
      expect(state.isLocked, isFalse);
      expect(state.activeView, ConditionViewDirection.sideLeft);
      expect(state.selectedPin, isNull);
    });

    test(
      'Switching views updates activeView and deselects active pin',
      () async {
        controller.switchView(ConditionViewDirection.front);
        expect(controller.state.activeView, ConditionViewDirection.front);
        expect(controller.state.selectedPin, isNull);

        controller.switchView(ConditionViewDirection.rear);
        expect(controller.state.activeView, ConditionViewDirection.rear);
      },
    );

    test('Adding a pin saves to repository, queues outbox mutation, and clamps coordinates', () async {
      final pin = await controller.addPin(
        view: ConditionViewDirection.sideLeft,
        nx: 1.25, // should clamp to 1.0
        ny: -0.15, // should clamp to 0.0
        type: DefectType.dent,
        severity: DefectSeverity.severe,
        note: 'Deep dent on door panel',
      );

      expect(pin.id, greaterThan(0));
      expect(pin.id, lessThanOrEqualTo(0x7fffffff));
      expect(pin.normalizedX, 1.0);
      expect(pin.normalizedY, 0.0);
      expect(pin.type, DefectType.dent);
      expect(pin.severity, DefectSeverity.severe);

      final state = controller.state;
      expect(state.totalPinCount, 1);
      expect(state.severeCount, 1);
      expect(state.moderateCount, 0);
      expect(state.minorCount, 0);
      expect(state.selectedPin, pin);

      // Verify Outbox Mutation
      expect(outboxService.allItems.length, 1);
      final item = outboxService.allItems.first;
      expect(item.targetTable, 'condition_pins');
      expect(item.operation, 'INSERT');
      expect(item.payload['type'], 'dent');
      expect(item.payload['severity'], 'severe');
    });

    test(
      'Retry after a lost finding response reuses the same finding id',
      () async {
        final retryRepository = LoseFirstFindingResponseRepository();
        final retryController = ConditionMapController(
          repository: retryRepository,
          initialJobCardId: 'JC-FINDING-RETRY',
          initialRegistration: 'DL01AB9988',
        );
        final photoBytes = Uint8List.fromList([1, 2, 3, 4]);

        Future<ConditionPin> saveFinding() => retryController.addPin(
          view: ConditionViewDirection.front,
          nx: .5,
          ny: .4,
          type: DefectType.surfaceScuff,
          severity: DefectSeverity.minor,
          note: 'Short scratch near the lamp',
          photoBytes: photoBytes,
          photoContentType: 'image/jpeg',
        );

        await expectLater(saveFinding(), throwsException);
        final firstAttempt = retryRepository.submittedPins.single;
        final saved = await saveFinding();

        expect(retryRepository.submittedPins, hasLength(2));
        expect(retryRepository.submittedPins.last.id, firstAttempt.id);
        expect(
          retryRepository.submittedPins.last.createdAt,
          firstAttempt.createdAt,
        );
        expect(saved.id, firstAttempt.id);
        expect(
          (await retryRepository.getPinsForJobCard('JC-FINDING-RETRY')),
          hasLength(1),
        );
        expect(retryController.state.pins, hasLength(1));
      },
    );

    test(
      'Cancel after an uncertain save refreshes before a new finding',
      () async {
        final retryRepository = LoseFirstFindingResponseRepository();
        final retryController = ConditionMapController(
          repository: retryRepository,
          initialJobCardId: 'JC-FINDING-CANCEL',
          initialRegistration: 'QA-ONLY',
        );

        await expectLater(
          retryController.addPin(
            view: ConditionViewDirection.front,
            nx: .5,
            ny: .4,
            type: DefectType.surfaceScuff,
            severity: DefectSeverity.minor,
            note: 'QA TEST ONLY: first synthetic finding',
          ),
          throwsException,
        );
        final firstPinId = retryRepository.submittedPins.single.id;

        retryController.discardPendingPin();
        final secondPin = await retryController.addPin(
          view: ConditionViewDirection.rear,
          nx: .6,
          ny: .5,
          type: DefectType.dent,
          severity: DefectSeverity.moderate,
          note: 'QA TEST ONLY: second synthetic finding',
        );

        expect(secondPin.id, isNot(firstPinId));
        expect(retryController.state.pins, hasLength(2));
        expect(
          await retryRepository.getPinsForJobCard('JC-FINDING-CANCEL'),
          hasLength(2),
        );
      },
    );

    test('Adding multiple pins increments sequential ID and filters by active view', () async {
      await controller.addPin(
        view: ConditionViewDirection.sideLeft,
        nx: 0.35,
        ny: 0.50,
        type: DefectType.deepScratch,
        severity: DefectSeverity.moderate,
      );

      await controller.addPin(
        view: ConditionViewDirection.front,
        nx: 0.50,
        ny: 0.40,
        type: DefectType.glassCrack,
        severity: DefectSeverity.severe,
      );

      final state = controller.state;
      expect(state.totalPinCount, 2);
      final leftPinId = state.pins[0].id;
      final frontPinId = state.pins[1].id;
      expect(leftPinId, isNot(frontPinId));

      // In sideLeft view, only 1 pin is active
      expect(state.activeViewPins.length, 1);
      expect(state.activeViewPins.first.id, leftPinId);

      // Switch to front view, 1 pin active
      controller.switchView(ConditionViewDirection.front);
      expect(controller.state.activeViewPins.length, 1);
      expect(controller.state.activeViewPins.first.id, frontPinId);
    });

    test('Deleting a pin removes it from state, queues outbox delete, and unselects', () async {
      final pin = await controller.addPin(
        view: ConditionViewDirection.sideLeft,
        nx: 0.4,
        ny: 0.4,
        type: DefectType.paintChip,
        severity: DefectSeverity.minor,
      );

      expect(controller.state.totalPinCount, 1);
      expect(controller.state.selectedPin?.id, pin.id);

      await controller.deletePin(pin.id);

      expect(controller.state.totalPinCount, 0);
      expect(controller.state.selectedPin, isNull);

      final deleteMutation = outboxService.allItems.firstWhere(
        (i) => i.operation == 'DELETE',
      );
      expect(deleteMutation.targetTable, 'condition_pins');
      expect(deleteMutation.payload['pinId'], pin.id);
    });

    test('Sign-off input validation rejects invalid inputs', () async {
      for (final view in ConditionViewDirection.values) {
        await controller.markViewReviewed(view);
      }
      // Too short customer name
      expect(
        controller.validateSignOffInput(
          customerName: 'A',
          customerPhone: '9876543210',
          advisorName: 'Kunal',
        ),
        contains('Customer name must be at least 2 characters'),
      );

      // Invalid phone number
      expect(
        controller.validateSignOffInput(
          customerName: 'Aarav',
          customerPhone: '12345',
          advisorName: 'Kunal',
        ),
        contains('10-digit customer mobile number'),
      );

      // Too short advisor name
      expect(
        controller.validateSignOffInput(
          customerName: 'Aarav',
          customerPhone: '9876543210',
          advisorName: 'K',
        ),
        contains('Service advisor name must be at least 2 characters'),
      );
    });

    test('Confirming pre-work sign-off generates SHA-256 checksum, locks map, and updates JobCard', () async {
      // Add 2 defects
      await controller.addPin(
        view: ConditionViewDirection.front,
        nx: 0.25,
        ny: 0.45,
        type: DefectType.dent,
        severity: DefectSeverity.moderate,
      );

      for (final view in ConditionViewDirection.values) {
        await controller.markViewReviewed(view);
      }
      await controller.addPin(
        view: ConditionViewDirection.rear,
        nx: 0.65,
        ny: 0.55,
        type: DefectType.surfaceScuff,
        severity: DefectSeverity.minor,
      );

      expect(controller.state.isLocked, isFalse);

      final success = await controller.confirmPreWorkSignOff(
        customerName: 'Rohan Sharma',
        customerPhone: '9876543210',
        advisorName: 'Manish Verma (Lead Advisor)',
      );

      expect(success, isTrue);
      final state = controller.state;
      expect(state.isLocked, isTrue);
      expect(state.signOff, isNotNull);
      expect(state.signOff!.customerName, 'Rohan Sharma');
      expect(state.signOff!.customerPhone, '9876543210');
      expect(state.signOff!.advisorName, 'Manish Verma (Lead Advisor)');
      expect(state.signOff!.sha256Checksum.length, 64); // SHA-256 hex string

      // Verify JobCard status in repository advanced to INSPECTION_PENDING
      expect(repository.getJobCardStatus('JC-MAP-001'), 'INSPECTION_PENDING');

      // Verify signoff and jobcard update in outbox
      final signoffMutation = outboxService.allItems.firstWhere(
        (i) => i.targetTable == 'condition_signoffs',
      );
      expect(signoffMutation.payload['customerName'], 'Rohan Sharma');

      final jobCardMutation = outboxService.allItems.firstWhere(
        (i) => i.targetTable == 'job_cards',
      );
      expect(jobCardMutation.payload['status'], 'INSPECTION_PENDING');
      expect(jobCardMutation.payload['conditionPinsCount'], 2);
    });

    test(
      'Retry after lost sign-off response reuses the exact signed payload',
      () async {
        final retryRepository = LoseFirstSignOffResponseRepository();
        final retryController = ConditionMapController(
          repository: retryRepository,
          initialJobCardId: 'JC-RETRY-001',
          initialRegistration: 'DL01AB9988',
        );
        for (final view in ConditionViewDirection.values) {
          await retryController.markViewReviewed(view);
        }

        final firstResult = await retryController.confirmPreWorkSignOff(
          customerName: 'Rohan Sharma',
          customerPhone: '9876543210',
          advisorName: 'Manish Verma',
        );
        final firstSignOff = retryRepository.submittedSignOffs.single;
        expect(firstResult, isFalse);
        expect(retryController.state.status, ConditionMapStatus.error);
        expect(
          () => retryController.addPin(
            view: ConditionViewDirection.front,
            nx: 0.5,
            ny: 0.5,
            type: DefectType.dent,
            severity: DefectSeverity.minor,
          ),
          throwsStateError,
        );

        final changedSignerResult = await retryController.confirmPreWorkSignOff(
          customerName: 'Rohan Sharma',
          customerPhone: '9876543210',
          advisorName: 'Another Advisor',
        );
        expect(changedSignerResult, isFalse);
        expect(retryRepository.submittedSignOffs, hasLength(1));

        final retryResult = await retryController.confirmPreWorkSignOff(
          customerName: 'Rohan Sharma',
          customerPhone: '9876543210',
          advisorName: 'Manish Verma',
        );

        expect(retryResult, isTrue);
        expect(retryRepository.submittedSignOffs, hasLength(2));
        expect(
          retryRepository.submittedSignOffs.last.signedAt,
          firstSignOff.signedAt,
        );
        expect(
          retryRepository.submittedSignOffs.last.sha256Checksum,
          firstSignOff.sha256Checksum,
        );
      },
    );

    test(
      'Modifications are blocked once map is signed off and locked',
      () async {
        for (final view in ConditionViewDirection.values) {
          await controller.markViewReviewed(view);
        }
        await controller.confirmPreWorkSignOff(
          customerName: 'Rohan Sharma',
          customerPhone: '9876543210',
          advisorName: 'Manish Verma',
        );

        expect(controller.state.isLocked, isTrue);

        // Attempt to add pin throws StateError
        expect(
          () => controller.addPin(
            view: ConditionViewDirection.front,
            nx: 0.5,
            ny: 0.5,
            type: DefectType.dent,
            severity: DefectSeverity.minor,
          ),
          throwsStateError,
        );

        // Attempt to delete throws StateError
        expect(() => controller.deletePin(1), throwsStateError);
      },
    );
  });
}

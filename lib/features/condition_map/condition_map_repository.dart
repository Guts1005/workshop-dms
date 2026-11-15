import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../data/sync/outbox_sync_service.dart';
import 'condition_map_models.dart';

abstract class ConditionMapRepository {
  Future<List<ConditionPin>> getPinsForJobCard(String jobCardId);
  Future<void> savePin({required String jobCardId, required ConditionPin pin});
  Future<void> deletePin({required String jobCardId, required int pinId});
  Future<PreWorkSignOff?> getSignOff(String jobCardId);
  Future<void> saveSignOff({required String jobCardId, required PreWorkSignOff signOff});
  String? getJobCardStatus(String jobCardId);
}

class LocalConditionMapRepository implements ConditionMapRepository {
  final OutboxSyncService? outboxSyncService;
  final _uuid = const Uuid();

  final Map<String, List<ConditionPin>> _pinsByJobCard = {};
  final Map<String, PreWorkSignOff> _signOffsByJobCard = {};
  final Map<String, String> _jobCardStatuses = {};

  LocalConditionMapRepository({this.outboxSyncService});

  @override
  Future<List<ConditionPin>> getPinsForJobCard(String jobCardId) async {
    return List.unmodifiable(_pinsByJobCard[jobCardId] ?? []);
  }

  @override
  Future<void> savePin({required String jobCardId, required ConditionPin pin}) async {
    _pinsByJobCard.putIfAbsent(jobCardId, () => []);
    final list = _pinsByJobCard[jobCardId]!;
    final existingIdx = list.indexWhere((p) => p.id == pin.id);
    if (existingIdx >= 0) {
      list[existingIdx] = pin;
    } else {
      list.add(pin);
    }

    // Enqueue Outbox mutation
    final mutationId = _uuid.v4();
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_pins',
      recordId: '${jobCardId}_pin_${pin.id}',
      operation: 'INSERT',
      payload: {
        'id': mutationId,
        'jobCardId': jobCardId,
        ...pin.toJson(),
      },
    );
  }

  @override
  Future<void> deletePin({required String jobCardId, required int pinId}) async {
    _pinsByJobCard[jobCardId]?.removeWhere((p) => p.id == pinId);

    // Enqueue Outbox deletion
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_pins',
      recordId: '${jobCardId}_pin_$pinId',
      operation: 'DELETE',
      payload: {
        'jobCardId': jobCardId,
        'pinId': pinId,
      },
    );
  }

  @override
  Future<PreWorkSignOff?> getSignOff(String jobCardId) async {
    return _signOffsByJobCard[jobCardId];
  }

  @override
  Future<void> saveSignOff({required String jobCardId, required PreWorkSignOff signOff}) async {
    _signOffsByJobCard[jobCardId] = signOff;
    _jobCardStatuses[jobCardId] = 'INSPECTION_PENDING';

    final signOffId = _uuid.v4();
    // Outbox: Sign-off record
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_signoffs',
      recordId: signOffId,
      operation: 'INSERT',
      payload: {
        'id': signOffId,
        'jobCardId': jobCardId,
        ...signOff.toJson(),
      },
    );

    // Outbox: Advance Job Card status to INSPECTION_PENDING
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'job_cards',
      recordId: jobCardId,
      operation: 'UPDATE',
      payload: {
        'jobCardId': jobCardId,
        'status': 'INSPECTION_PENDING',
        'conditionPinsCount': _pinsByJobCard[jobCardId]?.length ?? 0,
        'signedAt': signOff.signedAt.toIso8601String(),
        'checksum': signOff.sha256Checksum,
      },
    );
  }

  @override
  String? getJobCardStatus(String jobCardId) {
    return _jobCardStatuses[jobCardId];
  }
}

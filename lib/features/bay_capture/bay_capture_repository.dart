import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../data/sync/outbox_sync_service.dart';
import 'bay_capture_models.dart';

abstract class BayCaptureRepository {
  Future<void> savePhoto({
    required String jobCardId,
    required CapturedCheckInPhoto photo,
  });

  Future<Map<CheckInShotType, CapturedCheckInPhoto>> getPhotosForJobCard(String jobCardId);

  Future<void> removePhoto({
    required String jobCardId,
    required CheckInShotType shotType,
  });

  Future<void> recordManagerOverride({
    required String jobCardId,
    required ManagerOverrideRecord override,
  });

  Future<ManagerOverrideRecord?> getManagerOverride(String jobCardId);

  Future<void> finalizeBayCheckIn({
    required String jobCardId,
    ManagerOverrideRecord? override,
  });
}

class LocalBayCaptureRepository implements BayCaptureRepository {
  final OutboxSyncService? outboxSyncService;
  final _uuid = const Uuid();

  // In-memory backing stores per jobCardId
  final Map<String, Map<CheckInShotType, CapturedCheckInPhoto>> _photosByJobCard = {};
  final Map<String, ManagerOverrideRecord> _overridesByJobCard = {};
  final Map<String, String> _jobCardStatuses = {};

  LocalBayCaptureRepository({this.outboxSyncService});

  @override
  Future<void> savePhoto({
    required String jobCardId,
    required CapturedCheckInPhoto photo,
  }) async {
    _photosByJobCard.putIfAbsent(jobCardId, () => {});
    _photosByJobCard[jobCardId]![photo.shotType] = photo;

    // Enqueue Outbox mutation for cloud sync and offline persistence
    final photoRecordId = _uuid.v4();
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'bay_photos',
      recordId: photoRecordId,
      operation: 'INSERT',
      payload: {
        'id': photoRecordId,
        'jobCardId': jobCardId,
        'shotType': photo.shotType.name,
        'localPath': photo.localFilePath,
        'sha256Hash': photo.sha256Hash,
        'capturedAt': photo.capturedAt.toIso8601String(),
        'fileSizeBytes': photo.fileSizeBytes,
      },
    );
  }

  @override
  Future<Map<CheckInShotType, CapturedCheckInPhoto>> getPhotosForJobCard(String jobCardId) async {
    return Map.unmodifiable(_photosByJobCard[jobCardId] ?? {});
  }

  @override
  Future<void> removePhoto({
    required String jobCardId,
    required CheckInShotType shotType,
  }) async {
    _photosByJobCard[jobCardId]?.remove(shotType);
  }

  @override
  Future<void> recordManagerOverride({
    required String jobCardId,
    required ManagerOverrideRecord override,
  }) async {
    _overridesByJobCard[jobCardId] = override;

    final overrideId = _uuid.v4();
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'manager_overrides',
      recordId: overrideId,
      operation: 'INSERT',
      payload: {
        'id': overrideId,
        'jobCardId': jobCardId,
        'stage': 'BAY_CAPTURE',
        'authorizedBy': override.authorizedBy,
        'reason': override.reason,
        'missingShots': override.missingShots.map((s) => s.name).toList(),
        'timestamp': override.timestamp.toIso8601String(),
      },
    );
  }

  @override
  Future<ManagerOverrideRecord?> getManagerOverride(String jobCardId) async {
    return _overridesByJobCard[jobCardId];
  }

  @override
  Future<void> finalizeBayCheckIn({
    required String jobCardId,
    ManagerOverrideRecord? override,
  }) async {
    final photos = _photosByJobCard[jobCardId] ?? {};
    final mandatoryCount = CheckInShotType.values
        .where((shot) => shot.isMandatory && photos.containsKey(shot))
        .length;

    final hasOverride = override != null || _overridesByJobCard.containsKey(jobCardId);

    if (mandatoryCount < 6 && !hasOverride) {
      throw StateError(
        'Cannot finalize check-in: Missing mandatory photos ($mandatoryCount/6 captured) and no Manager Override authorized.',
      );
    }

    if (override != null) {
      await recordManagerOverride(jobCardId: jobCardId, override: override);
    }

    // Advance Job Card status to INSPECTION_PENDING (ready for Stage 3 Condition Map & Stage 4 Inspection)
    _jobCardStatuses[jobCardId] = 'INSPECTION_PENDING';

    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'job_cards',
      recordId: jobCardId,
      operation: 'UPDATE',
      payload: {
        'status': 'INSPECTION_PENDING',
        'bayCaptureCompletedAt': DateTime.now().toIso8601String(),
        'photosCount': photos.length,
        'hasOverride': hasOverride,
      },
    );
  }

  String? getJobCardStatus(String jobCardId) => _jobCardStatuses[jobCardId];
}

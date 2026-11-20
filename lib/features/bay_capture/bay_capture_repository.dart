import 'dart:async';

import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sync/outbox_sync_service.dart';
import 'bay_capture_models.dart';

abstract class BayCaptureRepository {
  Future<CapturedCheckInPhoto> savePhoto({
    required String jobCardId,
    required CapturedCheckInPhoto photo,
  });

  Future<Map<CheckInShotType, CapturedCheckInPhoto>> getPhotosForJobCard(
    String jobCardId,
  );

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
  final Map<String, Map<CheckInShotType, CapturedCheckInPhoto>>
  _photosByJobCard = {};
  final Map<String, ManagerOverrideRecord> _overridesByJobCard = {};
  final Map<String, String> _jobCardStatuses = {};

  LocalBayCaptureRepository({this.outboxSyncService});

  @override
  Future<CapturedCheckInPhoto> savePhoto({
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
    return photo;
  }

  @override
  Future<Map<CheckInShotType, CapturedCheckInPhoto>> getPhotosForJobCard(
    String jobCardId,
  ) async {
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
    final hasOverride =
        override != null || _overridesByJobCard.containsKey(jobCardId);
    final missingShots = CheckInShotType.values
        .where((shot) => shot.isMandatory && !photos.containsKey(shot))
        .toList();
    if (missingShots.isNotEmpty && !hasOverride) {
      throw StateError(
        'Capture all mandatory photos or record a manager override before continuing.',
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
        'missingShots': missingShots.map((shot) => shot.name).toList(),
        'hasOverride': hasOverride,
      },
    );
  }

  String? getJobCardStatus(String jobCardId) => _jobCardStatuses[jobCardId];
}

class SupabaseBayCaptureRepository implements BayCaptureRepository {
  SupabaseBayCaptureRepository(this.client);
  final SupabaseClient client;
  static const _bucket = 'workshop-checkin';

  Future<String> _workshopId() async =>
      (await client
              .from('workshop_memberships')
              .select('workshop_id')
              .eq('user_id', client.auth.currentUser!.id)
              .single())['workshop_id']
          as String;

  String _path(String workshopId, String jobId, CheckInShotType shot) =>
      '$workshopId/$jobId/${shot.name}/${const Uuid().v4()}.jpg';

  Future<String?> _signedUrlOrNull(String path) async {
    try {
      return await client.storage.from(_bucket).createSignedUrl(path, 3600);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CapturedCheckInPhoto> savePhoto({
    required String jobCardId,
    required CapturedCheckInPhoto photo,
  }) async {
    final bytes = photo.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Photo data is empty. Retake the photo and try again.');
    }
    final workshopId = await _workshopId();
    final existing = await client
        .from('bay_photos')
        .select('storage_path')
        .eq('job_card_id', jobCardId)
        .eq('shot_type', photo.shotType.name)
        .maybeSingle();
    final previousPath = existing?['storage_path'] as String?;
    final path = _path(workshopId, jobCardId, photo.shotType);
    await client.storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );
    try {
      await client.from('bay_photos').upsert({
        'workshop_id': workshopId,
        'job_card_id': jobCardId,
        'shot_type': photo.shotType.name,
        'storage_path': path,
        'sha256_hash': photo.sha256Hash,
        'captured_at': photo.capturedAt.toUtc().toIso8601String(),
      }, onConflict: 'job_card_id,shot_type');
    } catch (_) {
      await client.storage.from(_bucket).remove([path]);
      rethrow;
    }
    if (previousPath != null && previousPath != path) {
      try {
        await client.storage.from(_bucket).remove([previousPath]);
      } catch (_) {
        // The database now references the new object; cleanup can be retried later.
      }
    }
    return CapturedCheckInPhoto(
      shotType: photo.shotType,
      localFilePath: path,
      sha256Hash: photo.sha256Hash,
      capturedAt: photo.capturedAt,
      fileSizeBytes: photo.fileSizeBytes,
      remoteUrl: await _signedUrlOrNull(path),
    );
  }

  @override
  Future<Map<CheckInShotType, CapturedCheckInPhoto>> getPhotosForJobCard(
    String jobCardId,
  ) async {
    final rows = await client
        .from('bay_photos')
        .select('shot_type, storage_path, sha256_hash, captured_at')
        .eq('job_card_id', jobCardId);
    final photos = <CheckInShotType, CapturedCheckInPhoto>{};
    for (final row in rows) {
      final shotType = CheckInShotType.values.firstWhere(
        (shot) => shot.name == row['shot_type'],
      );
      final path = row['storage_path'] as String;
      final remoteUrl = await _signedUrlOrNull(path);
      photos[shotType] = CapturedCheckInPhoto(
        shotType: shotType,
        localFilePath: path,
        sha256Hash: row['sha256_hash'] as String,
        capturedAt: DateTime.parse(row['captured_at'] as String),
        fileSizeBytes: 0,
        remoteUrl: remoteUrl,
      );
    }
    return photos;
  }

  @override
  Future<void> removePhoto({
    required String jobCardId,
    required CheckInShotType shotType,
  }) async {
    final row = await client
        .from('bay_photos')
        .select('storage_path')
        .eq('job_card_id', jobCardId)
        .eq('shot_type', shotType.name)
        .maybeSingle();
    if (row == null) return;
    await client
        .from('bay_photos')
        .delete()
        .eq('job_card_id', jobCardId)
        .eq('shot_type', shotType.name);
    await client.storage.from(_bucket).remove([row['storage_path'] as String]);
  }

  @override
  Future<void> recordManagerOverride({
    required String jobCardId,
    required ManagerOverrideRecord override,
  }) async {
    final workshopId = await _workshopId();
    await client.from('manager_overrides').insert({
      'workshop_id': workshopId,
      'job_card_id': jobCardId,
      'authorized_by': override.authorizedBy,
      'reason': override.reason,
      'missing_shots': override.missingShots.map((shot) => shot.name).toList(),
      'created_at': override.timestamp.toUtc().toIso8601String(),
    });
  }

  @override
  Future<ManagerOverrideRecord?> getManagerOverride(String jobCardId) async {
    final row = await client
        .from('manager_overrides')
        .select('authorized_by, reason, missing_shots, created_at')
        .eq('job_card_id', jobCardId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return ManagerOverrideRecord(
      authorizedBy: row['authorized_by'] as String,
      reason: row['reason'] as String,
      timestamp: DateTime.parse(row['created_at'] as String),
      missingShots: (row['missing_shots'] as List<dynamic>)
          .map(
            (name) =>
                CheckInShotType.values.firstWhere((shot) => shot.name == name),
          )
          .toList(),
    );
  }

  @override
  Future<void> finalizeBayCheckIn({
    required String jobCardId,
    ManagerOverrideRecord? override,
  }) async {
    await client.rpc(
      'finalize_bay_check_in',
      params: {'p_job_card_id': jobCardId},
    );
  }
}

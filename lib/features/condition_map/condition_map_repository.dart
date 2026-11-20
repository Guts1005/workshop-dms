import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/sync/outbox_sync_service.dart';
import 'condition_map_models.dart';

abstract class ConditionMapRepository {
  Future<List<ConditionPin>> getPinsForJobCard(String jobCardId);
  Future<ConditionPin> savePin({
    required String jobCardId,
    required ConditionPin pin,
    Uint8List? photoBytes,
    String? photoContentType,
  });
  Future<void> deletePin({required String jobCardId, required int pinId});
  Future<PreWorkSignOff?> getSignOff(String jobCardId);
  Future<void> saveSignOff({
    required String jobCardId,
    required PreWorkSignOff signOff,
  });
  Future<Set<ConditionViewDirection>> getReviewedViews(String jobCardId);
  Future<void> saveReviewedViews(
    String jobCardId,
    Set<ConditionViewDirection> views,
  );
  String? getJobCardStatus(String jobCardId);
}

class LocalConditionMapRepository implements ConditionMapRepository {
  final OutboxSyncService? outboxSyncService;
  final _uuid = const Uuid();
  final Map<String, List<ConditionPin>> _pinsByJobCard = {};
  final Map<String, PreWorkSignOff> _signOffsByJobCard = {};
  final Map<String, String> _jobCardStatuses = {};
  final Map<String, Set<ConditionViewDirection>> _reviewedByJobCard = {};

  LocalConditionMapRepository({this.outboxSyncService});

  @override
  Future<List<ConditionPin>> getPinsForJobCard(String jobCardId) async {
    return List.unmodifiable(
      _pinsByJobCard[jobCardId] ?? const <ConditionPin>[],
    );
  }

  @override
  Future<ConditionPin> savePin({
    required String jobCardId,
    required ConditionPin pin,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    final savedPin = pin;
    _pinsByJobCard.putIfAbsent(jobCardId, () => []);
    final list = _pinsByJobCard[jobCardId]!;
    final existingIdx = list.indexWhere((p) => p.id == savedPin.id);
    if (existingIdx >= 0) {
      list[existingIdx] = savedPin;
    } else {
      list.add(savedPin);
    }
    // Enqueue Outbox mutation
    final mutationId = _uuid.v4();
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_pins',
      recordId: '${jobCardId}_pin_${savedPin.id}',
      operation: 'INSERT',
      payload: {'id': mutationId, 'jobCardId': jobCardId, ...savedPin.toJson()},
    );
    return savedPin;
  }

  @override
  Future<void> deletePin({
    required String jobCardId,
    required int pinId,
  }) async {
    _pinsByJobCard[jobCardId]?.removeWhere((p) => p.id == pinId);
    // Enqueue Outbox deletion
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_pins',
      recordId: '${jobCardId}_pin_$pinId',
      operation: 'DELETE',
      payload: {'jobCardId': jobCardId, 'pinId': pinId},
    );
  }

  @override
  Future<PreWorkSignOff?> getSignOff(String jobCardId) async {
    return _signOffsByJobCard[jobCardId];
  }

  @override
  Future<void> saveSignOff({
    required String jobCardId,
    required PreWorkSignOff signOff,
  }) async {
    _signOffsByJobCard[jobCardId] = signOff;
    _jobCardStatuses[jobCardId] = 'INSPECTION_PENDING';

    final signOffId = _uuid.v4();
    // Outbox: Sign-off record
    outboxSyncService?.enqueue(
      id: _uuid.v4(),
      targetTable: 'condition_signoffs',
      recordId: signOffId,
      operation: 'INSERT',
      payload: {'id': signOffId, 'jobCardId': jobCardId, ...signOff.toJson()},
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

  @override
  Future<Set<ConditionViewDirection>> getReviewedViews(String jobCardId) async {
    return Set.unmodifiable(_reviewedByJobCard[jobCardId] ?? const {});
  }

  @override
  Future<void> saveReviewedViews(
    String jobCardId,
    Set<ConditionViewDirection> views,
  ) async {
    _reviewedByJobCard[jobCardId] = Set.of(views);
  }
}

class SupabaseConditionMapRepository implements ConditionMapRepository {
  SupabaseConditionMapRepository(this.client);
  final SupabaseClient client;
  static const _photoBucket = 'workshop-checkin';

  Future<String> _workshopId() async =>
      (await client
              .from('workshop_memberships')
              .select('workshop_id')
              .eq('user_id', client.auth.currentUser!.id)
              .single())['workshop_id']
          as String;

  @override
  Future<List<ConditionPin>> getPinsForJobCard(String jobCardId) async {
    final rows = await client
        .from('condition_findings')
        .select(
          'id, area, normalized_x, normalized_y, finding_type, severity, note, photo_storage_path, created_at',
        )
        .eq('job_card_id', jobCardId)
        .order('id');
    return rows
        .map(
          (row) => ConditionPin(
            id: row['id'] as int,
            view: ConditionViewDirection.values.firstWhere(
              (v) => v.name == row['area'],
            ),
            normalizedX: (row['normalized_x'] as num).toDouble(),
            normalizedY: (row['normalized_y'] as num).toDouble(),
            type: DefectType.values.firstWhere(
              (v) => v.name == row['finding_type'],
            ),
            severity: DefectSeverity.values.firstWhere(
              (v) => v.name == row['severity'],
            ),
            note: row['note'] as String?,
            photoPath: row['photo_storage_path'] as String?,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }

  @override
  Future<ConditionPin> savePin({
    required String jobCardId,
    required ConditionPin pin,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    final workshopId = await _workshopId();
    var savedPin = pin;
    String? uploadedPath;
    final existingRow = await client
        .from('condition_findings')
        .select('photo_storage_path')
        .eq('job_card_id', jobCardId)
        .eq('id', pin.id)
        .maybeSingle();
    final previousPath = existingRow?['photo_storage_path'] as String?;
    if (photoBytes != null) {
      if (photoBytes.isEmpty) {
        throw StateError('The selected photo is empty. Choose another photo.');
      }
      final contentType = photoContentType ?? 'image/jpeg';
      if (!const {
        'image/jpeg',
        'image/png',
        'image/webp',
      }.contains(contentType)) {
        throw StateError('Choose a JPEG, PNG, or WebP photo.');
      }
      final extension = switch (contentType) {
        'image/png' => 'png',
        'image/webp' => 'webp',
        _ => 'jpg',
      };
      final contentHash = sha256.convert(photoBytes).toString();
      uploadedPath =
          '$workshopId/$jobCardId/findings/${pin.id}_$contentHash.$extension';
      await client.storage
          .from(_photoBucket)
          .uploadBinary(
            uploadedPath,
            photoBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      savedPin = pin.copyWith(photoPath: uploadedPath);
    }
    try {
      await client.from('condition_findings').upsert({
        'id': savedPin.id,
        'workshop_id': workshopId,
        'job_card_id': jobCardId,
        'area': savedPin.view.name,
        'normalized_x': savedPin.normalizedX,
        'normalized_y': savedPin.normalizedY,
        'finding_type': savedPin.type.name,
        'severity': savedPin.severity.name,
        'note': savedPin.note,
        'photo_storage_path': savedPin.photoPath,
        'created_at': savedPin.createdAt.toUtc().toIso8601String(),
      }, onConflict: 'job_card_id,id');
    } catch (_) {
      var replacementIsReferenced = false;
      if (uploadedPath != null) {
        try {
          final currentRow = await client
              .from('condition_findings')
              .select('photo_storage_path')
              .eq('job_card_id', jobCardId)
              .eq('id', pin.id)
              .maybeSingle();
          replacementIsReferenced =
              currentRow?['photo_storage_path'] == uploadedPath;
        } catch (_) {
          // Keep the uploaded file if the commit state cannot be confirmed.
        }
      }
      if (uploadedPath != null &&
          uploadedPath != previousPath &&
          !replacementIsReferenced) {
        try {
          await client.storage.from(_photoBucket).remove([uploadedPath]);
        } catch (_) {
          // An unreferenced private object can be cleaned later.
        }
      }
      rethrow;
    }
    if (previousPath != null && previousPath != savedPin.photoPath) {
      try {
        await client.storage.from(_photoBucket).remove([previousPath]);
      } catch (_) {
        // The row references the replacement; the old private object can be cleaned later.
      }
    }
    return savedPin;
  }

  @override
  Future<void> deletePin({
    required String jobCardId,
    required int pinId,
  }) async {
    final row = await client
        .from('condition_findings')
        .select('photo_storage_path')
        .eq('job_card_id', jobCardId)
        .eq('id', pinId)
        .maybeSingle();
    await client
        .from('condition_findings')
        .delete()
        .eq('job_card_id', jobCardId)
        .eq('id', pinId);
    final photoPath = row?['photo_storage_path'] as String?;
    if (photoPath != null) {
      try {
        await client.storage.from(_photoBucket).remove([photoPath]);
      } catch (_) {
        // The finding is already deleted; an orphaned private photo is harmless.
      }
    }
  }

  @override
  Future<PreWorkSignOff?> getSignOff(String jobCardId) async {
    final row = await client
        .from('condition_reports')
        .select(
          'customer_name, customer_phone, advisor_name, signed_at, customer_acknowledged, sha256_checksum',
        )
        .eq('job_card_id', jobCardId)
        .maybeSingle();
    if (row == null) return null;
    return PreWorkSignOff(
      customerName: row['customer_name'] as String,
      customerPhone: row['customer_phone'] as String,
      advisorName: row['advisor_name'] as String,
      signedAt: DateTime.parse(row['signed_at'] as String),
      customerAcknowledged: row['customer_acknowledged'] as bool,
      sha256Checksum: row['sha256_checksum'] as String,
    );
  }

  @override
  Future<void> saveSignOff({
    required String jobCardId,
    required PreWorkSignOff signOff,
  }) async {
    final views = await getReviewedViews(jobCardId);
    await client.rpc(
      'record_condition_signoff',
      params: {
        'p_job_card_id': jobCardId,
        'p_reviewed_areas': views.map((v) => v.name).toList(),
        'p_customer_name': signOff.customerName,
        'p_customer_phone': signOff.customerPhone,
        'p_advisor_name': signOff.advisorName,
        'p_customer_acknowledged': signOff.customerAcknowledged,
        'p_signed_at': signOff.signedAt.toUtc().toIso8601String(),
        'p_sha256_checksum': signOff.sha256Checksum,
      },
    );
  }

  @override
  Future<Set<ConditionViewDirection>> getReviewedViews(String jobCardId) async {
    final row = await client
        .from('condition_review_areas')
        .select('reviewed_areas')
        .eq('job_card_id', jobCardId)
        .maybeSingle();
    if (row == null) return {};
    final areas = (row['reviewed_areas'] as List<dynamic>).cast<String>();
    return areas
        .map(
          (name) =>
              ConditionViewDirection.values.firstWhere((v) => v.name == name),
        )
        .toSet();
  }

  @override
  Future<void> saveReviewedViews(
    String jobCardId,
    Set<ConditionViewDirection> views,
  ) async {
    final workshopId = await _workshopId();
    await client.from('condition_review_areas').upsert({
      'workshop_id': workshopId,
      'job_card_id': jobCardId,
      'reviewed_areas': views.map((v) => v.name).toList(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'job_card_id');
  }

  @override
  String? getJobCardStatus(String jobCardId) => null;
}

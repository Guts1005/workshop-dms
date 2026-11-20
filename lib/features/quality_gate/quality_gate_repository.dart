import 'package:supabase_flutter/supabase_flutter.dart';

import 'quality_gate_models.dart';

abstract class QualityGateRepository {
  Future<QualityGateWorkspace> load(String jobCardId);
  Future<String> save({
    required String jobCardId,
    required String inspectorName,
    required bool workCompleted,
    required Map<String, bool> checks,
    required RoadTestResult roadTestResult,
    required String roadTestNote,
    required String notes,
  });
}

class SupabaseQualityGateRepository implements QualityGateRepository {
  SupabaseQualityGateRepository(this.client);

  final SupabaseClient client;

  @override
  Future<QualityGateWorkspace> load(String jobCardId) async {
    final job = await client
        .from('job_cards')
        .select('id, status, vehicle_id')
        .eq('id', jobCardId)
        .single();
    if (job['status'] != 'WORK_IN_PROGRESS') {
      throw StateError('This job is not ready for quality checks.');
    }
    final vehicle = await client
        .from('vehicles')
        .select('registration_number')
        .eq('id', job['vehicle_id'])
        .single();
    return QualityGateWorkspace(
      jobCardId: jobCardId,
      registrationNumber: vehicle['registration_number'] as String,
    );
  }

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
    final result = await client.rpc(
      'record_job_quality_check',
      params: {
        'p_job_card_id': jobCardId,
        'p_inspector_name': inspectorName.trim(),
        'p_work_completed': workCompleted,
        'p_checks': checks,
        'p_road_test_result': roadTestResult.databaseValue,
        'p_road_test_note': roadTestNote.trim(),
        'p_notes': notes.trim(),
      },
    );
    if (result != 'PASSED' && result != 'FAILED') {
      throw StateError('The quality check returned an unknown result.');
    }
    return result as String;
  }
}

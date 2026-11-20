import 'package:supabase_flutter/supabase_flutter.dart';

import 'work_in_progress_models.dart';

abstract class WorkInProgressRepository {
  Future<WorkInProgressWorkspace> load(String jobCardId);
  Future<void> addUpdate({
    required String jobCardId,
    required WorkUpdateType type,
    required String note,
  });
}

class SupabaseWorkInProgressRepository implements WorkInProgressRepository {
  SupabaseWorkInProgressRepository(this.client);

  final SupabaseClient client;

  @override
  Future<WorkInProgressWorkspace> load(String jobCardId) async {
    final job = await client
        .from('job_cards')
        .select('id, status, vehicle_id')
        .eq('id', jobCardId)
        .single();
    if (job['status'] != 'WORK_IN_PROGRESS') {
      throw StateError('This application is not currently being serviced.');
    }
    final vehicle = await client
        .from('vehicles')
        .select('registration_number')
        .eq('id', job['vehicle_id'])
        .single();
    final scopeRows = await client
        .from('job_line_items')
        .select('description, item_type, quantity')
        .eq('job_card_id', jobCardId)
        .eq('approval_status', 'APPROVED')
        .order('created_at');
    final updateRows = await client
        .from('job_work_updates')
        .select('update_type, note, created_by_label, created_at')
        .eq('job_card_id', jobCardId)
        .order('created_at', ascending: false);

    return WorkInProgressWorkspace(
      jobCardId: jobCardId,
      registrationNumber: vehicle['registration_number'] as String,
      scope: scopeRows
          .map(
            (row) => WorkScopeItem(
              description: row['description'] as String,
              itemType: row['item_type'] as String,
              quantity: row['quantity'] as num,
            ),
          )
          .toList(),
      updates: updateRows
          .map(
            (row) => JobWorkUpdate(
              type: WorkUpdateType.fromDatabase(row['update_type'] as String),
              note: row['note'] as String,
              createdBy: row['created_by_label'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> addUpdate({
    required String jobCardId,
    required WorkUpdateType type,
    required String note,
  }) async {
    await client.rpc(
      'record_job_work_update',
      params: {
        'p_job_card_id': jobCardId,
        'p_update_type': type.databaseValue,
        'p_note': note.trim(),
      },
    );
  }
}

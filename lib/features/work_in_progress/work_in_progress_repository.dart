import 'package:supabase_flutter/supabase_flutter.dart';

import 'work_in_progress_models.dart';

abstract class WorkInProgressRepository {
  Future<WorkInProgressWorkspace> load(String jobCardId);
  Future<void> addUpdate({
    required String jobCardId,
    required WorkUpdateType type,
    required String note,
  });
  Future<void> recordPartMovement({
    required String partId,
    required String type,
    required num quantity,
    required String jobCardId,
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
        .select('description, item_type, code, quantity')
        .eq('job_card_id', jobCardId)
        .eq('approval_status', 'APPROVED')
        .order('created_at');
    final partCodes = scopeRows
        .where((row) => row['item_type'] == 'part')
        .map((row) => row['code'] as String)
        .toSet()
        .toList();
    final partRows = partCodes.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('inventory_parts')
              .select('id, sku, on_hand_quantity')
              .eq('active', true)
              .inFilter('sku', partCodes);
    final movementRows = partRows.isEmpty
        ? <Map<String, dynamic>>[]
        : await client
              .from('inventory_movements')
              .select('part_id, quantity_delta')
              .eq('job_card_id', jobCardId);
    final stockBySku = {for (final row in partRows) row['sku'] as String: row};
    final issuedByPart = <String, num>{};
    for (final row in movementRows) {
      final partId = row['part_id'] as String;
      issuedByPart[partId] =
          (issuedByPart[partId] ?? 0) + (row['quantity_delta'] as num);
    }
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
              code: row['code'] as String,
              quantity: row['quantity'] as num,
              inventoryPartId: stockBySku[row['code']]?['id'] as String?,
              stockOnHand:
                  stockBySku[row['code']]?['on_hand_quantity'] as num? ?? 0,
              quantityIssued: stockBySku[row['code']] == null
                  ? 0
                  : issuedByPart[stockBySku[row['code']]!['id']] ?? 0,
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

  @override
  Future<void> recordPartMovement({
    required String partId,
    required String type,
    required num quantity,
    required String jobCardId,
  }) async {
    await client.rpc(
      'record_inventory_movement',
      params: {
        'p_part_id': partId,
        'p_movement_type': type,
        'p_quantity': quantity,
        'p_supplier_id': null,
        'p_job_card_id': jobCardId,
        'p_note': 'Part ${type.toLowerCase()} against approved job',
      },
    );
  }
}

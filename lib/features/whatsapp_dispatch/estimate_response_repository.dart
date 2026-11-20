import 'package:supabase_flutter/supabase_flutter.dart';

import 'estimate_response_models.dart';

abstract class EstimateResponseRepository {
  Future<EstimateResponseWorkspace> getWorkspace(String jobCardId);
  Future<String> recordResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  });
}

class SupabaseEstimateResponseRepository implements EstimateResponseRepository {
  SupabaseEstimateResponseRepository(this.client);

  final SupabaseClient client;

  @override
  Future<EstimateResponseWorkspace> getWorkspace(String jobCardId) async {
    final job = await client
        .from('job_cards')
        .select('id, customer_id, vehicle_id, status')
        .eq('id', jobCardId)
        .single();
    final status = job['status'] as String;
    if (status != 'ESTIMATE_SENT' && status != 'WAITING_APPROVAL') {
      throw StateError('This estimate is not awaiting a customer response.');
    }
    final customer = await client
        .from('customers')
        .select('name, phone, consent_whatsapp')
        .eq('id', job['customer_id'])
        .single();
    final vehicle = await client
        .from('vehicles')
        .select('registration_number')
        .eq('id', job['vehicle_id'])
        .single();
    final rows = await client
        .from('job_line_items')
        .select(
          'id, item_type, description, code, quantity, unit_rate_paise, gst_rate_percent, approval_status, approval_note',
        )
        .eq('job_card_id', jobCardId)
        .order('created_at');
    final items = rows.map((row) {
      final status = row['approval_status'] as String? ?? 'PENDING';
      final decision = EstimateItemDecision.values.firstWhere(
        (value) => value.databaseValue == status,
        orElse: () => EstimateItemDecision.pending,
      );
      return EstimateResponseItem(
        id: row['id'] as String,
        description: row['description'] as String,
        itemType: row['item_type'] as String,
        code: row['code'] as String,
        quantity: row['quantity'] as num,
        unitRatePaise: row['unit_rate_paise'] as int,
        gstRatePercent: row['gst_rate_percent'] as num,
        decision: decision,
        note: row['approval_note'] as String? ?? '',
      );
    }).toList();
    return EstimateResponseWorkspace(
      jobCardId: jobCardId,
      registrationNumber: vehicle['registration_number'] as String,
      customerName: customer['name'] as String,
      customerPhone: customer['phone'] as String,
      whatsappConsent: customer['consent_whatsapp'] as bool? ?? false,
      status: status,
      items: items,
    );
  }

  @override
  Future<String> recordResponse({
    required String jobCardId,
    required String customerName,
    required List<EstimateResponseItem> items,
  }) async {
    final result = await client.rpc(
      'record_estimate_response',
      params: {
        'p_job_card_id': jobCardId,
        'p_customer_name': customerName.trim(),
        'p_decisions': [
          for (final item in items)
            {
              'lineItemId': item.id,
              'decision': item.decision.databaseValue,
              'note': item.note.trim(),
            },
        ],
      },
    );
    if (result is! String) {
      throw StateError('The response was saved without a workflow status.');
    }
    return result;
  }
}

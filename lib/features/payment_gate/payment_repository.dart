import 'package:supabase_flutter/supabase_flutter.dart';

import 'payment_models.dart';

abstract class PaymentRepository {
  Future<PaymentWorkspace> load(String jobCardId);
  Future<void> record({
    required String jobCardId,
    required int amountPaise,
    required PaymentMethod method,
    required String reference,
    required String requestId,
  });
  Future<void> deliver({
    required String jobCardId,
    required String creditOverrideReason,
  });
}

class SupabasePaymentRepository implements PaymentRepository {
  SupabasePaymentRepository(this.client);
  final SupabaseClient client;

  @override
  Future<PaymentWorkspace> load(String jobCardId) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw StateError('Sign in to access payment records.');
    final job = await client
        .from('job_cards')
        .select('id, status, workshop_id, customer_id, vehicle_id')
        .eq('id', jobCardId)
        .single();
    if (job['status'] != 'READY_FOR_PICKUP' && job['status'] != 'DELIVERED') {
      throw StateError('Payment is available after an invoice is issued.');
    }
    final workshopId = job['workshop_id'] as String;
    final invoice = await client
        .from('job_invoices')
        .select('invoice_number, grand_total_paise')
        .eq('job_card_id', jobCardId)
        .single();
    final payments = await client
        .from('job_payments')
        .select(
          'amount_paise, method, reference, received_by_label, created_at',
        )
        .eq('job_card_id', jobCardId)
        .order('created_at');
    final delivery = await client
        .from('job_deliveries')
        .select('delivered_at, credit_override_reason')
        .eq('job_card_id', jobCardId)
        .maybeSingle();
    final membership = await client
        .from('workshop_memberships')
        .select('role')
        .eq('workshop_id', workshopId)
        .eq('user_id', userId)
        .single();
    final vehicle = await client
        .from('vehicles')
        .select('registration_number')
        .eq('id', job['vehicle_id'])
        .single();
    final customer = await client
        .from('customers')
        .select('name')
        .eq('id', job['customer_id'])
        .single();

    return PaymentWorkspace(
      jobCardId: jobCardId,
      registrationNumber: vehicle['registration_number'] as String,
      customerName: customer['name'] as String,
      invoiceNumber: invoice['invoice_number'] as String,
      invoiceTotalPaise: invoice['grand_total_paise'] as int,
      payments: payments.map((row) {
        final method = PaymentMethod.values.firstWhere(
          (value) => value.databaseValue == row['method'],
        );
        return PaymentEntry(
          amountPaise: row['amount_paise'] as int,
          method: method,
          reference: row['reference'] as String? ?? '',
          receivedBy: row['received_by_label'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList(),
      isOwner: membership['role'] == 'owner',
      deliveredAt: delivery == null
          ? null
          : DateTime.parse(delivery['delivered_at'] as String),
      creditOverrideReason: delivery?['credit_override_reason'] as String?,
    );
  }

  @override
  Future<void> record({
    required String jobCardId,
    required int amountPaise,
    required PaymentMethod method,
    required String reference,
    required String requestId,
  }) async {
    await client.rpc(
      'record_job_payment',
      params: {
        'p_job_card_id': jobCardId,
        'p_amount_paise': amountPaise,
        'p_method': method.databaseValue,
        'p_reference': reference.trim(),
        'p_request_id': requestId,
      },
    );
  }

  @override
  Future<void> deliver({
    required String jobCardId,
    required String creditOverrideReason,
  }) async {
    await client.rpc(
      'confirm_job_delivery',
      params: {
        'p_job_card_id': jobCardId,
        'p_credit_override_reason': creditOverrideReason.trim(),
      },
    );
  }
}

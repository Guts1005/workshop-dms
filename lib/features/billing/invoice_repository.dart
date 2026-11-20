import 'package:supabase_flutter/supabase_flutter.dart';

import 'gst_engine.dart';
import 'invoice_models.dart';

abstract class InvoiceRepository {
  Future<InvoiceWorkspace> load(String jobCardId);
  Future<IssuedInvoice> issue({
    required String jobCardId,
    required InvoiceIssueDetails details,
  });
}

class SupabaseInvoiceRepository implements InvoiceRepository {
  SupabaseInvoiceRepository(this.client);

  final SupabaseClient client;

  @override
  Future<InvoiceWorkspace> load(String jobCardId) async {
    final job = await client
        .from('job_cards')
        .select('id, status, workshop_id, customer_id, vehicle_id')
        .eq('id', jobCardId)
        .single();
    if (job['status'] != 'QC_PASSED' && job['status'] != 'READY_FOR_PICKUP') {
      throw StateError(
        'An invoice is available only after quality checks pass.',
      );
    }
    final existingRow = await client
        .from('job_invoices')
        .select('id')
        .eq('job_card_id', jobCardId)
        .maybeSingle();
    final rows = await client
        .from('job_line_items')
        .select(
          'id, item_type, description, code, quantity, unit_rate_paise, gst_rate_percent',
        )
        .eq('job_card_id', jobCardId)
        .eq('approval_status', 'APPROVED')
        .order('created_at');
    final workshop = await client
        .from('workshops')
        .select('name')
        .eq('id', job['workshop_id'])
        .single();
    final customer = await client
        .from('customers')
        .select('name')
        .eq('id', job['customer_id'])
        .single();
    final vehicle = await client
        .from('vehicles')
        .select('registration_number')
        .eq('id', job['vehicle_id'])
        .single();
    final supplierProfile = await client
        .from('workshop_invoice_profiles')
        .select('address, gstin, state_code')
        .eq('workshop_id', job['workshop_id'])
        .maybeSingle();
    final recipientProfile = await client
        .from('customer_invoice_profiles')
        .select('billing_address, gstin, place_of_supply_state_code')
        .eq('workshop_id', job['workshop_id'])
        .eq('customer_id', job['customer_id'])
        .maybeSingle();

    IssuedInvoice? existingInvoice;
    if (existingRow != null) {
      existingInvoice = await _loadIssuedInvoice(existingRow['id'] as String);
    }
    return InvoiceWorkspace(
      jobCardId: jobCardId,
      registrationNumber: vehicle['registration_number'] as String,
      workshopName: workshop['name'] as String,
      customerName: customer['name'] as String,
      items: rows
          .map(
            (row) => InvoiceLineItem(
              id: row['id'] as String,
              type: row['item_type'] == 'labour'
                  ? LineItemType.labour
                  : LineItemType.part,
              description: row['description'] as String,
              code: row['code'] as String,
              quantity: row['quantity'] as num,
              unitRatePaise: row['unit_rate_paise'] as int,
              gstRatePercent: row['gst_rate_percent'] as num,
            ),
          )
          .toList(),
      existingInvoice: existingInvoice,
      savedSupplierAddress: supplierProfile?['address'] as String?,
      savedSupplierGstin: supplierProfile?['gstin'] as String?,
      savedSupplierStateCode: supplierProfile?['state_code'] as String?,
      savedRecipientAddress: recipientProfile?['billing_address'] as String?,
      savedRecipientGstin: recipientProfile?['gstin'] as String?,
      savedPlaceOfSupplyStateCode:
          recipientProfile?['place_of_supply_state_code'] as String?,
    );
  }

  @override
  Future<IssuedInvoice> issue({
    required String jobCardId,
    required InvoiceIssueDetails details,
  }) async {
    final result = await client.rpc(
      'issue_job_invoice',
      params: {
        'p_job_card_id': jobCardId,
        'p_supplier_name': details.supplierName.trim(),
        'p_supplier_address': details.supplierAddress.trim(),
        'p_supplier_gstin': details.supplierGstin.trim().toUpperCase(),
        'p_supplier_state_code': details.supplierStateCode.trim(),
        'p_recipient_address': details.recipientAddress.trim(),
        'p_recipient_gstin': details.recipientGstin.trim().isEmpty
            ? null
            : details.recipientGstin.trim().toUpperCase(),
        'p_place_of_supply_state_code': details.placeOfSupplyStateCode.trim(),
      },
    );
    if (result is! Map) {
      throw StateError('The database did not return the issued invoice.');
    }
    final invoiceId = result['invoice_id'] as String?;
    if (invoiceId == null) {
      throw StateError('The invoice was issued without an invoice ID.');
    }
    return _loadIssuedInvoice(invoiceId);
  }

  Future<IssuedInvoice> _loadIssuedInvoice(String invoiceId) async {
    final invoice = await client
        .from('job_invoices')
        .select(
          'id, invoice_number, issue_date, supplier_name, supplier_address, supplier_gstin, supplier_state_code, recipient_name, recipient_address, recipient_gstin, place_of_supply_state_code, tax_type, total_taxable_paise, cgst_paise, sgst_paise, igst_paise, total_tax_paise, grand_total_paise',
        )
        .eq('id', invoiceId)
        .single();
    final rows = await client
        .from('job_invoice_lines')
        .select(
          'item_type, description, code, quantity, unit_rate_paise, gst_rate_percent, taxable_paise, cgst_paise, sgst_paise, igst_paise, total_paise',
        )
        .eq('invoice_id', invoiceId);
    int amount(String column) => invoice[column] as int;
    return IssuedInvoice(
      id: invoice['id'] as String,
      invoiceNumber: invoice['invoice_number'] as String,
      issueDate: DateTime.parse(invoice['issue_date'] as String),
      supplierName: invoice['supplier_name'] as String,
      supplierAddress: invoice['supplier_address'] as String,
      supplierGstin: invoice['supplier_gstin'] as String,
      supplierStateCode: invoice['supplier_state_code'] as String,
      recipientName: invoice['recipient_name'] as String,
      recipientAddress: invoice['recipient_address'] as String,
      recipientGstin: invoice['recipient_gstin'] as String?,
      placeOfSupplyStateCode: invoice['place_of_supply_state_code'] as String,
      taxType: invoice['tax_type'] as String,
      totalTaxablePaise: amount('total_taxable_paise'),
      cgstPaise: amount('cgst_paise'),
      sgstPaise: amount('sgst_paise'),
      igstPaise: amount('igst_paise'),
      totalTaxPaise: amount('total_tax_paise'),
      grandTotalPaise: amount('grand_total_paise'),
      lines: rows
          .map(
            (row) => InvoiceSnapshotLine(
              itemType: row['item_type'] as String,
              description: row['description'] as String,
              code: row['code'] as String,
              quantity: row['quantity'] as num,
              unitRatePaise: row['unit_rate_paise'] as int,
              gstRatePercent: row['gst_rate_percent'] as num,
              taxablePaise: row['taxable_paise'] as int,
              cgstPaise: row['cgst_paise'] as int,
              sgstPaise: row['sgst_paise'] as int,
              igstPaise: row['igst_paise'] as int,
              totalPaise: row['total_paise'] as int,
            ),
          )
          .toList(),
    );
  }
}

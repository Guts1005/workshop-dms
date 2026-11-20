import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ui_kit/tokens/app_tokens.dart';
import '../../../ui_kit/widgets/sharp_button.dart';
import '../../../ui_kit/widgets/sharp_card.dart';
import '../../../ui_kit/widgets/status_chip.dart';
import '../../billing/gst_engine.dart';
import '../../vehicle/indian_number_plate.dart';
import '../estimate_status.dart';

/// Complete, Production-Grade Job Card & Estimate Builder Screen (Page 5)
/// Matches luxury Rivian + MG i-SMART automotive styling:
/// Luminous canvas, modular Bento grid, SAC 998714 labour billing, HSN automotive parts,
/// integer-paise GST computation, and WhatsApp digital dispatch.
class JobCardScreen extends StatefulWidget {
  final String? jobCardId;
  final String? registrationNumber;

  const JobCardScreen({super.key, this.jobCardId, this.registrationNumber});

  @override
  State<JobCardScreen> createState() => _JobCardScreenState();
}

class _JobCardScreenState extends State<JobCardScreen> {
  late String _regNumber;
  late String _jobCardId;
  bool _isApproved = false;
  bool _isSent = false;
  String _jobStatus = 'RECEIVED';
  String _vehicleDetails = 'Loading vehicle detailsâ€¦';
  String _customerDetails = 'Loading customer detailsâ€¦';
  String _odometerDetails = 'Loading odometerâ€¦';
  String _deliveryDetails = 'Not set';
  bool _loading = true;
  String? _loadError;

  // Pre-loaded realistic automotive labour lines (SAC 998714 - 18% GST)
  final List<InvoiceLineItem> _labourItems = [];

  // Pre-loaded realistic automotive OEM parts lines (HSN Codes - uniform 18% GST effective Sept 2025)
  final List<InvoiceLineItem> _partsItems = [];

  @override
  void initState() {
    super.initState();
    _regNumber = widget.registrationNumber ?? '';
    _jobCardId = widget.jobCardId ?? '';
    if (_jobCardId.isNotEmpty) {
      _loadJobCard();
    } else {
      _loading = false;
      _loadError = 'Open this estimate from an existing application.';
    }
  }

  Future<void> _loadJobCard() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final client = Supabase.instance.client;
      final job = await client
          .from('job_cards')
          .select(
            'id, vehicle_id, customer_id, expected_delivery, intake_odometer_km, status, customer_approved_at',
          )
          .eq('id', _jobCardId)
          .single();
      final vehicle = await client
          .from('vehicles')
          .select('registration_number, make, model')
          .eq('id', job['vehicle_id'])
          .single();
      final customer = await client
          .from('customers')
          .select('name, phone')
          .eq('id', job['customer_id'])
          .single();
      final rows = await client
          .from('job_line_items')
          .select(
            'id, item_type, description, code, quantity, unit_rate_paise, gst_rate_percent',
          )
          .eq('job_card_id', _jobCardId)
          .order('created_at');
      final items = rows
          .map(
            (row) => InvoiceLineItem(
              id: row['id'] as String,
              type: row['item_type'] == 'labour'
                  ? LineItemType.labour
                  : LineItemType.part,
              description: row['description'] as String,
              code: row['code'] as String,
              quantity: (row['quantity'] as num).round(),
              unitRatePaise: row['unit_rate_paise'] as int,
              gstRatePercent: (row['gst_rate_percent'] as num).round(),
            ),
          )
          .toList();
      if (!mounted) return;
      setState(() {
        _regNumber = vehicle['registration_number'] as String;
        _vehicleDetails = '${vehicle['make']} ${vehicle['model']}';
        _customerDetails = '${customer['name']} - ${customer['phone']}';
        _odometerDetails = '${job['intake_odometer_km']} km';
        final date = DateTime.tryParse(
          job['expected_delivery'] as String? ?? '',
        )?.toLocal();
        _deliveryDetails = date == null
            ? 'Not set'
            : DateFormat('dd MMM yyyy, hh:mm a').format(date);
        _isApproved = job['customer_approved_at'] != null;
        _jobStatus = job['status'] as String? ?? 'RECEIVED';
        _isSent =
            _jobStatus == 'ESTIMATE_SENT' ||
            _jobStatus == 'WAITING_APPROVAL' ||
            _isApproved;
        _labourItems
          ..clear()
          ..addAll(items.where((item) => item.type == LineItemType.labour));
        _partsItems
          ..clear()
          ..addAll(items.where((item) => item.type == LineItemType.part));
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'This application could not load. Check your connection and retry.';
        });
      }
    }
  }

  Future<void> _addLineItem(
    LineItemType type, {
    InvoiceLineItem? existing,
  }) async {
    if (isEstimateLocked(
      jobStatus: _jobStatus,
      customerApproved: _isApproved,
    )) {
      return;
    }
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final code = TextEditingController(
      text: existing?.code ?? (type == LineItemType.labour ? '998714' : ''),
    );
    final quantity = TextEditingController(
      text: existing?.quantity.toString() ?? '1',
    );
    final rate = TextEditingController(
      text: existing == null
          ? ''
          : (existing.unitRatePaise / 100).toStringAsFixed(2),
    );
    final formKey = GlobalKey<FormState>();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${existing == null ? 'Add' : 'Edit'} ${type == LineItemType.labour ? 'labour' : 'part'}',
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: description,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Enter a description'
                    : null,
              ),
              TextFormField(
                controller: code,
                decoration: InputDecoration(
                  labelText: type == LineItemType.labour
                      ? 'SAC code'
                      : 'HSN code',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter the code' : null,
              ),
              TextFormField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
                validator: (v) => (int.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive quantity'
                    : null,
              ),
              TextFormField(
                controller: rate,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Unit price (â‚¹)',
                ),
                validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                    ? 'Enter a positive price'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(existing == null ? 'Add' : 'Save changes'),
          ),
        ],
      ),
    );
    final itemDescription = description.text.trim();
    final itemCode = code.text.trim();
    final itemQuantity = int.tryParse(quantity.text.trim());
    final itemRate = double.tryParse(rate.text.trim());
    description.dispose();
    code.dispose();
    quantity.dispose();
    rate.dispose();
    if (save != true || !mounted) return;
    try {
      final payload = {
        'description': itemDescription,
        'code': itemCode,
        'quantity': itemQuantity,
        'unit_rate_paise': (itemRate! * 100).round(),
        'gst_rate_percent': 18,
      };
      if (existing == null) {
        await Supabase.instance.client.from('job_line_items').insert({
          'workshop_id': await _workshopId(),
          'job_card_id': _jobCardId,
          'item_type': type == LineItemType.labour ? 'labour' : 'part',
          ...payload,
        });
      } else {
        await Supabase.instance.client
            .from('job_line_items')
            .update(payload)
            .eq('id', existing.id)
            .eq('job_card_id', _jobCardId);
      }
      await _loadJobCard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save this estimate item: $error')),
        );
      }
    }
  }

  Future<void> _deleteLineItem(InvoiceLineItem item) async {
    if (isEstimateLocked(
      jobStatus: _jobStatus,
      customerApproved: _isApproved,
    )) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove estimate item?'),
        content: Text(
          'Remove “${item.description}” from the revised estimate?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep item'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await Supabase.instance.client
          .from('job_line_items')
          .delete()
          .eq('id', item.id)
          .eq('job_card_id', _jobCardId);
      await _loadJobCard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove estimate item: $error')),
        );
      }
    }
  }

  Future<String> _workshopId() async =>
      (await Supabase.instance.client
              .from('workshop_memberships')
              .select('workshop_id')
              .eq('user_id', Supabase.instance.client.auth.currentUser!.id)
              .single())['workshop_id']
          as String;

  Future<void> _markEstimateSent() async {
    if (_computeSummary().grandTotalPaise <= 0 || _isSent || _isApproved) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark estimate as sent?'),
        content: const Text(
          'Confirm that you shared this estimate with the customer. The estimate will be locked while you wait for their response.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm sent'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final client = Supabase.instance.client;
      await client.rpc(
        'mark_estimate_sent',
        params: {'p_job_card_id': _jobCardId},
      );
      if (mounted) {
        setState(() {
          _isSent = true;
          _jobStatus = 'ESTIMATE_SENT';
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mark estimate as sent: $error')),
        );
      }
    }
  }

  InvoiceTaxSummary _computeSummary() {
    final allItems = [..._labourItems, ..._partsItems];
    return AutomotiveGstEngine.calculate(
      items: allItems,
      isIntraState: true,
      totalPaidPaise: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900.0;
    final summary = _computeSummary();
    final grandTotalRupees = (summary.grandTotalPaise / 100).toStringAsFixed(2);
    final taxableLabourRupees = (summary.totalLabourTaxablePaise / 100)
        .toStringAsFixed(2);
    final taxablePartsRupees = (summary.totalPartsTaxablePaise / 100)
        .toStringAsFixed(2);
    final cgstRupees = (summary.cgstAmountPaise / 100).toStringAsFixed(2);
    final sgstRupees = (summary.sgstAmountPaise / 100).toStringAsFixed(2);
    final totalGstRupees =
        ((summary.cgstAmountPaise + summary.sgstAmountPaise) / 100)
            .toStringAsFixed(2);

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Header
            _buildStageHeader(),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_loadError != null)
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _jobCardId.isEmpty ? null : _loadJobCard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Scrollable Content Zone (Zero Horizontal Scroll)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 24.0 : 14.0,
                    vertical: 14.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Vehicle & Customer Hero Banner (Rivian + MG Aesthetic)
                          _buildVehicleCustomerHeroCard(),
                          const SizedBox(height: 14.0),

                          // Main Bento Workspace: 2-Column Split on Desktop, Stack on Mobile
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Labour Operations & Parts Catalogue (Flex 7)
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      _buildLabourModule(),
                                      const SizedBox(height: 14.0),
                                      _buildPartsModule(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16.0),

                                // Right Column: GST Calculation Summary & Actions (Flex 5)
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    children: [
                                      _buildGstSummaryBentoCard(
                                        taxableLabour: taxableLabourRupees,
                                        taxableParts: taxablePartsRupees,
                                        cgst: cgstRupees,
                                        sgst: sgstRupees,
                                        totalGst: totalGstRupees,
                                        grandTotal: grandTotalRupees,
                                      ),
                                      const SizedBox(height: 14.0),
                                      _buildQuickActionsCard(grandTotalRupees),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildLabourModule(),
                            const SizedBox(height: 14.0),
                            _buildPartsModule(),
                            const SizedBox(height: 14.0),
                            _buildGstSummaryBentoCard(
                              taxableLabour: taxableLabourRupees,
                              taxableParts: taxablePartsRupees,
                              cgst: cgstRupees,
                              sgst: sgstRupees,
                              totalGst: totalGstRupees,
                              grandTotal: grandTotalRupees,
                            ),
                            const SizedBox(height: 14.0),
                            _buildQuickActionsCard(grandTotalRupees),
                            const SizedBox(height: 20.0),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Top Stage Header Bar
  Widget _buildStageHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppTokens.raised,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: AppTokens.cardRadius,
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    context.go('/bays');
                  }
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: Icon(
                    Icons.arrow_back,
                    size: 20.0,
                    color: AppTokens.inverse,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7.0,
                  vertical: 3.0,
                ),
                decoration: const BoxDecoration(
                  color: AppTokens.brandRed,
                  borderRadius: AppTokens.inputRadius,
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: AppTokens.raised,
                  size: 14.0,
                ),
              ),
              const SizedBox(width: 8.0),
              Text(
                'JOB CARD & ESTIMATE',
                style: GoogleFonts.inter(
                  color: AppTokens.textPrimary,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          StatusChip(
            label: estimateStatusLabel(
              jobStatus: _jobStatus,
              hasEstimateItems:
                  _labourItems.isNotEmpty || _partsItems.isNotEmpty,
              customerApproved: _isApproved,
            ),
            icon: _isApproved || _isSent
                ? Icons.pending_outlined
                : Icons.edit_note_outlined,
            type: _isApproved ? StatusType.ok : StatusType.neutral,
          ),
        ],
      ),
    );
  }

  /// Vehicle & Customer Hero Card
  Widget _buildVehicleCustomerHeroCard() {
    final isNarrow = MediaQuery.of(context).size.width < 700.0;
    final registrationPlate = IndianNumberPlate(
      registrationNumber: _regNumber,
      height: 44.0,
    );
    final contextDetails = Wrap(
      spacing: 20.0,
      runSpacing: 12.0,
      children: [
        _buildInfoColumn('MAKE / MODEL', _vehicleDetails),
        _buildInfoColumn('CUSTOMER', _customerDetails),
        _buildInfoColumn('INTAKE ODOMETER', _odometerDetails),
        _buildInfoColumn('TARGET DELIVERY', _deliveryDetails),
      ],
    );

    return SharpCard(
      title: 'VEHICLE & CUSTOMER',
      titleTrailing: Text(
        _jobCardId,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w900,
          fontSize: 11.5,
          color: AppTokens.brandRed,
        ),
      ),
      padding: const EdgeInsets.all(16.0),
      child: isNarrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                registrationPlate,
                const SizedBox(height: 16.0),
                contextDetails,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                registrationPlate,
                const SizedBox(width: 16.0),
                Expanded(child: contextDetails),
              ],
            ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: AppTokens.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Labour Charges Bento Module
  Widget _buildLabourModule() {
    return SharpCard(
      title: 'LABOUR & DIAGNOSTICS',
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: <Widget>[
          ..._labourItems.map((item) {
            final amt = (item.taxableAmountPaise / 100).toStringAsFixed(2);
            final gstAmt = (item.gstAmountPaise / 100).toStringAsFixed(2);
            final canEdit = !isEstimateLocked(
              jobStatus: _jobStatus,
              customerApproved: _isApproved,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: AppTokens.cardRadius,
                border: Border.all(color: AppTokens.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: const BoxDecoration(
                      color: AppTokens.surfaceSubtle,
                      borderRadius: AppTokens.cardRadius,
                    ),
                    child: const Icon(
                      Icons.build_outlined,
                      color: AppTokens.brandRed,
                      size: 16.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: GoogleFonts.inter(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.code} â€¢ Qty: ${item.quantity} hr â€¢ GST Rate: ${item.gstRatePercent}% (+â‚¹$gstAmt)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹$amt',
                            style: GoogleFonts.inter(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.textPrimary,
                            ),
                          ),
                          if (canEdit)
                            IconButton(
                              tooltip: 'Remove ${item.description}',
                              onPressed: () => _deleteLineItem(item),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                        ],
                      ),
                      if (canEdit) ...[
                        IconButton(
                          tooltip: 'Edit ${item.description}',
                          onPressed: () =>
                              _addLineItem(LineItemType.labour, existing: item),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Remove ${item.description}',
                          onPressed: () => _deleteLineItem(item),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_labourItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No labour has been added to this estimate.'),
            ),
          if (!isEstimateLocked(
            jobStatus: _jobStatus,
            customerApproved: _isApproved,
          ))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addLineItem(LineItemType.labour),
                icon: const Icon(Icons.add),
                label: const Text('Add labour'),
              ),
            ),
        ],
      ),
    );
  }

  /// Spare Parts & Consumables Bento Module
  Widget _buildPartsModule() {
    return SharpCard(
      title: 'PARTS & CONSUMABLES',
      padding: const EdgeInsets.all(14.0),
      child: Column(
        children: <Widget>[
          ..._partsItems.map((item) {
            final amt = (item.taxableAmountPaise / 100).toStringAsFixed(2);
            final gstAmt = (item.gstAmountPaise / 100).toStringAsFixed(2);
            final canEdit = !isEstimateLocked(
              jobStatus: _jobStatus,
              customerApproved: _isApproved,
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: AppTokens.cardRadius,
                border: Border.all(color: AppTokens.borderLight),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32.0,
                    height: 32.0,
                    decoration: const BoxDecoration(
                      color: AppTokens.surfaceSubtle,
                      borderRadius: AppTokens.cardRadius,
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      color: AppTokens.brandRed,
                      size: 16.0,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.description,
                          style: GoogleFonts.inter(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: AppTokens.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.code} â€¢ Units: ${item.quantity} â€¢ GST Rate: ${item.gstRatePercent}% (+â‚¹$gstAmt)',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹$amt',
                            style: GoogleFonts.inter(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.textPrimary,
                            ),
                          ),
                          if (canEdit)
                            IconButton(
                              tooltip: 'Remove ${item.description}',
                              onPressed: () => _deleteLineItem(item),
                              icon: const Icon(Icons.delete_outline, size: 18),
                            ),
                        ],
                      ),
                      if (canEdit) ...[
                        IconButton(
                          tooltip: 'Edit ${item.description}',
                          onPressed: () =>
                              _addLineItem(LineItemType.part, existing: item),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        IconButton(
                          tooltip: 'Remove ${item.description}',
                          onPressed: () => _deleteLineItem(item),
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_partsItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No parts have been added to this estimate.'),
            ),
          if (!isEstimateLocked(
            jobStatus: _jobStatus,
            customerApproved: _isApproved,
          ))
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _addLineItem(LineItemType.part),
                icon: const Icon(Icons.add),
                label: const Text('Add part'),
              ),
            ),
        ],
      ),
    );
  }

  /// GST Calculation Summary Bento Card
  Widget _buildGstSummaryBentoCard({
    required String taxableLabour,
    required String taxableParts,
    required String cgst,
    required String sgst,
    required String totalGst,
    required String grandTotal,
  }) {
    return SharpCard(
      title: 'TAXES & TOTAL',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildSummaryRow('Taxable Labour (SAC 998714)', 'â‚¹$taxableLabour'),
          _buildSummaryRow('Taxable Spare Parts (HSN)', 'â‚¹$taxableParts'),
          const Divider(height: 16.0, color: AppTokens.borderLight),
          _buildSummaryRow('Central GST (CGST)', 'â‚¹$cgst'),
          _buildSummaryRow('State GST (SGST / UTGST)', 'â‚¹$sgst'),
          _buildSummaryRow(
            'Total Automotive GST',
            'â‚¹$totalGst',
            isEmphasized: true,
          ),
          const Divider(
            height: 20.0,
            color: AppTokens.borderLight,
            thickness: 1.2,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ESTIMATE TOTAL (INCL. GST)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.textPrimary,
                ),
              ),
              Text(
                'â‚¹$grandTotal',
                style: GoogleFonts.inter(
                  fontSize: 22.0,
                  fontWeight: FontWeight.w900,
                  color: AppTokens.brandRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isEmphasized = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: isEmphasized ? FontWeight.bold : FontWeight.w500,
              color: isEmphasized
                  ? AppTokens.textPrimary
                  : AppTokens.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.0,
              fontWeight: isEmphasized ? FontWeight.w800 : FontWeight.w700,
              color: isEmphasized
                  ? AppTokens.textPrimary
                  : AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Action Buttons Card
  Widget _buildQuickActionsCard(String grandTotalRupees) {
    return SharpCard(
      title: 'CUSTOMER REVIEW',
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Copy the summary so the user chooses where to share it.
          SharpButton(
            label: 'COPY ESTIMATE SUMMARY',
            icon: Icons.copy_rounded,
            borderRadius: AppTokens.cardRadius,
            onPressed: grandTotalRupees == '0.00'
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            'Workshop estimate for $_regNumber\n'
                            'Vehicle: $_vehicleDetails\n'
                            'Total including GST: â‚¹$grandTotalRupees\n'
                            'Please review and reply with approval or questions.',
                      ),
                    );
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppTokens.green,
                        content: Text(
                          'Estimate summary copied. Paste it into your customer message.',
                        ),
                      ),
                    );
                  },
          ),
          const SizedBox(height: 10.0),

          // Mark sent only after the customer has received the current estimate.
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 13.0),
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.cardRadius,
              ),
              side: const BorderSide(color: AppTokens.borderSolid, width: 1.2),
            ),
            icon: const Icon(
              Icons.send_outlined,
              color: AppTokens.textPrimary,
              size: 18.0,
            ),
            label: Text(
              _isApproved
                  ? 'CUSTOMER APPROVAL RECORDED'
                  : _isSent
                  ? 'WAITING FOR CUSTOMER RESPONSE'
                  : isEstimateLocked(
                      jobStatus: _jobStatus,
                      customerApproved: _isApproved,
                    )
                  ? 'ESTIMATE LOCKED'
                  : 'MARK ESTIMATE AS SENT',
              style: GoogleFonts.inter(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppTokens.textPrimary,
              ),
            ),
            onPressed:
                isEstimateLocked(
                      jobStatus: _jobStatus,
                      customerApproved: _isApproved,
                    ) ||
                    _computeSummary().grandTotalPaise == 0
                ? null
                : _markEstimateSent,
          ),
          const SizedBox(height: 8),
          Text(
            _isSent ? 'Estimate items are locked until the customer responds.' : 'Copy the summary, share it with the customer, then mark it as sent.',
            style: AppTokens.fontBody(
              fontSize: 13,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 10.0),

          // Proceed to Applications button
          SharpButton(
            label: 'RETURN TO APPLICATIONS',
            icon: Icons.arrow_forward,
            borderRadius: AppTokens.buttonRadius,
            onPressed: () {
              GoRouter.maybeOf(context)?.go('/applications');
            },
          ),
        ],
      ),
    );
  }
}

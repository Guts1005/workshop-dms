import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'gst_engine.dart';
import 'invoice_controller.dart';
import 'invoice_models.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({required this.jobCardId, super.key});

  final String? jobCardId;

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierName = TextEditingController();
  final _supplierAddress = TextEditingController();
  final _supplierGstin = TextEditingController();
  final _supplierState = TextEditingController();
  final _recipientAddress = TextEditingController();
  final _recipientGstin = TextEditingController();
  final _placeOfSupplyState = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.jobCardId?.trim() ?? '';
      if (id.isNotEmpty) ref.read(invoiceControllerProvider.notifier).load(id);
    });
  }

  @override
  void dispose() {
    _supplierName.dispose();
    _supplierAddress.dispose();
    _supplierGstin.dispose();
    _supplierState.dispose();
    _recipientAddress.dispose();
    _recipientGstin.dispose();
    _placeOfSupplyState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoiceControllerProvider);
    final controller = ref.read(invoiceControllerProvider.notifier);
    final workspace = state.workspace;
    if (workspace != null && !_seeded) _seed(workspace);

    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'GST invoice',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back to applications',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: widget.jobCardId?.trim().isNotEmpty != true
          ? _message(
              'Open invoice preparation from an application that passed QC.',
            )
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : workspace == null
          ? _error(
              state.errorMessage,
              onRetry: () => controller.load(widget.jobCardId!),
            )
          : state.issuedInvoice != null
          ? _issuedView(state.issuedInvoice!)
          : _draftView(
              workspace,
              state.errorMessage,
              state.issuing,
              controller,
            ),
    );
  }

  void _seed(InvoiceWorkspace workspace) {
    _seeded = true;
    _supplierName.text = workspace.workshopName;
    _supplierAddress.text = workspace.savedSupplierAddress ?? '';
    _supplierGstin.text = workspace.savedSupplierGstin ?? '';
    _supplierState.text = workspace.savedSupplierStateCode ?? '';
    _recipientAddress.text = workspace.savedRecipientAddress ?? '';
    _recipientGstin.text = workspace.savedRecipientGstin ?? '';
    _placeOfSupplyState.text =
        workspace.savedPlaceOfSupplyStateCode ??
        workspace.savedSupplierStateCode ??
        '';
  }

  Widget _draftView(
    InvoiceWorkspace workspace,
    String? error,
    bool issuing,
    InvoiceController controller,
  ) {
    final ratePreview =
        _validState(_supplierState.text) &&
        _validState(_placeOfSupplyState.text);
    final tax = ratePreview
        ? AutomotiveGstEngine.calculate(
            items: workspace.items,
            isIntraState:
                _supplierState.text.trim() == _placeOfSupplyState.text.trim(),
            totalPaidPaise: 0,
          )
        : null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              _vehicleCard(
                workspace.registrationNumber,
                workspace.customerName,
              ),
              const SizedBox(height: 12),
              _infoCard(
                'Invoice totals use the approved estimate snapshot. Confirm the tax code, rate, and place of supply with your accountant before issuing.',
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 20),
              _sectionTitle('SUPPLIER DETAILS'),
              const SizedBox(height: 8),
              _input(
                controller: _supplierName,
                label: 'Legal business name',
                validator: (value) =>
                    _required(value, 'Enter the supplier name.'),
              ),
              const SizedBox(height: 10),
              _input(
                controller: _supplierAddress,
                label: 'Registered address',
                maxLines: 3,
                validator: (value) => _required(
                  value,
                  'Enter the supplier address.',
                  minLength: 5,
                ),
              ),
              const SizedBox(height: 10),
              _input(
                controller: _supplierGstin,
                label: 'Supplier GSTIN',
                capitalization: TextCapitalization.characters,
                validator: (value) => _validGstin(value, isRequired: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _input(
                controller: _supplierState,
                label: 'Supplier state code (2 digits)',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (value) =>
                    _validState(value) &&
                        _supplierGstin.text.trim().toUpperCase().startsWith(
                          value!.trim(),
                        )
                    ? null
                    : 'State code must match the GSTIN prefix.',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              _sectionTitle('CUSTOMER DETAILS'),
              const SizedBox(height: 8),
              _readOnlyField('Customer', workspace.customerName),
              const SizedBox(height: 10),
              _input(
                controller: _recipientAddress,
                label: 'Billing address (include state and PIN)',
                maxLines: 3,
                validator: (value) => _required(
                  value,
                  'Enter the recipient address.',
                  minLength: 5,
                ),
              ),
              const SizedBox(height: 10),
              _input(
                controller: _recipientGstin,
                label: 'Recipient GSTIN (optional)',
                capitalization: TextCapitalization.characters,
                validator: (value) => _validGstin(value, isRequired: false),
              ),
              const SizedBox(height: 10),
              _input(
                controller: _placeOfSupplyState,
                label: 'Place of supply state code (2 digits)',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: (value) => _validState(value)
                    ? null
                    : 'Enter the two-digit place-of-supply state code.',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              if (ratePreview)
                _infoCard(
                  _supplierState.text.trim() == _placeOfSupplyState.text.trim()
                      ? 'Intra-state supply · CGST + SGST'
                      : 'Inter-state supply · IGST',
                  icon: Icons.account_balance_outlined,
                ),
              const SizedBox(height: 18),
              _sectionTitle('APPROVED ESTIMATE'),
              const SizedBox(height: 8),
              if (workspace.items.isEmpty)
                _infoCard(
                  'No approved estimate items are available to invoice.',
                )
              else
                ...workspace.items.map(_estimateLine),
              if (tax != null) ...[
                _summaryCard(
                  taxable: tax.totalTaxablePaise,
                  cgst: tax.cgstAmountPaise,
                  sgst: tax.sgstAmountPaise,
                  igst: tax.igstAmountPaise,
                  total: tax.grandTotalPaise,
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                _infoCard(error, icon: Icons.error_outline, error: true),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: issuing || workspace.items.isEmpty
                    ? null
                    : () => _confirmAndIssue(controller),
                icon: issuing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long_outlined),
                label: Text(
                  issuing ? 'Issuing…' : 'Review and issue tax invoice',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: AppTokens.inverse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndIssue(InvoiceController controller) async {
    if (!_formKey.currentState!.validate()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Issue this tax invoice?'),
        content: const Text(
          'This creates a permanent invoice number and locks the invoice snapshot for this job.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review details'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Issue invoice'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await controller.issue(
      InvoiceIssueDetails(
        supplierName: _supplierName.text,
        supplierAddress: _supplierAddress.text,
        supplierGstin: _supplierGstin.text,
        supplierStateCode: _supplierState.text,
        recipientAddress: _recipientAddress.text,
        recipientGstin: _recipientGstin.text,
        placeOfSupplyStateCode: _placeOfSupplyState.text,
      ),
    );
  }

  Widget _issuedView(IssuedInvoice invoice) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _infoCard(
            'Invoice ${invoice.invoiceNumber} issued',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 10),
          _vehicleCard(
            '',
            invoice.recipientName,
            statusLabel: 'INVOICE ISSUED',
          ),
          for (final line in invoice.lines) _issuedLine(line),
          const SizedBox(height: 10),
          _summaryCard(
            taxable: invoice.totalTaxablePaise,
            cgst: invoice.cgstPaise,
            sgst: invoice.sgstPaise,
            igst: invoice.igstPaise,
            total: invoice.grandTotalPaise,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _printInvoice(invoice),
            icon: const Icon(Icons.print_outlined),
            label: const Text('Print / save invoice PDF'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppTokens.inverse,
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.go(
              '/payment-gate',
              extra: {'jobCardId': widget.jobCardId},
            ),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Continue to payment'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _printInvoice(IssuedInvoice invoice) async {
    final document = _makePdf(invoice);
    await Printing.layoutPdf(onLayout: (_) => document.save());
  }

  pw.Document _makePdf(IssuedInvoice invoice) {
    final pdf = pw.Document();
    String currency(int paise) => 'INR ${(paise / 100).toStringAsFixed(2)}';
    final splitTaxHeaders = invoice.intraState
        ? const ['CGST', 'SGST/UTGST']
        : const ['IGST'];
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(invoice.invoiceNumber),
            pw.Text('Page ${context.pageNumber} of ${context.pagesCount}'),
          ],
        ),
        build: (context) => [
          pw.Text(
            'TAX INVOICE',
            style: const pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            invoice.supplierName,
            style: const pw.TextStyle(
              fontSize: 15,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(invoice.supplierAddress),
          pw.Text(
            'GSTIN: ${invoice.supplierGstin} · State code: ${invoice.supplierStateCode}',
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'BILL TO',
                      style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(invoice.recipientName),
                    pw.Text(invoice.recipientAddress),
                    if (invoice.recipientGstin != null)
                      pw.Text('GSTIN: ${invoice.recipientGstin}'),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Invoice: ${invoice.invoiceNumber}'),
                  pw.Text(
                    'Date: ${DateFormat('dd MMM yyyy').format(invoice.issueDate)}',
                  ),
                  pw.Text('Place of supply: ${invoice.placeOfSupplyStateCode}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: [
              'Description',
              'HSN/SAC',
              'Qty',
              'Unit rate',
              'Taxable',
              'GST rate',
              ...splitTaxHeaders,
              'Total',
            ],
            data: [
              for (final line in invoice.lines)
                [
                  line.description,
                  line.code,
                  line.quantity.toString(),
                  currency(line.unitRatePaise),
                  currency(line.taxablePaise),
                  '${line.gstRatePercent}%',
                  if (invoice.intraState) ...[
                    currency(line.cgstPaise),
                    currency(line.sgstPaise),
                  ] else
                    currency(line.igstPaise),
                  currency(line.totalPaise),
                ],
            ],
            headerStyle: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignments: {
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
              8: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 14),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Taxable value: ${currency(invoice.totalTaxablePaise)}',
                ),
                if (invoice.intraState) ...[
                  pw.Text('CGST: ${currency(invoice.cgstPaise)}'),
                  pw.Text('SGST/UTGST: ${currency(invoice.sgstPaise)}'),
                ] else
                  pw.Text('IGST: ${currency(invoice.igstPaise)}'),
                pw.Text('Total tax: ${currency(invoice.totalTaxPaise)}'),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Invoice total: ${currency(invoice.grandTotalPaise)}',
                  style: const pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 28),
          pw.Text('Authorised signatory'),
        ],
      ),
    );
    return pdf;
  }

  Widget _vehicleCard(
    String plate,
    String customer, {
    String statusLabel = 'QC PASSED',
  }) => _card(
    Row(
      children: [
        const Icon(Icons.receipt_long_outlined, color: AppTokens.brandRed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (plate.isNotEmpty)
                Text(
                  plate,
                  style: AppTokens.fontMonospace(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              Text(customer, style: AppTokens.fontBody(fontSize: 14)),
            ],
          ),
        ),
        Chip(label: Text(statusLabel)),
      ],
    ),
  );

  Widget _issuedLine(InvoiceSnapshotLine line) => _card(
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.description,
                style: AppTokens.fontBody(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                '${line.code} | Qty ${line.quantity} | GST ${line.gstRatePercent}%',
                style: AppTokens.fontBody(
                  fontSize: 12,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          _rupees(line.totalPaise),
          style: AppTokens.fontMonospace(fontSize: 14),
        ),
      ],
    ),
  );

  Widget _estimateLine(InvoiceLineItem item) => _card(
    Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.description,
                style: AppTokens.fontBody(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 3),
              Text(
                '${item.code} · Qty ${item.quantity} · GST ${item.gstRatePercent}%',
                style: AppTokens.fontBody(
                  fontSize: 12,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          _rupees(item.totalAmountPaise),
          style: AppTokens.fontMonospace(fontSize: 14),
        ),
      ],
    ),
  );

  Widget _summaryCard({
    required int taxable,
    required int cgst,
    required int sgst,
    required int igst,
    required int total,
  }) => _card(
    Column(
      children: [
        _summaryRow('Taxable amount', taxable),
        if (cgst > 0) _summaryRow('CGST', cgst),
        if (sgst > 0) _summaryRow('SGST / UTGST', sgst),
        if (igst > 0) _summaryRow('IGST', igst),
        const Divider(),
        _summaryRow('Invoice total', total, strong: true),
      ],
    ),
  );

  Widget _summaryRow(String label, int paise, {bool strong = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTokens.fontBody(
              fontWeight: strong ? FontWeight.w800 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          _rupees(paise),
          style: AppTokens.fontMonospace(
            fontWeight: strong ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _input({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.sentences,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLines == 1 ? 200 : 500,
    keyboardType: keyboardType,
    textCapitalization: capitalization,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: AppTokens.raised,
    ),
    validator: validator,
    onChanged: onChanged ?? (_) {},
  );

  Widget _readOnlyField(String label, String value) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: AppTokens.raised,
    ),
    child: Text(value),
  );

  Widget _sectionTitle(String text) => Text(
    text,
    style: AppTokens.fontMonospace(fontSize: 12, fontWeight: FontWeight.w800),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: child,
  );

  Widget _infoCard(
    String text, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) => _card(
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: error ? AppTokens.brandRed : AppTokens.textSecondary),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  Widget _error(String? message, {required VoidCallback onRetry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Could not load the invoice.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );

  String? _required(String? value, String message, {int minLength = 2}) =>
      (value?.trim().length ?? 0) < minLength ? message : null;

  String? _validGstin(String? value, {required bool isRequired}) {
    final gstin = value?.trim().toUpperCase() ?? '';
    if (gstin.isEmpty && !isRequired) return null;
    return RegExp(r'^[A-Z0-9]{15}$').hasMatch(gstin)
        ? null
        : isRequired
        ? 'Enter the 15-character supplier GSTIN.'
        : 'Enter a valid 15-character GSTIN or leave it blank.';
  }

  bool _validState(String? value) =>
      RegExp(r'^\d{2}$').hasMatch(value?.trim() ?? '');

  String _rupees(int paise) => '₹${(paise / 100).toStringAsFixed(2)}';
}

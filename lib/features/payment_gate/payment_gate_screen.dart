import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'payment_controller.dart';
import 'payment_models.dart';

class PaymentGateScreen extends ConsumerStatefulWidget {
  const PaymentGateScreen({required this.jobCardId, super.key});
  final String? jobCardId;

  @override
  ConsumerState<PaymentGateScreen> createState() => _PaymentGateScreenState();
}

class _PaymentGateScreenState extends ConsumerState<PaymentGateScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  PaymentMethod _method = PaymentMethod.upi;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.jobCardId?.trim() ?? '';
      if (id.isNotEmpty) ref.read(paymentControllerProvider.notifier).load(id);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentControllerProvider);
    final controller = ref.read(paymentControllerProvider.notifier);
    final workspace = state.workspace;
    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text('Payment & handover'),
        leading: IconButton(
          tooltip: 'Back to applications',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: widget.jobCardId?.trim().isNotEmpty != true
          ? _message('Open payment from an invoiced application.')
          : state.loading && workspace == null
          ? const Center(child: CircularProgressIndicator())
          : workspace == null
          ? _error(state.errorMessage, () => controller.load(widget.jobCardId!))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _card(
                      Row(
                        children: [
                          const Icon(Icons.directions_car_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  workspace.registrationNumber,
                                  style: AppTokens.fontMonospace(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${workspace.customerName}  ·  ${workspace.invoiceNumber}',
                                  style: AppTokens.fontBody(
                                    color: AppTokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (workspace.delivered)
                            const Chip(label: Text('HANDED OVER'))
                          else
                            const Chip(label: Text('AWAITING PICKUP')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      Column(
                        children: [
                          _amountRow(
                            'Invoice total',
                            workspace.invoiceTotalPaise,
                          ),
                          const SizedBox(height: 8),
                          _amountRow('Payments received', workspace.paidPaise),
                          const Divider(height: 24),
                          _amountRow(
                            'Balance due',
                            workspace.balancePaise,
                            strong: true,
                            color: workspace.balancePaise == 0
                                ? AppTokens.green
                                : AppTokens.brandRed,
                          ),
                        ],
                      ),
                    ),
                    if (workspace.balancePaise > 0) ...[
                      const SizedBox(height: 14),
                      _section('RECORD A PAYMENT'),
                      const SizedBox(height: 8),
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Amount received (₹)',
                                border: OutlineInputBorder(),
                                prefixText: '₹ ',
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<PaymentMethod>(
                              value: _method,
                              decoration: const InputDecoration(
                                labelText: 'Payment method',
                                border: OutlineInputBorder(),
                              ),
                              items: PaymentMethod.values
                                  .map(
                                    (value) => DropdownMenuItem(
                                      value: value,
                                      child: Text(value.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: state.saving
                                  ? null
                                  : (value) => setState(
                                      () => _method = value ?? _method,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _referenceController,
                              maxLength: 160,
                              decoration: const InputDecoration(
                                labelText: 'Transaction reference (optional)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FilledButton.icon(
                              onPressed: state.saving
                                  ? null
                                  : () async {
                                      final saved = await controller.record(
                                        amountText: _amountController.text,
                                        method: _method,
                                        reference: _referenceController.text,
                                      );
                                      if (saved && mounted) {
                                        _amountController.clear();
                                        _referenceController.clear();
                                      }
                                    },
                              icon: state.saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.add_card),
                              label: Text(
                                state.saving ? 'Saving…' : 'Record payment',
                              ),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(50),
                                backgroundColor: AppTokens.inverse,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _section('PAYMENT HISTORY'),
                    const SizedBox(height: 8),
                    if (workspace.payments.isEmpty)
                      _card(const Text('No payments recorded yet.'))
                    else
                      for (final payment in workspace.payments)
                        _card(
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(
                              formatPaymentRupees(payment.amountPaise),
                            ),
                            subtitle: Text(
                              [
                                payment.method.label,
                                if (payment.reference.isNotEmpty)
                                  payment.reference,
                                'by ${payment.receivedBy}',
                                _date(payment.createdAt),
                              ].join(' · '),
                            ),
                          ),
                        ),
                    if (workspace.creditOverrideReason?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      _card(
                        Text(
                          'Owner credit approval: ${workspace.creditOverrideReason}',
                        ),
                      ),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      _notice(state.errorMessage!, error: true),
                    ],
                    if (state.successMessage != null) ...[
                      const SizedBox(height: 10),
                      _notice(state.successMessage!, error: false),
                    ],
                    if (!workspace.delivered) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed:
                            state.saving ||
                                (workspace.balancePaise > 0 &&
                                    !workspace.isOwner)
                            ? null
                            : () => _confirmDelivery(
                                context,
                                controller,
                                workspace,
                              ),
                        icon: const Icon(Icons.key_outlined),
                        label: const Text('Confirm vehicle handover'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: workspace.balancePaise == 0
                              ? AppTokens.inverse
                              : AppTokens.textSecondary,
                        ),
                      ),
                      if (workspace.balancePaise > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            workspace.isOwner
                                ? 'A workshop owner can record an audited credit approval.'
                                : 'Clear the balance before handing over the vehicle.',
                            textAlign: TextAlign.center,
                            style: AppTokens.fontBody(
                              color: AppTokens.textSecondary,
                            ),
                          ),
                        ),
                    ] else ...[
                      const SizedBox(height: 12),
                      _notice(
                        'Handover recorded ${_date(workspace.deliveredAt!)}.',
                        error: false,
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmDelivery(
    BuildContext context,
    PaymentController controller,
    PaymentWorkspace workspace,
  ) async {
    final reasonController = TextEditingController();
    final allowOverride = workspace.isOwner && workspace.balancePaise > 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm vehicle handover?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              workspace.balancePaise == 0
                  ? 'The invoice is fully paid. This will complete the job and record the handover.'
                  : 'Balance due: ${formatPaymentRupees(workspace.balancePaise)}.',
            ),
            if (allowOverride) ...[
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Reason for allowing credit',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm handover'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deliver(allowOverride ? reasonController.text : '');
    }
    reasonController.dispose();
  }

  Widget _amountRow(
    String label,
    int paise, {
    bool strong = false,
    Color? color,
  }) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTokens.fontBody(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      Text(
        formatPaymentRupees(paise),
        style: AppTokens.fontMonospace(
          fontSize: strong ? 18 : 15,
          fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          color: color ?? AppTokens.textPrimary,
        ),
      ),
    ],
  );

  Widget _section(String text) => Text(
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

  Widget _notice(String text, {required bool error}) => _card(
    Row(
      children: [
        Icon(
          error ? Icons.error_outline : Icons.check_circle_outline,
          color: error ? AppTokens.brandRed : AppTokens.green,
        ),
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

  Widget _error(String? text, VoidCallback retry) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(text ?? 'Could not load payment details.'),
        ),
        OutlinedButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    ),
  );

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

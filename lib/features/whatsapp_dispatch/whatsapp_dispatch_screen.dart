import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'estimate_response_controller.dart';
import 'estimate_response_models.dart';

class WhatsAppDispatchScreen extends ConsumerStatefulWidget {
  const WhatsAppDispatchScreen({required this.jobCardId, super.key});

  final String? jobCardId;

  @override
  ConsumerState<WhatsAppDispatchScreen> createState() =>
      _WhatsAppDispatchScreenState();
}

class _WhatsAppDispatchScreenState
    extends ConsumerState<WhatsAppDispatchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.jobCardId?.trim() ?? '';
      if (id.isNotEmpty) {
        ref.read(estimateResponseControllerProvider.notifier).load(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estimateResponseControllerProvider);
    final controller = ref.read(estimateResponseControllerProvider.notifier);
    final hasJob = widget.jobCardId?.trim().isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'Customer response',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back to applications',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: !hasJob
          ? _message('Open a sent estimate from an existing application.')
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : state.workspace == null
          ? _loadError(
              state.errorMessage,
              () => controller.load(widget.jobCardId!),
            )
          : _workspace(state, controller),
    );
  }

  Widget _workspace(
    EstimateResponseState state,
    EstimateResponseController controller,
  ) {
    final workspace = state.workspace!;
    final items = [
      for (final item in workspace.items)
        EstimateResponseItem(
          id: item.id,
          description: item.description,
          itemType: item.itemType,
          code: item.code,
          quantity: item.quantity,
          unitRatePaise: item.unitRatePaise,
          gstRatePercent: item.gstRatePercent,
          decision: state.decisions[item.id] ?? EstimateItemDecision.pending,
          note: state.notes[item.id] ?? '',
        ),
    ];
    final totalPaise = items.fold<int>(
      0,
      (total, item) => total + item.taxableAmountPaise + item.gstAmountPaise,
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _customerCard(workspace),
                  const SizedBox(height: 14),
                  _whatsAppCard(workspace),
                  const SizedBox(height: 20),
                  Text(
                    'ESTIMATE ITEMS',
                    style: AppTokens.fontMonospace(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in items) ...[
                    _itemCard(item, controller),
                    const SizedBox(height: 10),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppTokens.inverse,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'ESTIMATE TOTAL INCLUDING GST',
                            style: AppTokens.fontMonospace(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppTokens.textOnDark,
                            ),
                          ),
                        ),
                        Text(
                          '₹${(totalPaise / 100).toStringAsFixed(2)}',
                          style: AppTokens.fontBody(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTokens.textOnDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    key: const ValueKey('response-customer-name'),
                    initialValue: state.customerName,
                    onChanged: controller.setCustomerName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Customer who responded',
                      filled: true,
                      fillColor: AppTokens.raised,
                      border: OutlineInputBorder(
                        borderRadius: AppTokens.zeroRadius,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Record what the customer actually decided. This creates an audit entry for each line item.',
                    style: AppTokens.fontBody(
                      fontSize: 13,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _notice(state.errorMessage!, error: true),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: const BoxDecoration(
                  color: AppTokens.raised,
                  border: Border(top: BorderSide(color: AppTokens.borderLight)),
                ),
                child: SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: state.saving || items.isEmpty
                        ? null
                        : () => _confirmAndSave(state, controller),
                    icon: state.saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      state.saving
                          ? 'Saving response…'
                          : 'Save customer response',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTokens.inverse,
                      foregroundColor: AppTokens.textOnDark,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppTokens.zeroRadius,
                      ),
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

  Widget _customerCard(EstimateResponseWorkspace workspace) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          workspace.registrationNumber,
          style: AppTokens.fontMonospace(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${workspace.customerName}  ·  ${workspace.customerPhone}',
          style: AppTokens.fontBody(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              workspace.whatsappConsent
                  ? Icons.check_circle_outline
                  : Icons.info_outline,
              size: 18,
              color: workspace.whatsappConsent
                  ? AppTokens.green
                  : AppTokens.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                workspace.whatsappConsent
                    ? 'Customer has opted in to WhatsApp updates.'
                    : 'WhatsApp consent was not recorded. Use another agreed channel.',
                style: AppTokens.fontBody(fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _whatsAppCard(EstimateResponseWorkspace workspace) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTokens.surface,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: estimateShareMessage(workspace)),
            );
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Estimate summary copied.')),
            );
          },
          icon: const Icon(Icons.copy_outlined),
          label: const Text('Copy estimate summary'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTokens.minTouchTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: AppTokens.zeroRadius,
            ),
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: workspace.whatsappConsent
              ? () => _openWhatsApp(workspace)
              : null,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Send WhatsApp follow-up'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF196C4A),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(AppTokens.minTouchTarget),
            shape: const RoundedRectangleBorder(
              borderRadius: AppTokens.zeroRadius,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _itemCard(
    EstimateResponseItem item,
    EstimateResponseController controller,
  ) {
    final amountPaise = item.taxableAmountPaise + item.gstAmountPaise;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.raised,
        border: Border.all(color: AppTokens.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.description,
            style: AppTokens.fontBody(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.itemType == 'labour' ? 'Labour' : 'Part'} · ${item.quantity} × ₹${(item.unitRatePaise / 100).toStringAsFixed(2)} · total with GST ₹${(amountPaise / 100).toStringAsFixed(2)}',
            style: AppTokens.fontBody(
              fontSize: 13,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final decision in [
                EstimateItemDecision.approved,
                EstimateItemDecision.declined,
                EstimateItemDecision.revisionRequested,
              ])
                ChoiceChip(
                  label: Text(decision.label),
                  selected: item.decision == decision,
                  onSelected: (_) => controller.setDecision(item.id, decision),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            key: ValueKey('response-note-${item.id}'),
            initialValue: item.note,
            onChanged: (value) => controller.setNote(item.id, value),
            maxLength: 1000,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Customer note (optional)',
              border: OutlineInputBorder(borderRadius: AppTokens.zeroRadius),
              filled: true,
              fillColor: AppTokens.base,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(EstimateResponseWorkspace workspace) async {
    final phone = workspace.customerPhone.replaceAll(RegExp(r'\D'), '');
    final internationalPhone = phone.length == 10 ? '91$phone' : phone;
    final uri = Uri.https('wa.me', '/$internationalPhone', {
      'text': estimateShareMessage(workspace),
    });
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp on this device.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp on this device.'),
        ),
      );
    }
  }

  Future<void> _confirmAndSave(
    EstimateResponseState state,
    EstimateResponseController controller,
  ) async {
    if (controller.validateCurrent() != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save customer decisions?'),
        content: const Text(
          'Confirm these choices reflect the customer’s response for every estimate item. The response will be saved to the job history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm response'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final saved = await controller.save();
    if (!saved || !mounted) return;
    final status = ref.read(estimateResponseControllerProvider).completedStatus;
    if (status == 'WORK_IN_PROGRESS') {
      context.go('/applications');
    } else if (status == 'ESTIMATE_REVISION_REQUIRED') {
      context.go(
        '/job-card',
        extra: {
          'jobCardId': state.workspace?.jobCardId,
          'registrationNumber': state.workspace?.registrationNumber,
        },
      );
    }
  }

  Widget _loadError(String? error, VoidCallback onRetry) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error ?? 'Could not load estimate.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );

  Widget _notice(String text, {required bool error}) => Container(
    padding: const EdgeInsets.all(12),
    color: error ? const Color(0xFFFFE8E3) : const Color(0xFFE7F3E8),
    child: Text(
      text,
      style: AppTokens.fontBody(
        color: error ? AppTokens.brandRed : AppTokens.green,
      ),
    ),
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, style: AppTokens.fontBody(fontSize: 16)),
    ),
  );
}

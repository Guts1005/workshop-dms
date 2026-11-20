import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'work_in_progress_controller.dart';
import 'work_in_progress_models.dart';

class WorkInProgressScreen extends ConsumerStatefulWidget {
  const WorkInProgressScreen({required this.jobCardId, super.key});

  final String? jobCardId;

  @override
  ConsumerState<WorkInProgressScreen> createState() =>
      _WorkInProgressScreenState();
}

class _WorkInProgressScreenState extends ConsumerState<WorkInProgressScreen> {
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.jobCardId?.trim() ?? '';
      if (id.isNotEmpty) {
        ref.read(workInProgressControllerProvider.notifier).load(id);
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(workInProgressControllerProvider);
    final controller = ref.read(workInProgressControllerProvider.notifier);
    final workspace = state.workspace;

    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'Work progress',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back to applications',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: widget.jobCardId?.trim().isNotEmpty != true
          ? _message('Open work progress from an active application.')
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : workspace == null
          ? _error(
              state.errorMessage,
              onRetry: () => controller.load(widget.jobCardId!),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _vehicleHeader(workspace.registrationNumber),
                    const SizedBox(height: 20),
                    _sectionTitle('APPROVED WORK'),
                    const SizedBox(height: 8),
                    if (workspace.scope.isEmpty)
                      _card(
                        const Text('No approved estimate items were found.'),
                      )
                    else
                      ...workspace.scope.map(
                        (item) => _card(
                          Row(
                            children: [
                              Icon(
                                item.itemType == 'part'
                                    ? Icons.settings_outlined
                                    : Icons.handyman_outlined,
                                size: 20,
                                color: AppTokens.brandRed,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.description,
                                  style: AppTokens.fontBody(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text('× ${_quantity(item.quantity)}'),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    ...workspace.scope
                        .where((item) => item.itemType == 'part')
                        .map(
                          (item) =>
                              _partStockCard(item, controller, state.saving),
                        ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        '/qc-gate',
                        extra: {'jobCardId': workspace.jobCardId},
                      ),
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Run quality check'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppTokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('ADD A PROGRESS UPDATE'),
                    const SizedBox(height: 8),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<WorkUpdateType>(
                            value: state.updateType,
                            decoration: const InputDecoration(
                              labelText: 'Update type',
                              border: OutlineInputBorder(),
                            ),
                            items: WorkUpdateType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.label),
                                  ),
                                )
                                .toList(),
                            onChanged: state.saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      controller.setType(value);
                                    }
                                  },
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _noteController,
                            minLines: 2,
                            maxLines: 4,
                            maxLength: 1000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'What changed?',
                              hintText: 'Add a short note for the job record',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: controller.setNote,
                          ),
                          if (state.errorMessage != null) ...[
                            Text(
                              state.errorMessage!,
                              style: AppTokens.fontBody(
                                color: AppTokens.brandRed,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          FilledButton.icon(
                            onPressed: state.saving
                                ? null
                                : () async {
                                    final saved = await controller.save();
                                    if (!saved || !mounted) return;
                                    _noteController.clear();
                                  },
                            icon: state.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.add),
                            label: Text(
                              state.saving ? 'Saving…' : 'Save update',
                            ),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppTokens.inverse,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('JOB HISTORY'),
                    const SizedBox(height: 8),
                    if (workspace.updates.isEmpty)
                      _card(
                        Text(
                          'No progress updates yet.',
                          style: AppTokens.fontBody(
                            color: AppTokens.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...workspace.updates.map(_updateCard),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _vehicleHeader(String plate) => _card(
    Row(
      children: [
        const Icon(Icons.directions_car_filled_outlined, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            plate,
            style: AppTokens.fontMonospace(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Chip(label: Text('IN SERVICE')),
      ],
    ),
  );

  Widget _updateCard(JobWorkUpdate update) => _card(
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(_iconFor(update.type), color: AppTokens.brandRed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(update.type.label.toUpperCase(), style: _sectionStyle()),
              const SizedBox(height: 5),
              Text(update.note, style: AppTokens.fontBody(fontSize: 15)),
              const SizedBox(height: 7),
              Text(
                '${_date(update.createdAt)} · ${update.createdBy}',
                style: AppTokens.fontBody(
                  fontSize: 12,
                  color: AppTokens.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _sectionTitle(String value) => Text(value, style: _sectionStyle());

  TextStyle _sectionStyle() =>
      AppTokens.fontMonospace(fontSize: 12, fontWeight: FontWeight.w800);

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: child,
  );

  Widget _message(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );

  Widget _partStockCard(
    WorkScopeItem item,
    WorkInProgressController controller,
    bool saving,
  ) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.description,
          style: AppTokens.fontBody(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          item.inventoryPartId == null
              ? 'Part ${item.code} is not in the stock catalog.'
              : 'Stock: ${_quantity(item.stockOnHand)}  |  Issued: ${_quantity(item.quantityIssued)} of ${_quantity(item.quantity)}',
          style: AppTokens.fontBody(color: AppTokens.textSecondary),
        ),
        if (item.inventoryPartId != null) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: saving || item.stockAvailable <= 0
                    ? null
                    : () => _stockMovementDialog(controller, item, 'ISSUE'),
                icon: const Icon(Icons.north_east),
                label: const Text('Issue part'),
              ),
              OutlinedButton.icon(
                onPressed: saving || item.quantityIssued <= 0
                    ? null
                    : () => _stockMovementDialog(controller, item, 'RETURN'),
                icon: const Icon(Icons.south_west),
                label: const Text('Return unused'),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Future<void> _stockMovementDialog(
    WorkInProgressController controller,
    WorkScopeItem item,
    String type,
  ) async {
    final quantity = TextEditingController();
    final maximum = type == 'ISSUE' ? item.stockAvailable : item.quantityIssued;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          type == 'ISSUE'
              ? 'Issue ${item.description}'
              : 'Return ${item.description}',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              type == 'ISSUE'
                  ? 'Up to ${_quantity(maximum)} can be issued from stock and the approved estimate.'
                  : 'Up to ${_quantity(maximum)} can be returned to stock.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(type == 'ISSUE' ? 'Issue part' : 'Record return'),
          ),
        ],
      ),
    );
    if (submitted == true && item.inventoryPartId != null && mounted) {
      await controller.recordPartMovement(
        partId: item.inventoryPartId!,
        type: type,
        quantityText: quantity.text,
      );
    }
    quantity.dispose();
  }

  Widget _error(String? message, {required VoidCallback onRetry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Could not load work progress.'),
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

  IconData _iconFor(WorkUpdateType type) => switch (type) {
    WorkUpdateType.progressNote => Icons.build_outlined,
    WorkUpdateType.waitingForParts => Icons.inventory_2_outlined,
    WorkUpdateType.customerUpdate => Icons.forum_outlined,
  };

  String _quantity(num value) =>
      value % 1 == 0 ? value.toInt().toString() : value.toString();

  String _date(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$day/$month/${local.year} $hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
  }
}

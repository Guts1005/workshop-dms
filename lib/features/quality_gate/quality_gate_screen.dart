import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'quality_gate_controller.dart';
import 'quality_gate_models.dart';

class QualityGateScreen extends ConsumerStatefulWidget {
  const QualityGateScreen({required this.jobCardId, super.key});

  final String? jobCardId;

  @override
  ConsumerState<QualityGateScreen> createState() => _QualityGateScreenState();
}

class _QualityGateScreenState extends ConsumerState<QualityGateScreen> {
  final _inspectorController = TextEditingController();
  final _roadTestNoteController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.jobCardId?.trim() ?? '';
      if (id.isNotEmpty) {
        ref.read(qualityGateControllerProvider.notifier).load(id);
      }
    });
  }

  @override
  void dispose() {
    _inspectorController.dispose();
    _roadTestNoteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qualityGateControllerProvider);
    final controller = ref.read(qualityGateControllerProvider.notifier);
    final workspace = state.workspace;

    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'Quality check',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back to work progress',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: widget.jobCardId?.trim().isNotEmpty != true
          ? _message('Open quality checks from an active application.')
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : workspace == null
          ? _error(
              state.errorMessage,
              onRetry: () => controller.load(widget.jobCardId!),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _card(
                      Row(
                        children: [
                          const Icon(Icons.directions_car_outlined),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              workspace.registrationNumber,
                              style: AppTokens.fontMonospace(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Chip(label: Text('FINAL CHECK')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Confirm the repair is complete, then record the final safety checks.',
                      style: AppTokens.fontBody(
                        color: AppTokens.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: state.workCompleted,
                        onChanged: state.saving
                            ? null
                            : (value) =>
                                  controller.setWorkCompleted(value ?? false),
                        title: const Text('Approved work is complete'),
                        subtitle: const Text('Required before final checks'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle('VEHICLE CHECKS'),
                    const SizedBox(height: 8),
                    for (final spec in qualityCheckSpecs) ...[
                      _card(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              spec.label,
                              style: AppTokens.fontBody(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: true,
                                  label: Text('Pass'),
                                  icon: Icon(Icons.check),
                                ),
                                ButtonSegment(
                                  value: false,
                                  label: Text('Needs attention'),
                                  icon: Icon(Icons.priority_high),
                                ),
                              ],
                              selected: state.checks.containsKey(spec.id)
                                  ? {state.checks[spec.id]!}
                                  : const {},
                              onSelectionChanged: state.saving
                                  ? null
                                  : (selection) {
                                      if (selection.isNotEmpty) {
                                        controller.setCheck(
                                          spec.id,
                                          selection.first,
                                        );
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _sectionTitle('ROAD TEST'),
                    const SizedBox(height: 8),
                    _card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DropdownButtonFormField<RoadTestResult>(
                            value: state.roadTestResult,
                            decoration: const InputDecoration(
                              labelText: 'Result',
                              border: OutlineInputBorder(),
                            ),
                            items: RoadTestResult.values
                                .map(
                                  (result) => DropdownMenuItem(
                                    value: result,
                                    child: Text(result.label),
                                  ),
                                )
                                .toList(),
                            onChanged: state.saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      controller.setRoadTestResult(value);
                                    }
                                  },
                          ),
                          if (state.roadTestResult !=
                              RoadTestResult.passed) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _roadTestNoteController,
                              minLines: 2,
                              maxLines: 3,
                              maxLength: 1000,
                              decoration: const InputDecoration(
                                labelText: 'Why did it fail or get skipped?',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: controller.setRoadTestNote,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _inspectorController,
                      label: 'Inspector name',
                      onChanged: controller.setInspectorName,
                      capitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    _textField(
                      controller: _notesController,
                      label: 'Additional notes (optional)',
                      onChanged: controller.setNotes,
                      maxLines: 3,
                    ),
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      _messageCard(state.errorMessage!, isError: true),
                    ],
                    if (state.result != null) ...[
                      const SizedBox(height: 12),
                      _messageCard(
                        state.result == 'PASSED'
                            ? 'QC passed. Continue to invoice preparation.'
                            : 'QC issue recorded. Keep the job in service, resolve it, then run the checks again.',
                        isError: state.result == 'FAILED',
                      ),
                    ],
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: state.saving || state.result == 'PASSED'
                          ? null
                          : () => controller.save(),
                      icon: state.saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fact_check_outlined),
                      label: Text(
                        state.saving ? 'Saving…' : 'Record quality result',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        backgroundColor: AppTokens.inverse,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<String> onChanged,
    TextCapitalization capitalization = TextCapitalization.sentences,
    int maxLines = 1,
  }) => TextField(
    controller: controller,
    maxLines: maxLines,
    maxLength: maxLines == 1 ? 120 : 2000,
    textCapitalization: capitalization,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: AppTokens.raised,
    ),
    onChanged: onChanged,
  );

  Widget _message(String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(text, textAlign: TextAlign.center),
    ),
  );

  Widget _messageCard(String text, {required bool isError}) => _card(
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? AppTokens.brandRed : AppTokens.green,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );

  Widget _error(String? message, {required VoidCallback onRetry}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message ?? 'Could not load the quality gate.'),
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
}

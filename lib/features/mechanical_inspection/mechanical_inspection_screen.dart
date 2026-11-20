import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'mechanical_inspection_controller.dart';
import 'mechanical_inspection_models.dart';

class MechanicalInspectionScreen extends ConsumerStatefulWidget {
  const MechanicalInspectionScreen({
    required this.jobCardId,
    required this.registrationNumber,
    super.key,
  });

  final String? jobCardId;
  final String? registrationNumber;

  @override
  ConsumerState<MechanicalInspectionScreen> createState() =>
      _MechanicalInspectionScreenState();
}

class _MechanicalInspectionScreenState
    extends ConsumerState<MechanicalInspectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobCardId = widget.jobCardId?.trim() ?? '';
      final plate = widget.registrationNumber?.trim() ?? '';
      if (jobCardId.isNotEmpty && plate.isNotEmpty) {
        ref
            .read(mechanicalInspectionControllerProvider.notifier)
            .initSession(jobCardId: jobCardId, registrationNumber: plate);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mechanicalInspectionControllerProvider);
    final controller = ref.read(
      mechanicalInspectionControllerProvider.notifier,
    );
    final hasJob =
        (widget.jobCardId?.trim().isNotEmpty ?? false) &&
        (widget.registrationNumber?.trim().isNotEmpty ?? false);

    return Scaffold(
      backgroundColor: AppTokens.base,
      appBar: AppBar(
        backgroundColor: AppTokens.base,
        foregroundColor: AppTokens.textPrimary,
        elevation: 0,
        title: const Text(
          'Mechanical inspection',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back to applications',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: !hasJob
          ? _message('Open an inspection from an existing application.')
          : state.loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        children: [
                          _vehicleHeader(state.registrationNumber),
                          const SizedBox(height: 18),
                          Text(
                            'Record measured values. If a measurement does not apply to this vehicle, mark it clearly.',
                            style: AppTokens.fontBody(
                              fontSize: 15,
                              color: AppTokens.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _textField(
                            label: 'Inspector name',
                            initialValue: state.inspectorName,
                            onChanged: controller.setInspectorName,
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          _textField(
                            label: 'Odometer reading',
                            initialValue: state.odometerText,
                            suffix: 'km',
                            keyboardType: TextInputType.number,
                            onChanged: controller.setOdometer,
                            helperText:
                                'Must be at least ${state.intakeOdometerKm} km from check-in',
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'MEASUREMENTS',
                            style: AppTokens.fontMonospace(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          for (final spec in mechanicalMeasurementSpecs) ...[
                            _measurementField(
                              spec: spec,
                              value: state.measurementTexts[spec.id] ?? '',
                              notApplicable: state.notApplicable.contains(
                                spec.id,
                              ),
                              onChanged: (value) =>
                                  controller.setMeasurement(spec.id, value),
                              onNotApplicableChanged: (value) => controller
                                  .setNotApplicable(spec.id, value ?? false),
                            ),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 8),
                          _textField(
                            label: 'Observations (optional)',
                            initialValue: state.notes,
                            onChanged: controller.setNotes,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: 14),
                            _notice(state.errorMessage!, isError: true),
                          ],
                          if (state.saved) ...[
                            const SizedBox(height: 14),
                            _notice('Inspection saved.', isError: false),
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
                          border: Border(
                            top: BorderSide(color: AppTokens.borderLight),
                          ),
                        ),
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: state.saving
                                ? null
                                : () async {
                                    final saved = await controller.save();
                                    if (!saved || !context.mounted) return;
                                    context.go(
                                      '/job-card',
                                      extra: {
                                        'jobCardId': state.jobCardId,
                                        'registrationNumber':
                                            state.registrationNumber,
                                      },
                                    );
                                  },
                            icon: state.saving
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.arrow_forward),
                            label: Text(
                              state.saving
                                  ? 'Saving inspection…'
                                  : 'Save inspection and continue',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTokens.inverse,
                              foregroundColor: AppTokens.textOnDark,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppTokens.zeroRadius,
                              ),
                              textStyle: AppTokens.fontBody(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTokens.textOnDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _vehicleHeader(String registrationNumber) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: Row(
      children: [
        const Icon(Icons.directions_car_outlined, color: AppTokens.brandRed),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            registrationNumber,
            style: AppTokens.fontMonospace(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Text('INSPECTION'),
      ],
    ),
  );

  Widget _measurementField({
    required MechanicalMeasurementSpec spec,
    required String value,
    required bool notApplicable,
    required ValueChanged<String> onChanged,
    required ValueChanged<bool?> onNotApplicableChanged,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      border: Border.all(color: AppTokens.borderLight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.label,
          style: AppTokens.fontBody(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('${spec.id}:$notApplicable'),
          initialValue: value,
          enabled: !notApplicable,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: InputDecoration(
            suffixText: spec.unit,
            hintText: 'Enter measured value',
            filled: true,
            fillColor: AppTokens.base,
            border: const OutlineInputBorder(
              borderRadius: AppTokens.zeroRadius,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
        Material(
          color: AppTokens.raised,
          child: CheckboxListTile(
            value: notApplicable,
            onChanged: onNotApplicableChanged,
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Not applicable for this vehicle'),
          ),
        ),
      ],
    ),
  );

  Widget _textField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
    String? suffix,
    String? helperText,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
  }) => TextFormField(
    key: ValueKey(label),
    initialValue: initialValue,
    onChanged: onChanged,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      helperText: helperText,
      filled: true,
      fillColor: AppTokens.raised,
      border: const OutlineInputBorder(borderRadius: AppTokens.zeroRadius),
    ),
  );

  Widget _notice(String text, {required bool isError}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isError ? const Color(0xFFFFE8E3) : const Color(0xFFE7F3E8),
      border: Border.all(color: isError ? AppTokens.brandRed : AppTokens.green),
    ),
    child: Text(
      text,
      style: AppTokens.fontBody(
        color: isError ? AppTokens.brandRed : AppTokens.green,
        fontWeight: FontWeight.w600,
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

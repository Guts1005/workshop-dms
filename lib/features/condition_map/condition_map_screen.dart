import 'package:flutter/material.dart';

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../ui_kit/tokens/app_tokens.dart';
import 'condition_map_controller.dart';
import 'condition_map_models.dart';

class ConditionMapScreen extends ConsumerStatefulWidget {
  final String? jobCardId;
  final String? registrationNumber;

  const ConditionMapScreen({
    super.key,
    this.jobCardId,
    this.registrationNumber,
  });

  @override
  ConsumerState<ConditionMapScreen> createState() => _ConditionMapScreenState();
}

class _ConditionMapScreenState extends ConsumerState<ConditionMapScreen> {
  static const _ink = AppTokens.textPrimary;
  static const _muted = AppTokens.textSecondary;
  static const _line = AppTokens.borderLight;
  static const _green = AppTokens.brandRed;
  static const _paper = AppTokens.base;
  final Map<String, Future<String>> _signedPhotoUrls = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobCardId = widget.jobCardId?.trim();
      final registration = widget.registrationNumber?.trim();
      if (jobCardId != null &&
          jobCardId.isNotEmpty &&
          registration != null &&
          registration.isNotEmpty) {
        ref
            .read(conditionMapControllerProvider.notifier)
            .initSession(
              jobCardId: jobCardId,
              registrationNumber: registration,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conditionMapControllerProvider);
    final controller = ref.read(conditionMapControllerProvider.notifier);
    final hasJob =
        state.jobCardId.isNotEmpty && state.registrationNumber.isNotEmpty;

    if (!hasJob) {
      return _missingJob();
    }

    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width >= 1100 ? 1020.0 : 760.0;
    final remaining =
        ConditionViewDirection.values.length - state.reviewedCount;

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Vehicle condition',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/applications'),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    _vehicleHeader(state),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Exterior check',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${state.reviewedCount}/5 checked',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Check each area. Record anything the workshop should know before work begins.',
                      style: TextStyle(
                        color: _muted,
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _progressBar(
                      state.reviewedCount /
                          ConditionViewDirection.values.length,
                    ),
                    const SizedBox(height: 18),
                    for (final view in ConditionViewDirection.values) ...[
                      _areaCard(state, controller, view),
                      const SizedBox(height: 10),
                    ],
                    if (state.pins.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Recorded findings',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final pin in state.pins)
                        _findingCard(pin, controller, state.isLocked),
                    ],
                    if (state.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: AppTokens.brandRed),
                      ),
                    ],
                  ],
                ),
              ),
              _footer(state, controller, remaining),
            ],
          ),
        ),
      ),
    );
  }

  Widget _missingJob() => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      backgroundColor: _paper,
      title: const Text('Vehicle condition'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_late_outlined, size: 42, color: _muted),
            const SizedBox(height: 12),
            const Text(
              'This inspection needs an application',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Open an existing application or create one first so this report is saved against the right vehicle.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => context.go('/applications'),
              child: const Text('Go to applications'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _vehicleHeader(ConditionMapState state) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      borderRadius: AppTokens.cardRadius,
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppTokens.surfaceSubtle,
            borderRadius: AppTokens.cardRadius,
          ),
          child: const Icon(
            Icons.directions_car_filled_outlined,
            color: _green,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.registrationNumber,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: .5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Application ${state.jobCardId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        if (state.isLocked) const Icon(Icons.verified_rounded, color: _green),
      ],
    ),
  );

  Widget _progressBar(double value) => ClipRRect(
    borderRadius: AppTokens.cardRadius,
    child: LinearProgressIndicator(
      value: value,
      minHeight: 7,
      backgroundColor: AppTokens.surfaceSubtle,
      color: _green,
    ),
  );

  Widget _areaCard(
    ConditionMapState state,
    ConditionMapController controller,
    ConditionViewDirection view,
  ) {
    final findings = state.pins.where((pin) => pin.view == view).toList();
    final checked = state.reviewedViews.contains(view);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTokens.raised,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: checked ? AppTokens.surfaceSubtle : _paper,
                  borderRadius: AppTokens.cardRadius,
                ),
                child: Icon(
                  _iconFor(view),
                  color: checked ? _green : _muted,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleFor(view),
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      findings.isEmpty
                          ? (checked
                                ? 'Checked - no findings'
                                : 'Not checked yet')
                          : '${findings.length} ${findings.length == 1 ? 'finding' : 'findings'}',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (checked)
                const Icon(Icons.check_circle, color: _green, size: 20),
            ],
          ),
          if (findings.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final finding in findings.take(2))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '- ${finding.type.label.toLowerCase()}${finding.note?.isNotEmpty == true ? ' - ${finding.note}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ),
            if (findings.length > 2)
              Text(
                '+ ${findings.length - 2} more',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
          ],
          if (!state.isLocked) ...[
            const SizedBox(height: 13),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showFindingDialog(view),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(findings.isEmpty ? 'Add finding' : 'Add another'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _line),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                  ),
                ),
                if (!checked) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => controller.markViewReviewed(view),
                    icon: const Icon(Icons.check, size: 17),
                    label: const Text('No issue'),
                    style: TextButton.styleFrom(foregroundColor: _green),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _findingCard(
    ConditionPin pin,
    ConditionMapController controller,
    bool locked,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTokens.raised,
      borderRadius: AppTokens.cardRadius,
      border: Border.all(color: _line),
    ),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 38,
          decoration: BoxDecoration(
            color: pin.severity.accentColor,
            borderRadius: AppTokens.cardRadius,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_pretty(pin.type.label)} - ${_titleFor(pin.view)}',
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                pin.note?.isNotEmpty == true
                    ? pin.note!
                    : pin.severity.label.replaceAll('LEVEL ', ''),
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
              if (pin.photoPath != null) ...[
                const SizedBox(height: 9),
                FutureBuilder<String>(
                  future: _signedPhotoUrls.putIfAbsent(
                    pin.photoPath!,
                    () => Supabase.instance.client.storage
                        .from('workshop-checkin')
                        .createSignedUrl(pin.photoPath!, 3600),
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Photo unavailable',
                        style: TextStyle(color: _muted, fontSize: 12),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Row(
                        children: [
                          Icon(Icons.photo_outlined, size: 16, color: _muted),
                          SizedBox(width: 5),
                          Text(
                            'Photo attached',
                            style: TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      );
                    }
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          child: InteractiveViewer(
                            child: Image.network(snapshot.data!),
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          snapshot.data!,
                          width: 112,
                          height: 76,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        if (!locked)
          IconButton(
            tooltip: 'Remove finding',
            onPressed: () => controller.deletePin(pin.id),
            icon: const Icon(Icons.delete_outline, color: _muted),
          ),
      ],
    ),
  );

  Widget _footer(
    ConditionMapState state,
    ConditionMapController controller,
    int remaining,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
    decoration: const BoxDecoration(
      color: AppTokens.raised,
      border: Border(top: BorderSide(color: _line)),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        child: state.isLocked
            ? FilledButton.icon(
                onPressed: () => context.go('/applications'),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Report saved - back to applications'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              )
            : FilledButton.icon(
                onPressed: remaining == 0
                    ? () => _showSignOffDialog(state, controller)
                    : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  remaining == 0
                      ? 'Review and save report'
                      : 'Check $remaining more ${remaining == 1 ? 'area' : 'areas'}',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: AppTokens.borderLight,
                  disabledForegroundColor: _muted,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
      ),
    ),
  );

  Future<void> _showFindingDialog(ConditionViewDirection view) async {
    final note = TextEditingController();
    var type = DefectType.surfaceScuff;
    var severity = DefectSeverity.minor;
    Uint8List? photoBytes;
    String? photoContentType;
    String? photoError;
    var isPickingPhoto = false;
    final controller = ref.read(conditionMapControllerProvider.notifier);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTokens.raised,
          title: Text(
            'Finding: ${_titleFor(view)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'What did you notice?',
                    style: TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<DefectType>(
                    value: type,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                    ),
                    items: DefectType.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(_pretty(item.label)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => type = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DefectSeverity>(
                    value: severity,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Severity',
                      border: OutlineInputBorder(),
                    ),
                    items: DefectSeverity.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(
                              _pretty(
                                item.label.replaceAll(
                                  RegExp(r'^LEVEL [0-9] - '),
                                  '',
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setDialogState(() => severity = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'Describe where it is or what you noticed',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (photoBytes == null)
                    OutlinedButton.icon(
                      onPressed: isPickingPhoto
                          ? null
                          : () async {
                              final source =
                                  await showModalBottomSheet<ImageSource>(
                                    context: context,
                                    builder: (sheetContext) => SafeArea(
                                      child: Wrap(
                                        children: [
                                          ListTile(
                                            leading: const Icon(
                                              Icons.camera_alt_outlined,
                                            ),
                                            title: const Text('Take a photo'),
                                            onTap: () => Navigator.pop(
                                              sheetContext,
                                              ImageSource.camera,
                                            ),
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.photo_library_outlined,
                                            ),
                                            title: const Text(
                                              'Choose from photos',
                                            ),
                                            onTap: () => Navigator.pop(
                                              sheetContext,
                                              ImageSource.gallery,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                              if (source == null || !context.mounted) return;
                              setDialogState(() {
                                isPickingPhoto = true;
                                photoError = null;
                              });
                              try {
                                final picked = await ImagePicker().pickImage(
                                  source: source,
                                  imageQuality: 85,
                                  maxWidth: 1800,
                                  maxHeight: 1800,
                                );
                                if (picked != null) {
                                  final bytes = await picked.readAsBytes();
                                  if (context.mounted) {
                                    setDialogState(() {
                                      final contentType = _imageMimeType(
                                        picked.name,
                                        picked.mimeType,
                                      );
                                      if (contentType == null) {
                                        photoError = 'Choose a JPEG, PNG, or WebP photo.';
                                        return;
                                      }
                                      photoBytes = bytes;
                                      photoContentType = contentType;
                                    });
                                  }
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  setDialogState(
                                    () => photoError = 'Could not add photo. Please try again.',
                                  );
                                }
                              } finally {
                                if (context.mounted) {
                                  setDialogState(() => isPickingPhoto = false);
                                }
                              }
                            },
                      icon: isPickingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_a_photo_outlined),
                      label: Text(
                        isPickingPhoto
                            ? 'Opening photos...'
                            : 'Add a photo (optional)',
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            photoBytes!,
                            width: 104,
                            height: 76,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        TextButton.icon(
                          onPressed: () => setDialogState(() {
                            photoBytes = null;
                            photoContentType = null;
                            photoError = null;
                          }),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove photo'),
                        ),
                      ],
                    ),
                  if (photoError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      photoError!,
                      style: const TextStyle(
                        color: AppTokens.brandRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isPickingPhoto
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isPickingPhoto
                  ? null
                  : () async {
                      try {
                        await controller.addPin(
                          view: view,
                          nx: .5,
                          ny: .5,
                          type: type,
                          severity: severity,
                          note: note.text.trim().isEmpty
                              ? null
                              : note.text.trim(),
                          photoBytes: photoBytes,
                          photoContentType: photoContentType,
                        );
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (_) {
                        if (context.mounted) {
                          setDialogState(
                            () => photoError = 'Finding could not be saved. Check your connection and try again.',
                          );
                        }
                      }
                    },
              child: const Text('Save finding'),
            ),
          ],
        ),
      ),
    );
    note.dispose();
  }

  static String? _imageMimeType(String name, String? mimeType) {
    const supportedTypes = {'image/jpeg', 'image/png', 'image/webp'};
    if (supportedTypes.contains(mimeType)) return mimeType;
    final extension = name.split('.').last.toLowerCase();
    return switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => null,
    };
  }

  Future<void> _showSignOffDialog(
    ConditionMapState state,
    ConditionMapController controller,
  ) async {
    final customer = TextEditingController();
    final phone = TextEditingController();
    final advisor = TextEditingController();
    var acknowledged = false;
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTokens.raised,
          title: const Text(
            'Save condition report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'This report will be saved to ${state.registrationNumber} for future reference.',
                    style: const TextStyle(color: _muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customer,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Customer name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Customer mobile',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: advisor,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Advisor name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: acknowledged,
                    onChanged: (value) =>
                        setDialogState(() => acknowledged = value ?? false),
                    title: const Text(
                      'Customer reviewed this report',
                      style: TextStyle(fontSize: 13),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (error != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        error!,
                        style: const TextStyle(
                          color: AppTokens.brandRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!acknowledged) {
                  setDialogState(
                    () => error =
                        'Ask the customer to review and confirm before saving.',
                  );
                  return;
                }
                final validation = controller.validateSignOffInput(
                  customerName: customer.text,
                  customerPhone: phone.text,
                  advisorName: advisor.text,
                );
                if (validation != null) {
                  setDialogState(() => error = validation);
                  return;
                }
                final saved = await controller.confirmPreWorkSignOff(
                  customerName: customer.text,
                  customerPhone: phone.text,
                  advisorName: advisor.text,
                );
                if (saved && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Confirm and save'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    customer.dispose();
    phone.dispose();
    advisor.dispose();
  }

  static String _titleFor(ConditionViewDirection view) => switch (view) {
    ConditionViewDirection.sideLeft => 'Left side',
    ConditionViewDirection.sideRight => 'Right side',
    ConditionViewDirection.front => 'Front',
    ConditionViewDirection.rear => 'Rear',
    ConditionViewDirection.top => 'Roof and glass',
  };

  static IconData _iconFor(ConditionViewDirection view) => switch (view) {
    ConditionViewDirection.sideLeft ||
    ConditionViewDirection.sideRight => Icons.directions_car_outlined,
    ConditionViewDirection.front => Icons.car_crash_outlined,
    ConditionViewDirection.rear => Icons.car_repair_outlined,
    ConditionViewDirection.top => Icons.grid_view_rounded,
  };

  static String _pretty(String value) => value
      .toLowerCase()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

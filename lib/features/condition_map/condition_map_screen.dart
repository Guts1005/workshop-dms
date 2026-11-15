import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../ui_kit/tokens/app_tokens.dart';
import '../../ui_kit/widgets/sharp_button.dart';
import '../../ui_kit/widgets/status_chip.dart';
import '../../ui_kit/widgets/swipe_to_confirm_slider.dart';
import 'condition_map_controller.dart';
import 'condition_map_models.dart';
import 'condition_schematic_painter.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobCardId != null || widget.registrationNumber != null) {
        ref.read(conditionMapControllerProvider.notifier).initSession(
              jobCardId: widget.jobCardId ?? 'JC-${DateTime.now().millisecondsSinceEpoch}',
              registrationNumber: widget.registrationNumber ?? 'RJ27CA1024',
            );
      }
    });
  }

  void _showAddPinDialog(BuildContext context, Offset normalizedPos, ConditionViewDirection view) {
    final controller = ref.read(conditionMapControllerProvider.notifier);
    final state = ref.read(conditionMapControllerProvider);

    if (state.isLocked) return;

    DefectType selectedType = DefectType.dent;
    DefectSeverity selectedSeverity = DefectSeverity.minor;
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                color: AppTokens.inverse,
                child: Row(
                  children: [
                    const Icon(Icons.add_location_alt_outlined, color: AppTokens.redOrange, size: 20.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'RECORD DEFECT PIN #${state.totalPinCount + 1}',
                      style: AppTokens.fontMonospace(
                        color: AppTokens.textOnDark,
                        fontWeight: FontWeight.w900,
                        fontSize: 13.0,
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 460.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'VIEW: ${view.label} • COORD: (${(normalizedPos.dx * 100).toStringAsFixed(1)}%, ${(normalizedPos.dy * 100).toStringAsFixed(1)}%)',
                        style: AppTokens.fontMonospace(fontSize: 10.5, color: AppTokens.textSecondary, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12.0),
                      Text('DEFECT CLASSIFICATION:', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 6.0,
                        children: DefectType.values.map((type) {
                          final isSel = selectedType == type;
                          return ChoiceChip(
                            label: Text(type.label),
                            selected: isSel,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            selectedColor: AppTokens.inverse,
                            backgroundColor: AppTokens.raised,
                            labelStyle: TextStyle(
                              color: isSel ? AppTokens.textOnDark : AppTokens.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.5,
                              fontFamily: 'monospace',
                            ),
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedType = type);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14.0),
                      Text('SEVERITY LEVEL:', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      Row(
                        children: DefectSeverity.values.map((sev) {
                          final isSel = selectedSeverity == sev;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: InkWell(
                                onTap: () => setDialogState(() => selectedSeverity = sev),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    color: isSel ? sev.accentColor : AppTokens.raised,
                                    border: Border.all(
                                      color: isSel ? AppTokens.borderSolid : const Color(0xFFCCCCCC),
                                      width: isSel ? 2.0 : 1.0,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    sev.label.replaceAll('LEVEL ', 'L'),
                                    style: TextStyle(
                                      color: isSel ? Colors.white : AppTokens.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.0,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14.0),
                      Text('INSPECTION NOTES / OBSERVED DAMAGE:', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 5cm paint gouge down to primer near lower door crease',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTokens.textSecondary)),
                ),
                SharpButton(
                  label: 'SAVE DEFECT PIN',
                  icon: Icons.check,
                  onPressed: () async {
                    await controller.addPin(
                      view: view,
                      nx: normalizedPos.dx,
                      ny: normalizedPos.dy,
                      type: selectedType,
                      severity: selectedSeverity,
                      note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                    );
                    if (dialogCtx.mounted) {
                      Navigator.of(dialogCtx).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPreWorkSignOffModal(BuildContext context) {
    final state = ref.read(conditionMapControllerProvider);
    final controller = ref.read(conditionMapControllerProvider.notifier);

    final customerNameController = TextEditingController(text: 'Rohan Sharma');
    final customerPhoneController = TextEditingController(text: '9876543210');
    final advisorNameController = TextEditingController(text: 'Vikram Joshi (Advisor)');
    bool consentChecked = true;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 16.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        color: AppTokens.inverse,
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined, color: Color(0xFF00E676), size: 20.0),
                            const SizedBox(width: 8.0),
                            Text(
                              'CUSTOMER PRE-WORK CONDITION SIGN-OFF',
                              style: AppTokens.fontMonospace(
                                color: AppTokens.textOnDark,
                                fontWeight: FontWeight.w900,
                                fontSize: 13.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      const Text(
                        'Review recorded exterior defects before commencing repair work. Confirmation locks this condition map and generates an immutable SHA-256 integrity hash.',
                        style: TextStyle(fontSize: 12.0, color: AppTokens.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 12.0),

                      // Defect Summary Chips
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        color: AppTokens.base,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text('TOTAL: ${state.totalPinCount}', style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 11.5)),
                            Text('SEVERE: ${state.severeCount}', style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 11.5, color: AppTokens.redOrange)),
                            Text('MODERATE: ${state.moderateCount}', style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 11.5, color: const Color(0xFFF8A348))),
                            Text('MINOR: ${state.minorCount}', style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 11.5, color: const Color(0xFF2E6B3F))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // Customer Details
                      Text('CUSTOMER FULL NAME *', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: customerNameController,
                        decoration: const InputDecoration(
                          hintText: 'Customer Name',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                      const SizedBox(height: 10.0),

                      Text('CUSTOMER MOBILE (+91) *', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: '10-digit mobile number',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                      const SizedBox(height: 10.0),

                      Text('SERVICE ADVISOR SIGNING *', style: AppTokens.fontMonospace(fontSize: 11.0, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: advisorNameController,
                        decoration: const InputDecoration(
                          hintText: 'Service Advisor Name / ID',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      // Customer Consent Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: consentChecked,
                            activeColor: AppTokens.inverse,
                            onChanged: (val) => setModalState(() => consentChecked = val ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Customer acknowledges that all pre-existing damages noted above were present prior to workshop handover.',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.3),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (localError != null) ...[
                        const SizedBox(height: 8.0),
                        Text(
                          localError!,
                          style: const TextStyle(color: AppTokens.redOrange, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const SizedBox(height: 16.0),

                      // Swipe-to-Confirm Slider (Irreversible Action Gate)
                      SwipeToConfirmSlider(
                        label: 'SWIPE TO CONFIRM PRE-WORK SIGN-OFF',
                        onConfirmed: () async {
                          if (!consentChecked) {
                            setModalState(() => localError = 'Customer consent acknowledgement is required');
                            return;
                          }
                          final err = controller.validateSignOffInput(
                            customerName: customerNameController.text,
                            customerPhone: customerPhoneController.text,
                            advisorName: advisorNameController.text,
                          );
                          if (err != null) {
                            setModalState(() => localError = err);
                            return;
                          }

                          final ok = await controller.confirmPreWorkSignOff(
                            customerName: customerNameController.text,
                            customerPhone: customerPhoneController.text,
                            advisorName: advisorNameController.text,
                          );

                          if (ok && modalCtx.mounted) {
                            Navigator.of(modalCtx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Pre-work condition map signed off and locked.'),
                                backgroundColor: Color(0xFF00E676),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conditionMapControllerProvider);
    final controller = ref.read(conditionMapControllerProvider.notifier);
    final isNarrow = MediaQuery.of(context).size.width < 960.0;

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Header & Telemetry Bar
            _buildHeaderBar(state),

            // Error Notice Banner
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                color: AppTokens.redOrange,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 16.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content Zone (Responsive, zero horizontal overflow)
            Expanded(
              child: isNarrow ? _buildNarrowLayout(state, controller) : _buildWideLayout(state, controller),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(state),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(ConditionMapState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: AppTokens.inverse,
        border: Border(bottom: BorderSide(color: Color(0xFF333333), width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                color: AppTokens.redOrange,
                child: Text(
                  '03',
                  style: AppTokens.fontMonospace(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAGE 3: 360° CONDITION MAP & PRE-WORK SIGN-OFF',
                    style: AppTokens.fontMonospace(
                      color: AppTokens.textOnDark,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'JOB: ${state.jobCardId} • VEHICLE: ${state.registrationNumber}',
                    style: AppTokens.fontMonospace(
                      color: AppTokens.surface,
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              if (state.isLocked)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: StatusChip(
                    label: 'PRE-WORK SIGNED OFF',
                    icon: Icons.lock,
                    type: StatusType.ok,
                  ),
                ),
              StatusChip(
                label: '${state.totalPinCount} DEFECTS LOGGED',
                icon: Icons.pin_drop,
                type: state.severeCount > 0 ? StatusType.critical : (state.totalPinCount > 0 ? StatusType.dueSoon : StatusType.ok),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(ConditionMapState state, ConditionMapController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildViewTabs(state, controller),
          const SizedBox(height: 10.0),
          _buildInteractiveCanvas(state, controller, height: 340.0),
          const SizedBox(height: 14.0),
          _buildPinInspector(state, controller),
          const SizedBox(height: 14.0),
          _buildPinsSummaryCard(state, controller),
        ],
      ),
    );
  }

  Widget _buildWideLayout(ConditionMapState state, ConditionMapController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Area: View Tabs & Interactive Schematic Canvas
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildViewTabs(state, controller),
                const SizedBox(height: 12.0),
                Expanded(
                  child: _buildInteractiveCanvas(state, controller, height: double.infinity),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16.0),
          // Right Sidebar: Pin Inspector & Defect Ledger
          SizedBox(
            width: 380.0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPinInspector(state, controller),
                  const SizedBox(height: 14.0),
                  _buildPinsSummaryCard(state, controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabs(ConditionMapState state, ConditionMapController controller) {
    return Row(
      children: ConditionViewDirection.values.map((v) {
        final isSel = state.activeView == v;
        final pinCountInView = state.pins.where((p) => p.view == v).length;

        return Expanded(
          child: InkWell(
            onTap: () => controller.switchView(v),
            child: Container(
              height: 44.0,
              decoration: BoxDecoration(
                color: isSel ? AppTokens.inverse : AppTokens.surface,
                border: Border.all(
                  color: isSel ? AppTokens.borderSolid : const Color(0xFFCCCCCC),
                  width: isSel ? 2.0 : 1.0,
                ),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    v.label,
                    style: TextStyle(
                      color: isSel ? AppTokens.textOnDark : AppTokens.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11.0,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (pinCountInView > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                      color: isSel ? AppTokens.redOrange : AppTokens.inverse,
                      child: Text(
                        '$pinCountInView',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractiveCanvas(
    ConditionMapState state,
    ConditionMapController controller, {
    required double height,
  }) {
    final activePins = state.activeViewPins;

    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: AppTokens.raised,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              if (state.isLocked) return;
              final localOffset = details.localPosition;
              final nx = (localOffset.dx / constraints.maxWidth).clamp(0.0, 1.0);
              final ny = (localOffset.dy / constraints.maxHeight).clamp(0.0, 1.0);
              _showAddPinDialog(context, Offset(nx, ny), state.activeView);
            },
            child: Stack(
              children: [
                // 1. Vector Schematic Drawing for Active View Angle
                Positioned.fill(
                  child: CustomPaint(
                    painter: ConditionSchematicPainter(
                      view: state.activeView,
                      isLocked: state.isLocked,
                    ),
                  ),
                ),

                // 2. Numbered Condition Pin Overlays
                for (final pin in activePins)
                  Positioned(
                    left: (pin.normalizedX * constraints.maxWidth) - 14.0,
                    top: (pin.normalizedY * constraints.maxHeight) - 14.0,
                    child: GestureDetector(
                      onTap: () => controller.selectPin(pin),
                      child: Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: pin.severity.accentColor,
                          border: Border.all(
                            color: state.selectedPin?.id == pin.id ? Colors.white : AppTokens.inverse,
                            width: state.selectedPin?.id == pin.id ? 2.5 : 1.2,
                          ),
                          boxShadow: state.selectedPin?.id == pin.id
                              ? [BoxShadow(color: pin.severity.accentColor.withOpacity(0.6), blurRadius: 6.0)]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${pin.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Instruction Pill Indicator in corner
                Positioned(
                  bottom: 8.0,
                  left: 8.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    color: AppTokens.inverse.withOpacity(0.85),
                    child: Text(
                      state.isLocked
                          ? 'MAP LOCKED: PRE-WORK SIGN-OFF RECORDED'
                          : 'TAP SCHEMATIC TO DROP DEFECT PIN [${state.activeView.label}]',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinInspector(ConditionMapState state, ConditionMapController controller) {
    final sel = state.selectedPin;

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: sel == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEFECT INSPECTOR',
                  style: AppTokens.fontMonospace(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  'Tap any numbered pin on the vehicle schematic to inspect or delete.',
                  style: TextStyle(fontSize: 11.5, color: AppTokens.textSecondary),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24.0,
                          height: 24.0,
                          color: sel.severity.accentColor,
                          alignment: Alignment.center,
                          child: Text(
                            '${sel.id}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'PIN #${sel.id}: ${sel.type.label}',
                          style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 12.5),
                        ),
                      ],
                    ),
                    StatusChip(
                      label: sel.severity.label.replaceAll('LEVEL ', 'L'),
                      icon: sel.severity == DefectSeverity.severe ? Icons.priority_high : Icons.warning_amber,
                      type: sel.severity == DefectSeverity.severe
                          ? StatusType.critical
                          : (sel.severity == DefectSeverity.moderate ? StatusType.dueSoon : StatusType.ok),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                Text('VIEW: ${sel.view.label}', style: const TextStyle(fontSize: 11.0, color: AppTokens.textSecondary)),
                if (sel.note != null && sel.note!.isNotEmpty) ...[
                  const SizedBox(height: 6.0),
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    color: AppTokens.base,
                    child: Text('OBSERVATION: ${sel.note}', style: const TextStyle(fontSize: 11.5)),
                  ),
                ],
                const SizedBox(height: 12.0),
                if (!state.isLocked)
                  Row(
                    children: [
                      Expanded(
                        child: SharpButton(
                          label: 'DELETE PIN',
                          icon: Icons.delete_outline,
                          variant: SharpButtonVariant.secondary,
                          onPressed: () => controller.deletePin(sel.id),
                          height: 40.0,
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: SharpButton(
                          label: 'DESELECT',
                          variant: SharpButtonVariant.secondary,
                          onPressed: () => controller.selectPin(null),
                          height: 40.0,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _buildPinsSummaryCard(ConditionMapState state, ConditionMapController controller) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppTokens.surface,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEFECT LEDGER (${state.totalPinCount})',
                style: AppTokens.fontMonospace(fontSize: 11.5, fontWeight: FontWeight.bold),
              ),
              Text(
                '${state.severeCount} S • ${state.moderateCount} M • ${state.minorCount} L',
                style: AppTokens.fontMonospace(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTokens.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          if (state.pins.isEmpty)
            Container(
              padding: const EdgeInsets.all(12.0),
              color: AppTokens.base,
              alignment: Alignment.center,
              child: const Text(
                'No defects logged. Tap on the vehicle schematic to drop pins.',
                style: TextStyle(fontSize: 11.5, color: AppTokens.textSecondary),
              ),
            )
          else
            Column(
              children: state.pins.map((pin) {
                final isSelected = state.selectedPin?.id == pin.id;
                return InkWell(
                  onTap: () {
                    controller.switchView(pin.view);
                    controller.selectPin(pin);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                    color: isSelected ? AppTokens.raised : AppTokens.base,
                    child: Row(
                      children: [
                        Container(
                          width: 20.0,
                          height: 20.0,
                          color: pin.severity.accentColor,
                          alignment: Alignment.center,
                          child: Text(
                            '${pin.id}',
                            style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pin.type.label} (${pin.view.label})',
                                style: AppTokens.fontMonospace(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              if (pin.note != null)
                                Text(
                                  pin.note!,
                                  style: const TextStyle(fontSize: 10.0, color: AppTokens.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          pin.severity.label.replaceAll('LEVEL ', 'L'),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: pin.severity.accentColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(ConditionMapState state) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: AppTokens.inverse,
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1.0)),
      ),
      child: Row(
        children: [
          if (state.isLocked) ...[
            Container(
              padding: const EdgeInsets.all(6.0),
              color: const Color(0xFF00E676),
              child: const Icon(Icons.check, color: Colors.black, size: 18.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIGNED OFF BY ${state.signOff!.customerName.toUpperCase()}',
                    style: AppTokens.fontMonospace(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.0),
                  ),
                  Text(
                    'HASH: ${state.signOff!.sha256Checksum.substring(0, 20)}...',
                    style: AppTokens.fontMonospace(color: const Color(0xFF00E676), fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SharpButton(
              label: 'ADVANCE TO MECHANICAL INSPECTION',
              icon: Icons.arrow_forward,
              onDark: true,
              onPressed: () {
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.go('/mechanical-inspection');
                }
              },
            ),
          ] else ...[
            Expanded(
              child: SharpButton(
                label: 'INITIATE CUSTOMER PRE-WORK SIGN-OFF (${state.totalPinCount} DEFECTS LOGGED)',
                icon: Icons.verified_user_outlined,
                onDark: true,
                onPressed: () => _showPreWorkSignOffModal(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

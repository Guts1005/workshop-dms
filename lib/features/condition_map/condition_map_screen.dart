import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                decoration: const BoxDecoration(
                  color: Color(0xFF111827),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(Icons.add_location_alt_outlined, color: Color(0xFFEF4444), size: 18.0),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'RECORD DEFECT PIN #${state.totalPinCount + 1}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.0,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 480.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'VIEW: ${view.label} • COORD: (${(normalizedPos.dx * 100).toStringAsFixed(1)}%, ${(normalizedPos.dy * 100).toStringAsFixed(1)}%)',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10.5,
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'DEFECT CLASSIFICATION:',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: DefectType.values.map((type) {
                          final isSel = selectedType == type;
                          return ChoiceChip(
                            label: Text(type.label),
                            selected: isSel,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            selectedColor: const Color(0xFF111827),
                            backgroundColor: const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isSel ? const Color(0xFF111827) : const Color(0xFFE2E8F0),
                            ),
                            labelStyle: GoogleFonts.inter(
                              color: isSel ? Colors.white : const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                              fontSize: 11.0,
                            ),
                            onSelected: (val) {
                              if (val) setDialogState(() => selectedType = type);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'SEVERITY LEVEL:',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: DefectSeverity.values.map((sev) {
                          final isSel = selectedSeverity == sev;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3.0),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10.0),
                                onTap: () => setDialogState(() => selectedSeverity = sev),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: isSel ? sev.accentColor : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10.0),
                                    border: Border.all(
                                      color: isSel ? sev.accentColor : const Color(0xFFE2E8F0),
                                      width: isSel ? 2.0 : 1.0,
                                    ),
                                    boxShadow: isSel
                                        ? [
                                            BoxShadow(
                                              color: sev.accentColor.withValues(alpha: 0.3),
                                              blurRadius: 6.0,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    sev.label.replaceAll('LEVEL ', 'L'),
                                    style: GoogleFonts.inter(
                                      color: isSel ? Colors.white : const Color(0xFF334155),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'INSPECTION NOTES / OBSERVED DAMAGE:',
                        style: GoogleFonts.inter(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. 5cm paint gouge down to primer near lower door crease',
                          hintStyle: GoogleFonts.inter(fontSize: 12.0, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'CANCEL',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 12.0,
                    ),
                  ),
                ),
                SharpButton(
                  label: 'SAVE DEFECT PIN',
                  icon: Icons.check,
                  height: 42.0,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 20.0,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 18.0),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                'CUSTOMER PRE-WORK CONDITION SIGN-OFF',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Review recorded exterior defects before commencing repair work. Confirmation locks this condition map and generates an immutable SHA-256 integrity hash.',
                        style: GoogleFonts.inter(fontSize: 12.0, color: const Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 14.0),

                      // Defect Summary Chips
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'TOTAL: ${state.totalPinCount}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5, color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              'SEVERE: ${state.severeCount}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5, color: const Color(0xFFDC2626)),
                            ),
                            Text(
                              'MODERATE: ${state.moderateCount}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5, color: const Color(0xFFEA580C)),
                            ),
                            Text(
                              'MINOR: ${state.minorCount}',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5, color: const Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Customer Details
                      Text(
                        'CUSTOMER FULL NAME *',
                        style: GoogleFonts.inter(fontSize: 11.0, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: customerNameController,
                        decoration: InputDecoration(
                          hintText: 'Customer Name',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'CUSTOMER MOBILE (+91) *',
                        style: GoogleFonts.inter(fontSize: 11.0, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: customerPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '10-digit mobile number',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),

                      Text(
                        'SERVICE ADVISOR SIGNING *',
                        style: GoogleFonts.inter(fontSize: 11.0, fontWeight: FontWeight.w700, color: const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 4.0),
                      TextField(
                        controller: advisorNameController,
                        decoration: InputDecoration(
                          hintText: 'Service Advisor Name / ID',
                          hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),

                      // Customer Consent Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: consentChecked,
                            activeColor: const Color(0xFF111827),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                            onChanged: (val) => setModalState(() => consentChecked = val ?? false),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Customer acknowledges that all pre-existing damages noted above were present prior to workshop handover.',
                                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.35, color: const Color(0xFF1E293B)),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (localError != null) ...[
                        const SizedBox(height: 10.0),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            localError!,
                            style: GoogleFonts.inter(color: const Color(0xFFDC2626), fontSize: 11.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18.0),

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
                                backgroundColor: Color(0xFF10B981),
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
      backgroundColor: const Color(0xFFF6F8FA),
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
                color: const Color(0xFFDC2626),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 16.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC0000),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    '03',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PAGE 3: 360° CONDITION MAP & PRE-WORK SIGN-OFF',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF0F172A),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'JOB: ${state.jobCardId} • VEHICLE: ${state.registrationNumber}',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Row(
            mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12.0),
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
    final isMobile = MediaQuery.of(context).size.width < 700.0;

    if (isMobile) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: ConditionViewDirection.values.map((v) {
              final isSel = state.activeView == v;
              final pinCountInView = state.pins.where((p) => p.view == v).length;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () => controller.switchView(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 40.0,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFF111827) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: isSel
                          ? [
                              const BoxShadow(
                                color: Color(0x18000000),
                                blurRadius: 6.0,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          v.label,
                          style: GoogleFonts.inter(
                            color: isSel ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            fontSize: 11.0,
                          ),
                        ),
                        if (pinCountInView > 0) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Text(
                              '$pinCountInView',
                              style: GoogleFonts.inter(
                                color: isSel ? Colors.white : const Color(0xFF1E293B),
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
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
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: ConditionViewDirection.values.map((v) {
          final isSel = state.activeView == v;
          final pinCountInView = state.pins.where((p) => p.view == v).length;

          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12.0),
              onTap: () => controller.switchView(v),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 42.0,
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF111827) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: isSel
                      ? [
                          const BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 6.0,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.label,
                      style: GoogleFonts.inter(
                        color: isSel ? Colors.white : const Color(0xFF475569),
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 11.0,
                      ),
                    ),
                    if (pinCountInView > 0) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Text(
                          '$pinCountInView',
                          style: GoogleFonts.inter(
                            color: isSel ? Colors.white : const Color(0xFF1E293B),
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
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
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10.0,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
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
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: state.selectedPin?.id == pin.id ? Colors.white : const Color(0xFF0F172A),
                            width: state.selectedPin?.id == pin.id ? 2.5 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pin.severity.accentColor.withValues(alpha: 0.5),
                              blurRadius: state.selectedPin?.id == pin.id ? 8.0 : 4.0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${pin.id}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 3. Instruction Pill Indicator in corner
                Positioned(
                  bottom: 12.0,
                  left: 12.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20000000),
                          blurRadius: 6.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      state.isLocked
                          ? 'MAP LOCKED: PRE-WORK SIGN-OFF RECORDED'
                          : 'TAP SCHEMATIC TO DROP DEFECT PIN [${state.activeView.label}]',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: sel == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DEFECT INSPECTOR',
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Tap any numbered pin on the vehicle schematic to inspect or delete.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
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
                          width: 26.0,
                          height: 26.0,
                          decoration: BoxDecoration(
                            color: sel.severity.accentColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${sel.id}',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.0),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Text(
                          'PIN #${sel.id}: ${sel.type.label}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 13.0, color: const Color(0xFF0F172A)),
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
                Text(
                  'VIEW: ${sel.view.label}',
                  style: GoogleFonts.inter(fontSize: 11.0, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                if (sel.note != null && sel.note!.isNotEmpty) ...[
                  const SizedBox(height: 8.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      'OBSERVATION: ${sel.note}',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155)),
                    ),
                  ),
                ],
                const SizedBox(height: 14.0),
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
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEFECT LEDGER (${state.totalPinCount})',
                style: GoogleFonts.inter(
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '${state.severeCount} S • ${state.moderateCount} M • ${state.minorCount} L',
                style: GoogleFonts.inter(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          if (state.pins.isEmpty)
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(
                'No defects logged. Tap on the vehicle schematic to drop pins.',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            )
          else
            Column(
              children: state.pins.map((pin) {
                final isSelected = state.selectedPin?.id == pin.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(10.0),
                  onTap: () {
                    controller.switchView(pin.view);
                    controller.selectPin(pin);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.only(bottom: 6.0),
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10.0),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 22.0,
                          height: 22.0,
                          decoration: BoxDecoration(
                            color: pin.severity.accentColor,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${pin.id}',
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pin.type.label} (${pin.view.label})',
                                style: GoogleFonts.inter(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (pin.note != null)
                                Text(
                                  pin.note!,
                                  style: GoogleFonts.inter(fontSize: 10.0, color: const Color(0xFF64748B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text(
                          pin.severity.label.replaceAll('LEVEL ', 'L'),
                          style: GoogleFonts.inter(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w800,
                            color: pin.severity.accentColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10.0,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (state.isLocked) ...[
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF10B981), size: 18.0),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SIGNED OFF BY ${state.signOff!.customerName.toUpperCase()}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w800,
                      fontSize: 12.0,
                    ),
                  ),
                  Text(
                    'HASH: ${state.signOff!.sha256Checksum.substring(0, 20)}...',
                    style: GoogleFonts.jetBrainsMono(
                      color: const Color(0xFF047857),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SharpButton(
              label: 'ADVANCE TO MECHANICAL INSPECTION',
              icon: Icons.arrow_forward,
              height: 46.0,
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
                height: 46.0,
                onPressed: () => _showPreWorkSignOffModal(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

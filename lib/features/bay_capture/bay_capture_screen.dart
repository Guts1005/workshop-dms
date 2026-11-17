import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../camera_capture/camera_capture_module.dart';
import '../../ui_kit/widgets/sharp_button.dart';
import '../../ui_kit/widgets/status_chip.dart';
import 'bay_capture_controller.dart';
import 'bay_capture_models.dart';

class BayCaptureScreen extends ConsumerStatefulWidget {
  final String? jobCardId;
  final String? registrationNumber;

  const BayCaptureScreen({
    super.key,
    this.jobCardId,
    this.registrationNumber,
  });

  @override
  ConsumerState<BayCaptureScreen> createState() => _BayCaptureScreenState();
}

class _BayCaptureScreenState extends ConsumerState<BayCaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobCardId != null || widget.registrationNumber != null) {
        ref.read(bayCaptureControllerProvider.notifier).initSession(
              jobCardId: widget.jobCardId ?? 'JC-${DateTime.now().millisecondsSinceEpoch}',
              registrationNumber: widget.registrationNumber ?? 'RJ27CA1024',
            );
      }
    });
  }

  void _showManagerOverrideDialog() {
    final state = ref.read(bayCaptureControllerProvider);
    final controller = ref.read(bayCaptureControllerProvider.notifier);
    final managerNameController = TextEditingController(text: state.managerOverride?.authorizedBy ?? '');
    final reasonController = TextEditingController(text: state.managerOverride?.reason ?? '');
    String? localError;

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
                      child: const Icon(Icons.security, color: Color(0xFFEF4444), size: 18.0),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'MANAGER OVERRIDE AUTHORIZATION',
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
                      Text(
                        'A Manager Override allows bypassing missing mandatory check-in shots when capture is physically impossible (e.g. accident damage, vehicle covered, workshop camera malfunction).',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MISSING MANDATORY SHOTS (${state.missingMandatoryShots.length}):',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.0,
                                color: const Color(0xFFDC2626),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            for (final shot in state.missingMandatoryShots)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.circle, size: 5.0, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 6.0),
                                    Expanded(
                                      child: Text(
                                        shot.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF991B1B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text(
                        'AUTHORIZED MANAGER NAME / PIN *',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: managerNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Rajesh Kumar (Workshop Mgr)',
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'JUSTIFICATION / REASON *',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                          color: const Color(0xFF475569),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Vehicle arrived on flatbed with severe front-end impact, bumper missing',
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
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                          ),
                        ),
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
                            style: GoogleFonts.inter(
                              color: const Color(0xFFDC2626),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
              actions: [
                if (state.isOverrideActive)
                  TextButton(
                    onPressed: () {
                      controller.removeManagerOverride();
                      Navigator.of(ctx).pop();
                    },
                    child: Text(
                      'REVOKE OVERRIDE',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.0,
                      ),
                    ),
                  ),
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
                  label: 'AUTHORIZE OVERRIDE',
                  height: 42.0,
                  onPressed: () async {
                    final err = controller.validateManagerOverride(
                      authorizedBy: managerNameController.text,
                      reason: reasonController.text,
                    );
                    if (err != null) {
                      setDialogState(() => localError = err);
                      return;
                    }
                    final ok = await controller.applyManagerOverride(
                      authorizedBy: managerNameController.text,
                      reason: reasonController.text,
                    );
                    if (ok && dialogCtx.mounted) {
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bayCaptureControllerProvider);
    final controller = ref.read(bayCaptureControllerProvider.notifier);
    final isNarrow = MediaQuery.of(context).size.width < 900.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Header & Telemetry Bar
            _buildHeaderBar(state),

            // Error Notice Banner (if any)
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                color: const Color(0xFFDC2626),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18.0),
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

            // Bottom Gated Action Bar
            _buildBottomActionBar(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(BayCaptureState state) {
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
                    '02',
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
                        'PAGE 2: BAY CHECK-IN CAPTURE',
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
              if (state.isOverrideActive)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: StatusChip(
                    label: 'OVERRIDE: ${state.managerOverride!.authorizedBy.toUpperCase()}',
                    icon: Icons.shield,
                    type: StatusType.dueSoon,
                  ),
                ),
              StatusChip(
                label: '${state.mandatoryCompletedCount}/${state.totalMandatoryCount} MANDATORY',
                icon: state.isAllMandatoryCaptured ? Icons.check_circle : Icons.camera_alt,
                type: state.isAllMandatoryCaptured ? StatusType.ok : StatusType.dueSoon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BayCaptureState state, BayCaptureController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildActiveShotGuidanceCard(state),
          const SizedBox(height: 12.0),
          _buildCameraWorkspace(state, controller, height: 340.0),
          const SizedBox(height: 14.0),
          _buildShotsGrid(state, controller, crossAxisCount: 2),
        ],
      ),
    );
  }

  Widget _buildWideLayout(BayCaptureState state, BayCaptureController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Shot Selector & Visual Progress List
          SizedBox(
            width: 380.0,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildActiveShotGuidanceCard(state),
                  const SizedBox(height: 12.0),
                  _buildShotsList(state, controller),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          // Right Area: Active Hardware Camera View / Review Frame
          Expanded(
            child: _buildCameraWorkspace(state, controller, height: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveShotGuidanceCard(BayCaptureState state) {
    final active = state.activeShotType;
    final captured = state.capturedPhotos[active];

    return Container(
      padding: const EdgeInsets.all(14.0),
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
                'TARGET SLOT:',
                style: GoogleFonts.inter(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              StatusChip(
                label: active.isMandatory ? 'MANDATORY' : 'OPTIONAL',
                icon: active.isMandatory ? Icons.priority_high : Icons.info_outline,
                type: active.isMandatory ? StatusType.critical : StatusType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            active.title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            active.instruction,
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
          ),
          if (captured != null) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 14.0),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      'VERIFIED: ${captured.sha256Hash.substring(0, 16)}...',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: const Color(0xFF047857),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCameraWorkspace(BayCaptureState state, BayCaptureController controller, {required double height}) {
    final active = state.activeShotType;
    final captured = state.capturedPhotos[active];

    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16.0),
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (captured != null)
            // Captured Shot Evidence Card with instant RETAKE action
            _buildCapturedEvidenceCard(active, captured, controller)
          else
            // Real Hardware Camera Capture with intelligent visual guides
            CameraCaptureModule(
              key: ValueKey(active.name),
              title: active.title,
              instruction: active.instruction,
              shotType: active,
              onPhotoConfirmed: (photoPath, hash, sizeBytes) async {
                await controller.recordCapturedPhoto(
                  shotType: active,
                  filePath: photoPath,
                  sha256Hash: hash,
                  fileSizeBytes: sizeBytes,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCapturedEvidenceCard(
    CheckInShotType active,
    CapturedCheckInPhoto captured,
    BayCaptureController controller,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 48.0),
          ),
          const SizedBox(height: 14.0),
          Text(
            '${active.title} RECORDED',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  'TAMPER-PROOF SHA-256 HASH:',
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  captured.sha256Hash,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.0,
                    color: const Color(0xFF047857),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'TIMESTAMP: ${captured.capturedAt.toLocal()} • SIZE: ${(captured.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          SharpButton(
            label: 'RETAKE THIS SHOT',
            icon: Icons.refresh,
            variant: SharpButtonVariant.secondary,
            onPressed: () => controller.retakeShot(active),
            width: 220.0,
            height: 46.0,
          ),
        ],
      ),
    );
  }

  Widget _buildShotsList(BayCaptureState state, BayCaptureController controller) {
    return Column(
      children: [
        for (final shot in CheckInShotType.values)
          _buildShotTile(shot, state, controller),
      ],
    );
  }

  Widget _buildShotsGrid(BayCaptureState state, BayCaptureController controller, {required int crossAxisCount}) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      childAspectRatio: 2.3,
      children: [
        for (final shot in CheckInShotType.values)
          _buildShotTile(shot, state, controller),
      ],
    );
  }

  Widget _buildShotTile(CheckInShotType shot, BayCaptureState state, BayCaptureController controller) {
    final isSelected = state.activeShotType == shot;
    final isCaptured = state.capturedPhotos.containsKey(shot);

    return InkWell(
      borderRadius: BorderRadius.circular(14.0),
      onTap: () => controller.selectShot(shot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFBFBFD),
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF111827)
                : (isCaptured ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? const Color(0x12000000) : const Color(0x04000000),
              blurRadius: isSelected ? 8.0 : 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 28.0,
              height: 28.0,
              decoration: BoxDecoration(
                color: isCaptured
                    ? const Color(0xFF10B981)
                    : (shot.isMandatory ? const Color(0xFFCC0000) : const Color(0xFF64748B)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              alignment: Alignment.center,
              child: Icon(
                isCaptured ? Icons.check : (shot.isMandatory ? Icons.priority_high : Icons.camera_alt),
                color: Colors.white,
                size: 15.0,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shot.title,
                    style: GoogleFonts.inter(
                      fontSize: 11.0,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    isCaptured ? 'VERIFIED (SHA-256)' : (shot.isMandatory ? 'REQUIRED' : 'OPTIONAL'),
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: isCaptured
                          ? const Color(0xFF059669)
                          : (shot.isMandatory ? const Color(0xFFDC2626) : const Color(0xFF94A3B8)),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar(BayCaptureState state, BayCaptureController controller) {
    final isNarrow = MediaQuery.of(context).size.width < 600.0;

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
      child: isNarrow
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SharpButton(
                  label: state.canFinalizeCheckIn
                      ? 'FINALIZE CHECK-IN & OPEN 360° CONDITION MAP'
                      : 'LOCKED: ${state.mandatoryCompletedCount}/6 SHOTS REQUIRED TO OPEN JOB CARD',
                  icon: state.canFinalizeCheckIn ? Icons.arrow_forward : Icons.lock_outline,
                  height: 48.0,
                  onPressed: state.canFinalizeCheckIn
                      ? () async {
                          final ok = await controller.finalizeCheckIn();
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Bay Check-in complete. Advancing to 360° Condition Map.'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                            final router = GoRouter.maybeOf(context);
                            if (router != null) {
                              router.go('/condition-map');
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 8.0),
                SharpButton(
                  label: state.isOverrideActive ? 'VIEW OVERRIDE' : 'MANAGER OVERRIDE',
                  icon: Icons.admin_panel_settings_outlined,
                  variant: SharpButtonVariant.secondary,
                  height: 42.0,
                  onPressed: _showManagerOverrideDialog,
                ),
              ],
            )
          : Row(
              children: [
                // Manager Override Action Button
                SharpButton(
                  label: state.isOverrideActive ? 'VIEW OVERRIDE' : 'MANAGER OVERRIDE',
                  icon: Icons.admin_panel_settings_outlined,
                  variant: SharpButtonVariant.secondary,
                  height: 46.0,
                  onPressed: _showManagerOverrideDialog,
                ),
                const SizedBox(width: 12.0),
                // Finalize Check-in Gate Button
                Expanded(
                  child: SharpButton(
                    label: state.canFinalizeCheckIn
                        ? 'FINALIZE CHECK-IN & OPEN 360° CONDITION MAP'
                        : 'LOCKED: ${state.mandatoryCompletedCount}/6 SHOTS REQUIRED TO OPEN JOB CARD',
                    icon: state.canFinalizeCheckIn ? Icons.arrow_forward : Icons.lock_outline,
                    height: 46.0,
                    onPressed: state.canFinalizeCheckIn
                        ? () async {
                            final ok = await controller.finalizeCheckIn();
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Bay Check-in complete. Advancing to 360° Condition Map.'),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                              final router = GoRouter.maybeOf(context);
                              if (router != null) {
                                router.go('/condition-map');
                              }
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
    );
  }
}

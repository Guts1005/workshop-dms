import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../camera_capture/camera_capture_module.dart';
import '../../ui_kit/tokens/app_tokens.dart';
import '../../ui_kit/widgets/sharp_button.dart';
import '../../ui_kit/widgets/status_chip.dart';
import 'bay_capture_controller.dart';
import 'bay_capture_models.dart';

class BayCaptureScreen extends ConsumerStatefulWidget {
  final String? jobCardId;
  final String? registrationNumber;

  const BayCaptureScreen({super.key, this.jobCardId, this.registrationNumber});

  @override
  ConsumerState<BayCaptureScreen> createState() => _BayCaptureScreenState();
}

class _BayCaptureScreenState extends ConsumerState<BayCaptureScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.jobCardId != null || widget.registrationNumber != null) {
        ref
            .read(bayCaptureControllerProvider.notifier)
            .initSession(
              jobCardId: widget.jobCardId ?? '',
              registrationNumber: widget.registrationNumber ?? '',
            );
      }
    });
  }

  void _showManagerOverrideDialog() {
    final state = ref.read(bayCaptureControllerProvider);
    final controller = ref.read(bayCaptureControllerProvider.notifier);
    final managerNameController = TextEditingController(
      text: state.managerOverride?.authorizedBy ?? '',
    );
    final reasonController = TextEditingController(
      text: state.managerOverride?.reason ?? '',
    );
    String? localError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTokens.raised,
              shape: const RoundedRectangleBorder(
                borderRadius: AppTokens.cardRadius,
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18.0,
                  vertical: 14.0,
                ),
                decoration: const BoxDecoration(
                  color: AppTokens.inverse,
                  borderRadius: AppTokens.cardRadius,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: AppTokens.brandRed.withValues(alpha: 0.15),
                        borderRadius: AppTokens.cardRadius,
                      ),
                      child: const Icon(
                        Icons.security,
                        color: AppTokens.brandRed,
                        size: 18.0,
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'MANAGER OVERRIDE AUTHORIZATION',
                        style: GoogleFonts.inter(
                          color: AppTokens.raised,
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
                          color: AppTokens.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppTokens.surfaceSubtle,
                          borderRadius: AppTokens.cardRadius,
                          border: Border.all(color: AppTokens.surfaceSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MISSING MANDATORY SHOTS (${state.missingMandatoryShots.length}):',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.0,
                                color: AppTokens.brandRed,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            for (final shot in state.missingMandatoryShots)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.circle,
                                      size: 5.0,
                                      color: AppTokens.brandRed,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Expanded(
                                      child: Text(
                                        shot.title,
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppTokens.brandRed,
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
                          color: AppTokens.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: managerNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Rajesh Kumar (Workshop Mgr)',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppTokens.textTertiary,
                          ),
                          filled: true,
                          fillColor: AppTokens.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.borderLight,
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.borderLight,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.inverse,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text(
                        'JUSTIFICATION / REASON *',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.0,
                          color: AppTokens.textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g. Vehicle arrived on flatbed with severe front-end impact, bumper missing',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: AppTokens.textTertiary,
                          ),
                          filled: true,
                          fillColor: AppTokens.surface,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          border: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.borderLight,
                            ),
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.borderLight,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: AppTokens.cardRadius,
                            borderSide: BorderSide(
                              color: AppTokens.inverse,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 10.0),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: const BoxDecoration(
                            color: AppTokens.surfaceSubtle,
                            borderRadius: AppTokens.cardRadius,
                          ),
                          child: Text(
                            localError!,
                            style: GoogleFonts.inter(
                              color: AppTokens.brandRed,
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
              actionsPadding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 14.0,
              ),
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
                        color: AppTokens.brandRed,
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
                      color: AppTokens.textSecondary,
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

    if (state.jobCardId.isEmpty || state.registrationNumber.isEmpty) {
      return Scaffold(
        backgroundColor: AppTokens.base,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.assignment_outlined, size: 40),
                const SizedBox(height: 16),
                Text(
                  'Open check-in from an application',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an active application first so photos and inspection details are saved to the right vehicle.',
                  style: AppTokens.fontBody(color: AppTokens.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SharpButton(
                  label: 'Go to Applications',
                  onPressed: () => context.go('/applications'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTokens.base,
      body: SafeArea(
        child: Column(
          children: [
            // Top Stage Header & Telemetry Bar
            _buildHeaderBar(state),

            // Error Notice Banner (if any)
            if (state.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                color: AppTokens.brandRed,
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTokens.raised,
                      size: 18.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: GoogleFonts.inter(
                          color: AppTokens.raised,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content Zone (Responsive, zero horizontal overflow)
            Expanded(
              child: isNarrow
                  ? _buildNarrowLayout(state, controller)
                  : _buildWideLayout(state, controller),
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
        color: AppTokens.raised,
        border: Border(
          bottom: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
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
                InkWell(
                  borderRadius: AppTokens.cardRadius,
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/bays');
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.arrow_back,
                      size: 20.0,
                      color: AppTokens.inverse,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTokens.brandRed,
                    borderRadius: AppTokens.inputRadius,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppTokens.raised,
                    size: 14.0,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHOTO INSPECTION',
                        style: GoogleFonts.inter(
                          color: AppTokens.textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'JOB: ${state.jobCardId} â€¢ VEHICLE: ${state.registrationNumber}',
                        style: GoogleFonts.inter(
                          color: AppTokens.textSecondary,
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
                    label:
                        'OVERRIDE: ${state.managerOverride!.authorizedBy.toUpperCase()}',
                    icon: Icons.shield,
                    type: StatusType.dueSoon,
                  ),
                ),
              StatusChip(
                label:
                    '${state.mandatoryCompletedCount}/${state.totalMandatoryCount} MANDATORY',
                icon: state.isAllMandatoryCaptured
                    ? Icons.check_circle
                    : Icons.camera_alt,
                type: state.isAllMandatoryCaptured
                    ? StatusType.ok
                    : StatusType.dueSoon,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
    BayCaptureState state,
    BayCaptureController controller,
  ) {
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

  Widget _buildWideLayout(
    BayCaptureState state,
    BayCaptureController controller,
  ) {
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
            child: _buildCameraWorkspace(
              state,
              controller,
              height: double.infinity,
            ),
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
        color: AppTokens.raised,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderLight),
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
                  color: AppTokens.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              StatusChip(
                label: active.isMandatory ? 'MANDATORY' : 'OPTIONAL',
                icon: active.isMandatory
                    ? Icons.priority_high
                    : Icons.info_outline,
                type: active.isMandatory
                    ? StatusType.critical
                    : StatusType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            active.title,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: AppTokens.inverse,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            active.instruction,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppTokens.textSecondary,
              height: 1.35,
            ),
          ),
          if (captured != null) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 6.0,
              ),
              decoration: BoxDecoration(
                color: AppTokens.surfaceSubtle,
                borderRadius: AppTokens.cardRadius,
                border: Border.all(color: AppTokens.green),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTokens.green,
                    size: 14.0,
                  ),
                  const SizedBox(width: 6.0),
                  Expanded(
                    child: Text(
                      'VERIFIED: ${captured.sha256Hash.substring(0, 16)}...',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9.5,
                        color: AppTokens.green,
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

  Widget _buildCameraWorkspace(
    BayCaptureState state,
    BayCaptureController controller, {
    required double height,
  }) {
    final active = state.activeShotType;
    final captured = state.capturedPhotos[active];

    return Container(
      height: height == double.infinity ? null : height,
      decoration: BoxDecoration(
        color: AppTokens.inverse,
        borderRadius: AppTokens.cardRadius,
        border: Border.all(color: AppTokens.borderLight),
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
              onPhotoConfirmed: (photoPath, hash, sizeBytes, bytes) async {
                await controller.recordCapturedPhoto(
                  shotType: active,
                  filePath: photoPath,
                  sha256Hash: hash,
                  fileSizeBytes: sizeBytes,
                  bytes: bytes,
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
      color: AppTokens.raised,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: AppTokens.surfaceSubtle,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTokens.green,
              size: 48.0,
            ),
          ),
          const SizedBox(height: 14.0),
          Text(
            '${active.title} RECORDED',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTokens.inverse,
              fontWeight: FontWeight.w900,
              fontSize: 16.0,
            ),
          ),
          const SizedBox(height: 10.0),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: AppTokens.cardRadius,
              border: Border.all(color: AppTokens.borderLight),
            ),
            child: Column(
              children: [
                Text(
                  'TAMPER-PROOF SHA-256 HASH:',
                  style: GoogleFonts.inter(
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  captured.sha256Hash,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.0,
                    color: AppTokens.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'TIMESTAMP: ${captured.capturedAt.toLocal()} â€¢ SIZE: ${(captured.fileSizeBytes / 1024).toStringAsFixed(1)} KB',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    color: AppTokens.textSecondary,
                  ),
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

  Widget _buildShotsList(
    BayCaptureState state,
    BayCaptureController controller,
  ) {
    return Column(
      children: [
        for (final shot in CheckInShotType.values)
          _buildShotTile(shot, state, controller),
      ],
    );
  }

  Widget _buildShotsGrid(
    BayCaptureState state,
    BayCaptureController controller, {
    required int crossAxisCount,
  }) {
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

  Widget _buildShotTile(
    CheckInShotType shot,
    BayCaptureState state,
    BayCaptureController controller,
  ) {
    final isSelected = state.activeShotType == shot;
    final isCaptured = state.capturedPhotos.containsKey(shot);

    return InkWell(
      borderRadius: AppTokens.cardRadius,
      onTap: () => controller.selectShot(shot),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.raised : AppTokens.base,
          borderRadius: AppTokens.cardRadius,
          border: Border.all(
            color: isSelected
                ? AppTokens.inverse
                : (isCaptured ? AppTokens.green : AppTokens.borderLight),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0x12000000)
                  : const Color(0x04000000),
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
                    ? AppTokens.green
                    : (shot.isMandatory
                          ? AppTokens.brandRed
                          : AppTokens.textSecondary),
                borderRadius: AppTokens.cardRadius,
              ),
              alignment: Alignment.center,
              child: Icon(
                isCaptured
                    ? Icons.check
                    : (shot.isMandatory
                          ? Icons.priority_high
                          : Icons.camera_alt),
                color: AppTokens.raised,
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
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? AppTokens.inverse
                          : AppTokens.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    isCaptured
                        ? 'VERIFIED (SHA-256)'
                        : (shot.isMandatory ? 'REQUIRED' : 'OPTIONAL'),
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: isCaptured
                          ? AppTokens.green
                          : (shot.isMandatory
                                ? AppTokens.brandRed
                                : AppTokens.textTertiary),
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

  Widget _buildBottomActionBar(
    BayCaptureState state,
    BayCaptureController controller,
  ) {
    final isNarrow = MediaQuery.of(context).size.width < 600.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: AppTokens.raised,
        border: Border(
          top: BorderSide(color: AppTokens.borderLight, width: 1.0),
        ),
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
                      ? 'Continue to condition report'
                      : 'Continue to condition report',
                  icon: Icons.arrow_forward,
                  height: 48.0,
                  onPressed: state.canFinalizeCheckIn
                      ? () async {
                          final ok = await controller.finalizeCheckIn();
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.missingMandatoryShots.isEmpty
                                      ? 'Check-in saved. Continue with the vehicle condition report.'
                                      : 'Check-in saved. ${state.missingMandatoryShots.length} photo(s) remain to be captured.',
                                ),
                                backgroundColor: AppTokens.green,
                              ),
                            );
                            final router = GoRouter.maybeOf(context);
                            if (router != null) {
                              router.go(
                                '/condition-map',
                                extra: {
                                  'jobCardId': state.jobCardId,
                                  'registrationNumber':
                                      state.registrationNumber,
                                },
                              );
                            }
                          }
                        }
                      : null,
                ),
                const SizedBox(height: 8.0),
                SharpButton(
                  label: state.isOverrideActive
                      ? 'VIEW OVERRIDE'
                      : 'MANAGER OVERRIDE',
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
                  label: state.isOverrideActive
                      ? 'VIEW OVERRIDE'
                      : 'MANAGER OVERRIDE',
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
                        ? 'Continue to condition report'
                        : 'Continue to condition report',
                    icon: Icons.arrow_forward,
                    height: 46.0,
                    onPressed: state.canFinalizeCheckIn
                        ? () async {
                            final ok = await controller.finalizeCheckIn();
                            if (ok && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    state.missingMandatoryShots.isEmpty
                                        ? 'Check-in saved. Continue with the vehicle condition report.'
                                        : 'Check-in saved. ${state.missingMandatoryShots.length} photo(s) remain to be captured.',
                                  ),
                                  backgroundColor: AppTokens.green,
                                ),
                              );
                              final router = GoRouter.maybeOf(context);
                              if (router != null) {
                                router.go(
                                  '/condition-map',
                                  extra: {
                                    'jobCardId': state.jobCardId,
                                    'registrationNumber':
                                        state.registrationNumber,
                                  },
                                );
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

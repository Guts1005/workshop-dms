import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../camera_capture/camera_capture_module.dart';
import '../../ui_kit/tokens/app_tokens.dart';
import '../../ui_kit/widgets/sharp_button.dart';
import '../../ui_kit/widgets/status_chip.dart';
import 'bay_camera_guides.dart';
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

  Future<void> _simulateDesktopCapture(CheckInShotType shotType) async {
    final controller = ref.read(bayCaptureControllerProvider.notifier);
    final mockBytes = List<int>.generate(256, (i) => (i * 7 + shotType.index) % 256);
    final hash = CapturedCheckInPhoto.computeHash(mockBytes);

    final path = kIsWeb
        ? 'simulated://${shotType.name}.jpg'
        : p.join(Directory.systemTemp.path, 'simulated_${shotType.name}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    await controller.recordCapturedPhoto(
      shotType: shotType,
      filePath: path,
      sha256Hash: hash,
      fileSizeBytes: mockBytes.length,
    );
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
              backgroundColor: AppTokens.surface,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                color: AppTokens.inverse,
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppTokens.redOrange, size: 20.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'MANAGER OVERRIDE AUTHORIZATION',
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
                width: 480.0,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'A Manager Override allows bypassing missing mandatory check-in shots when capture is physically impossible (e.g. accident damage, vehicle covered, workshop camera malfunction).',
                        style: TextStyle(fontSize: 12.5, color: AppTokens.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 12.0),
                      Container(
                        padding: const EdgeInsets.all(10.0),
                        color: AppTokens.base,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MISSING MANDATORY SHOTS (${state.missingMandatoryShots.length}):',
                              style: AppTokens.fontMonospace(
                                fontWeight: FontWeight.bold,
                                fontSize: 11.0,
                                color: AppTokens.redOrange,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            for (final shot in state.missingMandatoryShots)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text('• ${shot.title}', style: const TextStyle(fontSize: 11.5)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Text('AUTHORIZED MANAGER NAME / PIN *',
                          style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.0)),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: managerNameController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Rajesh Kumar (Workshop Mgr)',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Text('JUSTIFICATION / REASON *',
                          style: AppTokens.fontMonospace(fontWeight: FontWeight.bold, fontSize: 11.0)),
                      const SizedBox(height: 6.0),
                      TextField(
                        controller: reasonController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Vehicle arrived on flatbed with severe front-end impact, bumper missing',
                          filled: true,
                          fillColor: AppTokens.raised,
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                      ),
                      if (localError != null) ...[
                        const SizedBox(height: 10.0),
                        Text(
                          localError!,
                          style: const TextStyle(color: AppTokens.redOrange, fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (state.isOverrideActive)
                  TextButton(
                    onPressed: () {
                      controller.removeManagerOverride();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('REVOKE OVERRIDE', style: TextStyle(color: AppTokens.redOrange)),
                  ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL', style: TextStyle(color: AppTokens.textPrimary)),
                ),
                SharpButton(
                  label: 'AUTHORIZE OVERRIDE',
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                color: AppTokens.redOrange,
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white, size: 18.0),
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

            // Main Content Zone
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
                  '02',
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
                    'PAGE 2: BAY CHECK-IN CAPTURE',
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
          _buildCameraWorkspace(state, controller, height: 320.0),
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
          // Left Sidebar: Shot Selector and Progress
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
          // Right Area: Active Camera View / Review Frame
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
      padding: const EdgeInsets.all(12.0),
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
                'TARGET SLOT:',
                style: AppTokens.fontMonospace(fontSize: 10.0, fontWeight: FontWeight.bold, color: AppTokens.textSecondary),
              ),
              StatusChip(
                label: active.isMandatory ? 'MANDATORY' : 'OPTIONAL',
                icon: active.isMandatory ? Icons.priority_high : Icons.info_outline,
                type: active.isMandatory ? StatusType.critical : StatusType.neutral,
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            active.title,
            style: AppTokens.fontMonospace(fontSize: 13.0, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4.0),
          Text(
            active.instruction,
            style: const TextStyle(fontSize: 12.0, color: AppTokens.textSecondary),
          ),
          if (captured != null) ...[
            const SizedBox(height: 8.0),
            Container(
              padding: const EdgeInsets.all(6.0),
              color: AppTokens.base,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HASH (SHA-256):', style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.bold)),
                  Text(
                    captured.sha256Hash,
                    style: AppTokens.fontMonospace(fontSize: 9.0, color: AppTokens.green, fontWeight: FontWeight.bold),
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
        color: AppTokens.inverse,
        border: Border.all(color: AppTokens.borderSolid, width: 1.0),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // If already captured and not actively retaking, show preview thumbnail
          if (captured != null)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, color: AppTokens.green, size: 54.0),
                const SizedBox(height: 12.0),
                Text(
                  '${active.title} CAPTURED',
                  style: AppTokens.fontMonospace(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14.0),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'SHA-256: ${captured.sha256Hash.substring(0, 16)}...',
                  style: AppTokens.fontMonospace(color: AppTokens.surface, fontSize: 11.0),
                ),
                const SizedBox(height: 16.0),
                SharpButton(
                  label: 'RETAKE THIS SHOT',
                  variant: SharpButtonVariant.secondary,
                  onPressed: () => controller.retakeShot(active),
                  width: 200.0,
                ),
              ],
            )
          else if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
            // Native Mobile Camera Module
            CameraCaptureModule(
              title: active.title,
              instruction: active.instruction,
              wireframeGuide: BayCameraGuidePainter(shotType: active),
              onPhotoConfirmed: (file, hash) async {
                final len = await file.length();
                await controller.recordCapturedPhoto(
                  shotType: active,
                  filePath: file.path,
                  sha256Hash: hash,
                  fileSizeBytes: len,
                );
              },
            )
          else
            // Desktop / Web / Testing Fallback Simulator
            Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                constraints: const BoxConstraints(maxWidth: 420.0),
                decoration: BoxDecoration(
                  color: AppTokens.surface,
                  border: Border.all(color: AppTokens.borderSolid, width: 1.0),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_outlined, size: 48.0, color: AppTokens.textPrimary),
                    const SizedBox(height: 12.0),
                    Text(
                      'BAY CAMERA: ${active.title}',
                      textAlign: TextAlign.center,
                      style: AppTokens.fontMonospace(fontWeight: FontWeight.w900, fontSize: 13.0),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      active.instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12.0, color: AppTokens.textSecondary),
                    ),
                    const SizedBox(height: 16.0),
                    SharpButton(
                      label: 'CAPTURE SHOT NOW',
                      icon: Icons.camera,
                      onPressed: () => _simulateDesktopCapture(active),
                    ),
                  ],
                ),
              ),
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
      childAspectRatio: 2.2,
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
      onTap: () => controller.selectShot(shot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6.0),
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppTokens.raised : AppTokens.surface,
          border: Border.all(
            color: isSelected ? AppTokens.borderSolid : const Color(0xFFCCCCCC),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24.0,
              height: 24.0,
              color: isCaptured
                  ? AppTokens.green
                  : (shot.isMandatory ? AppTokens.redOrange : AppTokens.inverse),
              alignment: Alignment.center,
              child: Icon(
                isCaptured ? Icons.check : (shot.isMandatory ? Icons.priority_high : Icons.camera),
                color: Colors.white,
                size: 14.0,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    shot.title,
                    style: AppTokens.fontMonospace(
                      fontSize: 10.5,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isCaptured ? 'VERIFIED (SHA-256)' : (shot.isMandatory ? 'REQUIRED' : 'OPTIONAL'),
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isCaptured ? AppTokens.green : (shot.isMandatory ? AppTokens.redOrange : AppTokens.textSecondary),
                      fontWeight: FontWeight.bold,
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
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: AppTokens.inverse,
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1.0)),
      ),
      child: Row(
        children: [
          // Manager Override Action Button
          SharpButton(
            label: state.isOverrideActive ? 'VIEW OVERRIDE' : 'MANAGER OVERRIDE',
            icon: Icons.admin_panel_settings_outlined,
            variant: SharpButtonVariant.secondary,
            onDark: true,
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
              onDark: true,
              onPressed: state.canFinalizeCheckIn
                  ? () async {
                      final ok = await controller.finalizeCheckIn();
                      if (ok && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Bay Check-in complete. Advancing to 360° Condition Map.'),
                            backgroundColor: AppTokens.green,
                          ),
                        );
                        context.go('/condition-map');
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

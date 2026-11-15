import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../ui_kit/tokens/app_tokens.dart';
import '../ui_kit/widgets/sharp_button.dart';

typedef QualityCheckCallback = Future<bool> Function(File photo);

class CameraCaptureModule extends StatefulWidget {
  final String title;
  final String instruction;
  final CustomPainter? wireframeGuide;
  final Function(File photo, String sha256Hash) onPhotoConfirmed;
  final QualityCheckCallback? onQualityCheck;

  const CameraCaptureModule({
    super.key,
    required this.title,
    required this.instruction,
    this.wireframeGuide,
    required this.onPhotoConfirmed,
    this.onQualityCheck,
  });

  @override
  State<CameraCaptureModule> createState() => _CameraCaptureModuleState();
}

enum _ModulePermissionState { prompt, checking, granted, denied }

class _CameraCaptureModuleState extends State<CameraCaptureModule> with WidgetsBindingObserver {
  _ModulePermissionState _permissionState = _ModulePermissionState.prompt;
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitializing = false;
  String? _errorMessage;

  // Staged capture for review & quality check
  File? _stagedPhoto;
  String? _stagedHash;
  bool _isProcessing = false;
  String? _qualityWarning;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      if (_permissionState == _ModulePermissionState.granted && _stagedPhoto == null) {
        _initCamera();
      }
    }
  }

  Future<void> _disposeController() async {
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        await c.dispose();
      } catch (e) {
        debugPrint('Error disposing camera: $e');
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission() async {
    setState(() => _permissionState = _ModulePermissionState.checking);
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() => _permissionState = _ModulePermissionState.granted);
        await _initCamera();
      } else {
        setState(() => _permissionState = _ModulePermissionState.denied);
      }
    } else {
      setState(() => _permissionState = _ModulePermissionState.granted);
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _errorMessage = null;
    if (mounted) setState(() {});

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('NoCamerasFound', 'No camera hardware detected on this device.');
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _controller = controller;
    } catch (e) {
      _errorMessage = e.toString();
      _disposeController();
    } finally {
      _isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _takeShutter() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile rawShot = await c.takePicture();
      final bytes = await rawShot.readAsBytes();

      // 1. Compute SHA-256 on raw device bytes
      final hash = sha256.convert(bytes).toString();

      // 2. Write to App Sandbox directory only
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String bayDir = p.join(appDocDir.path, 'bay_captures');
      final Directory targetDir = Directory(bayDir);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final String fileName = 'shot_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String destinationPath = p.join(targetDir.path, fileName);
      final File permanentFile = await File(rawShot.path).copy(destinationPath);

      // 3. Optional Quality Check Hook
      String? warning;
      if (widget.onQualityCheck != null) {
        final passed = await widget.onQualityCheck!(permanentFile);
        if (!passed) {
          warning = 'Photo may be blurry or poorly lit. Verify before confirming.';
        }
      }

      setState(() {
        _stagedPhoto = permanentFile;
        _stagedHash = hash;
        _qualityWarning = warning;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture error: $e'), backgroundColor: AppTokens.redOrange),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _retake() {
    setState(() {
      _stagedPhoto = null;
      _stagedHash = null;
      _qualityWarning = null;
    });
    _initCamera();
  }

  void _confirm() {
    if (_stagedPhoto != null && _stagedHash != null) {
      widget.onPhotoConfirmed(_stagedPhoto!, _stagedHash!);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_permissionState) {
      case _ModulePermissionState.prompt:
        return _buildPrompt();
      case _ModulePermissionState.checking:
        return const Center(child: CircularProgressIndicator());
      case _ModulePermissionState.denied:
        return _buildDenied();
      case _ModulePermissionState.granted:
        return _stagedPhoto != null ? _buildReviewScreen() : _buildLiveView();
    }
  }

  Widget _buildPrompt() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppTokens.raised,
          borderRadius: AppTokens.zeroRadius,
          border: Border.all(color: AppTokens.borderSolid, width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48.0, color: AppTokens.textPrimary),
            const SizedBox(height: 16.0),
            Text(
              widget.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Workshop Check-in requires camera access to capture vehicle condition photos and odometer readings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, color: AppTokens.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24.0),
            SharpButton(
              label: 'CONTINUE & ALLOW CAMERA',
              onPressed: _requestPermission,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenied() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppTokens.raised,
          borderRadius: AppTokens.zeroRadius,
          border: Border.all(color: AppTokens.redOrange, width: 2.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48.0, color: AppTokens.redOrange),
            const SizedBox(height: 16.0),
            const Text(
              'CAMERA PERMISSION DENIED',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w800, color: AppTokens.redOrange),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Camera access was denied. Please enable camera access in your device settings to proceed.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, height: 1.4),
            ),
            const SizedBox(height: 24.0),
            SharpButton(
              label: 'OPEN SETTINGS',
              onPressed: () => openAppSettings(),
            ),
            const SizedBox(height: 8.0),
            SharpButton(
              label: 'RETRY PERMISSION',
              variant: SharpButtonVariant.secondary,
              onPressed: _requestPermission,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveView() {
    if (_isInitializing) return const Center(child: CircularProgressIndicator());

    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTokens.raised,
            border: Border.all(color: AppTokens.redOrange, width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44.0, color: AppTokens.redOrange),
              const SizedBox(height: 8.0),
              const Text('CAMERA ERROR / DISCONNECTED', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8.0),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.0)),
              const SizedBox(height: 16.0),
              SharpButton(label: 'RECONNECT CAMERA', onPressed: _initCamera),
            ],
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: Text('Initializing camera preview...'));
    }

    return Stack(
      children: [
        Positioned.fill(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: c.value.previewSize?.height ?? 1920,
              height: c.value.previewSize?.width ?? 1080,
              child: CameraPreview(c),
            ),
          ),
        ),
        // Optional Custom Wireframe Overlay
        if (widget.wireframeGuide != null)
          Positioned.fill(
            child: CustomPaint(painter: widget.wireframeGuide!),
          ),
        // Header Instruction Banner
        Positioned(
          top: 16.0,
          left: 16.0,
          right: 16.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: AppTokens.inverse.withOpacity(0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(color: AppTokens.textOnDark, fontWeight: FontWeight.w800, fontSize: 13.0),
                ),
                Text(
                  widget.instruction,
                  style: const TextStyle(color: AppTokens.surface, fontSize: 12.0),
                ),
              ],
            ),
          ),
        ),
        // Shutter Button Bar
        Positioned(
          bottom: 24.0,
          left: 0,
          right: 0,
          child: Center(
            child: SharpButton(
              label: _isProcessing ? 'CAPTURING...' : 'CAPTURE SHOT',
              icon: Icons.camera,
              onPressed: _isProcessing ? null : _takeShutter,
              width: 220.0,
              height: 52.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewScreen() {
    return Container(
      color: AppTokens.base,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: AppTokens.inverse,
            child: Row(
              children: [
                Text(
                  'REVIEW EVIDENCE: ${widget.title.toUpperCase()}',
                  style: const TextStyle(color: AppTokens.textOnDark, fontWeight: FontWeight.w800, fontSize: 13.0),
                ),
                const Spacer(),
                const Text(
                  'TAMPER-PROOF HASH GENERATED',
                  style: TextStyle(color: AppTokens.green, fontWeight: FontWeight.w700, fontSize: 11.0, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(color: AppTokens.borderSolid, width: 1.0),
              ),
              child: Image.file(_stagedPhoto!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: AppTokens.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FILE: ${_stagedPhoto!.path}', style: const TextStyle(fontSize: 10.0, fontFamily: 'monospace')),
                const SizedBox(height: 4.0),
                Text('SHA-256: $_stagedHash', style: const TextStyle(fontSize: 10.0, fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                if (_qualityWarning != null) ...[
                  const SizedBox(height: 6.0),
                  Text('⚠️ $_qualityWarning', style: const TextStyle(fontSize: 11.0, color: AppTokens.redOrange, fontWeight: FontWeight.w700)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: SharpButton(
                  label: 'RETAKE',
                  variant: SharpButtonVariant.secondary,
                  onPressed: _retake,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: SharpButton(
                  label: 'CONFIRM & ATTACH',
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

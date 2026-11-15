import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:crypto/crypto.dart';
import 'package:permission_handler/permission_handler.dart';
import '../ui_kit/tokens/app_tokens.dart';
import '../ui_kit/widgets/sharp_button.dart';

typedef QualityCheckCallback = Future<bool> Function(Uint8List bytes);

class CameraCaptureModule extends StatefulWidget {
  final String title;
  final String instruction;
  final CustomPainter? wireframeGuide;
  final Function(String photoPath, String sha256Hash, int fileSizeBytes) onPhotoConfirmed;
  final QualityCheckCallback? onQualityCheck;
  final VoidCallback? onFallbackToSimulation;

  const CameraCaptureModule({
    super.key,
    required this.title,
    required this.instruction,
    this.wireframeGuide,
    required this.onPhotoConfirmed,
    this.onQualityCheck,
    this.onFallbackToSimulation,
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
  Uint8List? _stagedBytes;
  String? _stagedPath;
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
      if (_permissionState == _ModulePermissionState.granted && _stagedBytes == null) {
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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        final status = await Permission.camera.request();
        if (status.isGranted) {
          setState(() => _permissionState = _ModulePermissionState.granted);
          await _initCamera();
        } else {
          setState(() => _permissionState = _ModulePermissionState.denied);
        }
      } catch (_) {
        setState(() => _permissionState = _ModulePermissionState.granted);
        await _initCamera();
      }
    } else {
      // Web, Windows, macOS, Linux: permission is requested by browser/system on initialize()
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
        throw CameraException('NoCamerasFound', 'No camera hardware detected or available.');
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

      // 2. Optional Quality Check Hook
      String? warning;
      if (widget.onQualityCheck != null) {
        final passed = await widget.onQualityCheck!(bytes);
        if (!passed) {
          warning = 'Photo may be blurry or poorly lit. Verify before confirming.';
        }
      }

      setState(() {
        _stagedBytes = bytes;
        _stagedPath = rawShot.path;
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
      _stagedBytes = null;
      _stagedPath = null;
      _stagedHash = null;
      _qualityWarning = null;
    });
    _initCamera();
  }

  void _confirm() {
    if (_stagedPath != null && _stagedHash != null && _stagedBytes != null) {
      widget.onPhotoConfirmed(_stagedPath!, _stagedHash!, _stagedBytes!.length);
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
        return _stagedBytes != null ? _buildReviewScreen() : _buildLiveView();
    }
  }

  Widget _buildPrompt() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTokens.raised,
          borderRadius: AppTokens.zeroRadius,
          border: Border.all(color: AppTokens.borderSolid, width: 1.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 40.0, color: AppTokens.textPrimary),
              const SizedBox(height: 12.0),
              Text(
                widget.title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Workshop Check-in requires camera access to capture vehicle condition photos and odometer readings.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.0, color: AppTokens.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 18.0),
              SharpButton(
                label: 'CONTINUE & ALLOW CAMERA',
                onPressed: _requestPermission,
              ),
              if (widget.onFallbackToSimulation != null) ...[
                const SizedBox(height: 10.0),
                SharpButton(
                  label: 'USE SIMULATED CAPTURE (NO WEBCAM)',
                  variant: SharpButtonVariant.secondary,
                  onPressed: widget.onFallbackToSimulation,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDenied() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: AppTokens.raised,
          borderRadius: AppTokens.zeroRadius,
          border: Border.all(color: AppTokens.redOrange, width: 2.0),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.no_photography_outlined, size: 40.0, color: AppTokens.redOrange),
              const SizedBox(height: 12.0),
              const Text(
                'CAMERA PERMISSION DENIED',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w800, color: AppTokens.redOrange),
              ),
              const SizedBox(height: 10.0),
              const Text(
                'Camera access was denied. Please allow camera access in your browser or device settings to proceed.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.0, height: 1.35),
              ),
              const SizedBox(height: 18.0),
              if (!kIsWeb)
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
              if (widget.onFallbackToSimulation != null) ...[
                const SizedBox(height: 8.0),
                SharpButton(
                  label: 'USE SIMULATED CAPTURE (DEV MODE)',
                  variant: SharpButtonVariant.secondary,
                  onPressed: widget.onFallbackToSimulation,
                ),
              ],
            ],
          ),
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
          constraints: const BoxConstraints(maxWidth: 460.0),
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
              SharpButton(label: 'RETRY CAMERA', onPressed: _initCamera),
              if (widget.onFallbackToSimulation != null) ...[
                const SizedBox(height: 8.0),
                SharpButton(
                  label: 'SWITCH TO SIMULATED CAPTURE',
                  variant: SharpButtonVariant.secondary,
                  onPressed: widget.onFallbackToSimulation,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: Text('Initializing camera preview...'));
    }

    final double previewRatio = c.value.isInitialized && c.value.aspectRatio > 0
        ? c.value.aspectRatio
        : 16 / 9;

    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: AspectRatio(
              aspectRatio: previewRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(c),
                  // Custom Wireframe Guide Overlay aligned to camera frame
                  if (widget.wireframeGuide != null)
                    CustomPaint(painter: widget.wireframeGuide!),
                ],
              ),
            ),
          ),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SharpButton(
                  label: _isProcessing ? 'CAPTURING...' : 'CAPTURE SHOT',
                  icon: Icons.camera,
                  onPressed: _isProcessing ? null : _takeShutter,
                  width: 220.0,
                  height: 52.0,
                ),
                if (widget.onFallbackToSimulation != null) ...[
                  const SizedBox(width: 12.0),
                  SharpButton(
                    label: 'SIMULATE',
                    variant: SharpButtonVariant.secondary,
                    onDark: true,
                    onPressed: widget.onFallbackToSimulation,
                    height: 52.0,
                  ),
                ],
              ],
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
              child: Image.memory(_stagedBytes!, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(12.0),
            color: AppTokens.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FILE: $_stagedPath', style: const TextStyle(fontSize: 10.0, fontFamily: 'monospace')),
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

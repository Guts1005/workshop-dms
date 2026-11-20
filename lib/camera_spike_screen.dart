import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum CameraPermissionStatus {
  prompt, // Shows the one-line explanation screen first
  checking,
  granted,
  denied, // Shows screen with "Open Settings" action
}

class CameraSpikeScreen extends StatefulWidget {
  const CameraSpikeScreen({super.key});

  @override
  State<CameraSpikeScreen> createState() => _CameraSpikeScreenState();
}

class _CameraSpikeScreenState extends State<CameraSpikeScreen>
    with WidgetsBindingObserver {
  CameraPermissionStatus _permissionStatus = CameraPermissionStatus.prompt;
  CameraController? _controller;
  List<CameraDescription> _availableCameras = [];
  bool _isCameraInitializing = false;
  String? _cameraErrorMessage;

  // Capture results
  File? _lastCapturedFile;
  int? _lastCapturedSizeBytes;
  int _captureCount = 0;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Always start with the explanation prompt on first use across all platforms
    _permissionStatus = CameraPermissionStatus.prompt;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _controller;
    _controller = null;
    c?.dispose();
    super.dispose();
  }

  /// App Lifecycle Handling: Dispose on pause/inactive, re-init on resume
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeController();
    } else if (state == AppLifecycleState.resumed) {
      if (_permissionStatus == CameraPermissionStatus.granted) {
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
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _permissionStatus = CameraPermissionStatus.checking);

    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.camera.request();
      if (status.isGranted) {
        setState(() => _permissionStatus = CameraPermissionStatus.granted);
        await _initCamera();
      } else {
        setState(() => _permissionStatus = CameraPermissionStatus.denied);
      }
    } else {
      // Windows / Desktop
      setState(() => _permissionStatus = CameraPermissionStatus.granted);
      await _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_isCameraInitializing) return;
    _isCameraInitializing = true;
    _cameraErrorMessage = null;
    if (mounted) setState(() {});

    try {
      _availableCameras = await availableCameras();
      if (_availableCameras.isEmpty) {
        throw CameraException(
          'NoCamerasFound',
          'No connected camera detected on this device.',
        );
      }

      // Prefer rear camera on mobile, or first camera on desktop
      final selectedCamera = _availableCameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => _availableCameras.first,
      );

      final controller = CameraController(
        selectedCamera,
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
      _cameraErrorMessage = e.toString();
      _disposeController();
    } finally {
      _isCameraInitializing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _capturePhoto() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final XFile photo = await c.takePicture();

      // Save to App Sandbox directory only
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String sandboxFolder = p.join(appDir.path, 'bay_captures');
      final Directory targetDir = Directory(sandboxFolder);
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String targetPath = p.join(
        targetDir.path,
        'capture_$timestamp.jpg',
      );

      // Copy from temporary buffer to permanent sandbox location
      final File savedFile = await File(photo.path).copy(targetPath);
      final int sizeBytes = await savedFile.length();

      setState(() {
        _lastCapturedFile = savedFile;
        _lastCapturedSizeBytes = sizeBytes;
        _captureCount++;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Capture error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4E2DD),
      appBar: AppBar(
        title: const Text(
          'CAMERA CAPTURE SPIKE',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            fontSize: 16.0,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: const Color(0xFFE4E2DD),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'CAPTURES: $_captureCount',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  fontSize: 14.0,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_permissionStatus) {
      case CameraPermissionStatus.prompt:
        return _buildPermissionExplanationView();
      case CameraPermissionStatus.checking:
        return const Center(child: CircularProgressIndicator());
      case CameraPermissionStatus.denied:
        return _buildPermissionDeniedView();
      case CameraPermissionStatus.granted:
        return _buildCameraMainView();
    }
  }

  /// 1. One-line explanation screen before requesting permissions
  Widget _buildPermissionExplanationView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF1E1E1E), width: 1.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 48.0,
              color: Color(0xFF1E1E1E),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'CAMERA ACCESS REQUIRED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Workshop Check-in requires camera access to capture vehicle condition photos and odometer readings.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, height: 1.4),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFFE4E2DD),
                minimumSize: const Size(double.infinity, 48.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: _requestPermission,
              child: const Text(
                'CONTINUE & ALLOW CAMERA',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 2. Denial screen with "Open Settings" action
  Widget _buildPermissionDeniedView() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24.0),
        margin: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFDB4A2B), width: 2.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              size: 48.0,
              color: Color(0xFFDB4A2B),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'CAMERA PERMISSION DENIED',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFFDB4A2B),
              ),
            ),
            const SizedBox(height: 12.0),
            const Text(
              'Camera access was denied. Please grant permission in your system settings to capture check-in photos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.0, height: 1.4),
            ),
            const SizedBox(height: 24.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E1E),
                foregroundColor: const Color(0xFFE4E2DD),
                minimumSize: const Size(double.infinity, 48.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              onPressed: () => openAppSettings(),
              child: const Text(
                'OPEN SETTINGS',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 8.0),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48.0),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                side: const BorderSide(color: Color(0xFF1E1E1E)),
              ),
              onPressed: _requestPermission,
              child: const Text(
                'RETRY ACCESS',
                style: TextStyle(
                  color: Color(0xFF1E1E1E),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 3. Main Live Camera Preview + Captured Photo Side-by-Side
  Widget _buildCameraMainView() {
    if (_isCameraInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cameraErrorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFDB4A2B), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48.0,
                color: Color(0xFFDB4A2B),
              ),
              const SizedBox(height: 12.0),
              const Text(
                'CAMERA ERROR / DISCONNECTED',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15.0),
              ),
              const SizedBox(height: 8.0),
              Text(
                _cameraErrorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                onPressed: _initCamera,
                child: const Text('RECONNECT CAMERA'),
              ),
            ],
          ),
        ),
      );
    }

    final c = _controller;
    if (c == null || !c.value.isInitialized) {
      return const Center(child: Text('Camera initializing...'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        final previewWidget = Stack(
          alignment: Alignment.bottomCenter,
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
            // Capture Button Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCapturing
                          ? Colors.grey
                          : const Color(0xFFDB4A2B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200.0, 52.0),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    onPressed: _isCapturing ? null : _capturePhoto,
                    icon: _isCapturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.camera),
                    label: Text(
                      _isCapturing ? 'SAVING...' : 'CAPTURE PHOTO (JPEG)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final resultWidget = Container(
          color: const Color(0xFFD9D6D0),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                color: const Color(0xFF1E1E1E),
                child: const Text(
                  'LAST CAPTURED (APP SANDBOX)',
                  style: TextStyle(
                    color: Color(0xFFE4E2DD),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.0,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _lastCapturedFile != null
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(
                            color: const Color(0xFF1E1E1E),
                            width: 1.0,
                          ),
                        ),
                        child: Image.file(
                          _lastCapturedFile!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: const Color(0xFF1E1E1E),
                            width: 1.0,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'NO PHOTO CAPTURED YET',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8.0),
              if (_lastCapturedFile != null) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SANDBOX FILE PATH:',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF444444),
                        ),
                      ),
                      Text(
                        _lastCapturedFile!.path,
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        'SIZE: ${(_lastCapturedSizeBytes! / 1024).toStringAsFixed(1)} KB (${(_lastCapturedSizeBytes! / (1024 * 1024)).toStringAsFixed(2)} MB)',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );

        if (isLandscape) {
          return Row(
            children: [
              Expanded(flex: 3, child: previewWidget),
              Container(width: 1.0, color: const Color(0xFF1E1E1E)),
              Expanded(flex: 2, child: resultWidget),
            ],
          );
        } else {
          return Column(
            children: [
              Expanded(flex: 3, child: previewWidget),
              Container(height: 1.0, color: const Color(0xFF1E1E1E)),
              Expanded(flex: 2, child: resultWidget),
            ],
          );
        }
      },
    );
  }
}

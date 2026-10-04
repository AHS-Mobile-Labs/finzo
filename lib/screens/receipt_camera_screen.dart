import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_theme.dart';

class ReceiptCameraScreen extends StatefulWidget {
  const ReceiptCameraScreen({super.key});

  @override
  State<ReceiptCameraScreen> createState() => _ReceiptCameraScreenState();
}

class _ReceiptCameraScreenState extends State<ReceiptCameraScreen> {
  CameraController? _controller;
  Future<void>? _initialiseCamera;
  String? _error;
  bool _capturing = false;
  bool _isTorchOn = false;

  @override
  void initState() {
    super.initState();
    _initialiseCamera = _setupCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera found on this device.');
        return;
      }

      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (e) {
      if (mounted) setState(() => _error = e.description ?? e.code);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      HapticFeedback.selectionClick();
      final next = !_isTorchOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      setState(() => _isTorchOn = next);
    } catch (e) {
      debugPrint('Failed to toggle flash: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null && mounted) {
        HapticFeedback.lightImpact();
        Navigator.pop(context, result.files.single.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load image: $e')));
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }

    setState(() => _capturing = true);
    HapticFeedback.mediumImpact();
    try {
      final image = await controller.takePicture();
      if (mounted) Navigator.pop(context, image.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
      setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Receipt',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initialiseCamera,
        builder: (context, snapshot) {
          if (_error != null) {
            return _CameraMessage(message: _error!);
          }
          final controller = _controller;
          if (controller == null || !controller.value.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // Full cover camera preview that prevents letterboxing / squashing
              LayoutBuilder(
                builder: (context, constraints) {
                  var cameraRatio = controller.value.aspectRatio;
                  // On portrait mobile, invert the landscape camera ratio
                  if (constraints.maxHeight > constraints.maxWidth &&
                      cameraRatio > 1.0) {
                    cameraRatio = 1.0 / cameraRatio;
                  }
                  final screenRatio =
                      constraints.maxWidth / constraints.maxHeight;
                  double scale;
                  if (cameraRatio > screenRatio) {
                    scale =
                        constraints.maxHeight /
                        (constraints.maxWidth / cameraRatio);
                  } else {
                    scale =
                        constraints.maxWidth /
                        (constraints.maxHeight * cameraRatio);
                  }

                  return ClipRect(
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: AspectRatio(
                          aspectRatio: cameraRatio,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Viewfinder overlay with dark mask, frame cutout, and corner brackets
              const _ReceiptFrameOverlay(),

              // Bottom control bar (Gallery, Shutter, Flash)
              Positioned(
                left: 24,
                right: 24,
                bottom: 32,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Upload from Gallery
                      IconButton(
                        onPressed: _pickFromGallery,
                        icon: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.photo_library_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        tooltip: 'Upload from gallery',
                      ),

                      // Shutter button
                      GestureDetector(
                        onTap: _capturing ? null : _capture,
                        child: Container(
                          width: 78,
                          height: 78,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _capturing ? Colors.white54 : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: _capturing
                                ? const Center(
                                    child: SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.black,
                                    size: 30,
                                  ),
                          ),
                        ),
                      ),

                      // Torch toggle
                      IconButton(
                        onPressed: _toggleTorch,
                        icon: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isTorchOn
                                ? AppTheme.primaryColor
                                : Colors.black45,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isTorchOn
                                  ? AppTheme.primaryColor
                                  : Colors.white24,
                            ),
                          ),
                          child: Icon(
                            _isTorchOn
                                ? Icons.flash_on_rounded
                                : Icons.flash_off_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        tooltip: 'Toggle Flash',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  final String message;

  const _CameraMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_rounded,
              color: Colors.white38,
              size: 52,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptFrameOverlay extends StatelessWidget {
  const _ReceiptFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.maxWidth * 0.84;
          final boxHeight = constraints.maxHeight * 0.62;
          final left = (constraints.maxWidth - boxWidth) / 2;
          final top = (constraints.maxHeight - boxHeight) / 2.3;
          final cutoutRect = Rect.fromLTWH(left, top, boxWidth, boxHeight);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Dark vignette mask with cutout
              CustomPaint(painter: _CutoutMaskPainter(cutoutRect: cutoutRect)),

              // Viewfinder frame and corner brackets
              Positioned.fromRect(
                rect: cutoutRect,
                child: CustomPaint(painter: _ScannerBracketPainter()),
              ),

              // Guidance pill above frame
              Positioned(
                top: top - 44,
                left: 20,
                right: 20,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.document_scanner_rounded,
                          size: 15,
                          color: AppTheme.primaryColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Align receipt inside the frame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CutoutMaskPainter extends CustomPainter {
  final Rect cutoutRect;
  _CutoutMaskPainter({required this.cutoutRect});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(cutoutRect, const Radius.circular(16)),
      );
    final combinedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final paint = Paint()..color = Colors.black.withAlpha(160);
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CutoutMaskPainter oldDelegate) =>
      oldDelegate.cutoutRect != cutoutRect;
}

class _ScannerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bracketPaint = Paint()
      ..color = AppTheme.primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 26.0;
    const r = 16.0;

    // Top-left
    final tl = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, r)
      ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tl, bracketPaint);

    // Top-right
    final tr = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(tr, bracketPaint);

    // Bottom-left
    final bl = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - r)
      ..arcToPoint(Offset(r, size.height), radius: const Radius.circular(r))
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(bl, bracketPaint);

    // Bottom-right
    final br = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - r, size.height)
      ..arcToPoint(
        Offset(size.width, size.height - r),
        radius: const Radius.circular(r),
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(br, bracketPaint);

    // Subtle 3x3 alignment rule of thirds grid
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(20)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      gridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

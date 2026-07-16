import 'package:flutter/material.dart';

import '../screens/receipt_camera_screen.dart';
import '../screens/receipt_review_screen.dart';
import '../services/receipt_scanner_service.dart';
import '../utils/app_theme.dart';

class ReceiptScanFlow {
  const ReceiptScanFlow._();

  static Future<bool> start(BuildContext context) async {
    final source = await _showSourceSheet(context);
    if (source == null || !context.mounted) return false;
    return _startReceiptScan(context, source);
  }

  static Future<ReceiptImageSource?> _showSourceSheet(BuildContext context) {
    return showModalBottomSheet<ReceiptImageSource>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Scan receipt',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ScanSourceTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Take photo',
                  subtitle: 'Use the camera and scan on-device',
                  onTap: () =>
                      Navigator.pop(sheetContext, ReceiptImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ScanSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Choose image',
                  subtitle: 'Pick an existing receipt from gallery',
                  onTap: () =>
                      Navigator.pop(sheetContext, ReceiptImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool> _startReceiptScan(
    BuildContext context,
    ReceiptImageSource source,
  ) async {
    var loadingShown = false;
    final receiptScanner = ReceiptScannerService();
    final navigator = Navigator.of(context);

    try {
      final imagePath = switch (source) {
        ReceiptImageSource.camera => await navigator.push<String>(
          MaterialPageRoute(builder: (_) => const ReceiptCameraScreen()),
        ),
        ReceiptImageSource.gallery => await receiptScanner.pickGalleryImage(),
      };

      if (!context.mounted || imagePath == null) return false;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      loadingShown = true;

      final result = await receiptScanner.processImage(imagePath);
      if (!context.mounted) return false;
      Navigator.of(context, rootNavigator: true).pop();
      loadingShown = false;

      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ReceiptReviewScreen(result: result)),
      );
      if (saved == true && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt saved as expense.')),
        );
      }
      return saved == true;
    } catch (e) {
      if (!context.mounted) return false;
      if (loadingShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Receipt scan failed: $e')));
      return false;
    }
  }
}

class _ScanSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(42),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

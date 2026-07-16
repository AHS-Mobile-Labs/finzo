import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../models/receipt_scan_model.dart';
import 'database_service.dart';
import 'receipt_text_parser.dart';

enum ReceiptImageSource { camera, gallery }

class ReceiptScannerService {
  ReceiptScannerService({ImagePicker? imagePicker})
    : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;
  final ReceiptTextParser _parser = ReceiptTextParser();

  Future<String?> pickGalleryImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
    );
    return image?.path;
  }

  Future<ReceiptScanResult> processImage(String imagePath) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognisedText = await textRecognizer.processImage(inputImage);
      final processedPath =
          await _saveProcessedReceipt(imagePath, recognisedText) ??
          await DatabaseService.saveReceiptImage(imagePath);
      final rawText = recognisedText.text.trim();
      final lines = ReceiptTextParser.normaliseLines(rawText);

      return ReceiptScanResult(
        receiptPath: processedPath,
        rawText: rawText,
        lines: lines,
        fields: _parser.parse(rawText),
      );
    } finally {
      await textRecognizer.close();
    }
  }

  Future<String?> _saveProcessedReceipt(
    String imagePath,
    RecognizedText recognisedText,
  ) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final oriented = img.bakeOrientation(decoded);
      final crop = _textCropBounds(
        recognisedText,
        imageWidth: oriented.width,
        imageHeight: oriented.height,
      );
      final cropped = crop == null
          ? oriented
          : img.copyCrop(
              oriented,
              x: crop.left.round(),
              y: crop.top.round(),
              width: crop.width.round(),
              height: crop.height.round(),
            );

      final enhanced = img.adjustColor(
        cropped,
        brightness: 0.04,
        contrast: 1.1,
      );
      final resized = enhanced.width > 2000
          ? img.copyResize(enhanced, width: 2000)
          : enhanced;
      final jpg = img.encodeJpg(resized, quality: 88);
      return DatabaseService.saveReceiptImageBytes(jpg);
    } catch (_) {
      return null;
    }
  }

  Rect? _textCropBounds(
    RecognizedText recognisedText, {
    required int imageWidth,
    required int imageHeight,
  }) {
    var left = imageWidth.toDouble();
    var top = imageHeight.toDouble();
    var right = 0.0;
    var bottom = 0.0;
    var found = false;

    for (final block in recognisedText.blocks) {
      final bounds = block.boundingBox;
      if (bounds.width <= 0 || bounds.height <= 0) continue;
      left = left < bounds.left ? left : bounds.left;
      top = top < bounds.top ? top : bounds.top;
      right = right > bounds.right ? right : bounds.right;
      bottom = bottom > bounds.bottom ? bottom : bounds.bottom;
      found = true;
    }

    if (!found) return null;
    if (right <= left || bottom <= top) return null;
    if (right > imageWidth * 1.2 || bottom > imageHeight * 1.2) return null;

    final horizontalPadding = imageWidth * 0.04;
    final verticalPadding = imageHeight * 0.04;
    left = (left - horizontalPadding).clamp(0, imageWidth - 1).toDouble();
    top = (top - verticalPadding).clamp(0, imageHeight - 1).toDouble();
    right = (right + horizontalPadding).clamp(1, imageWidth).toDouble();
    bottom = (bottom + verticalPadding).clamp(1, imageHeight).toDouble();

    final width = right - left;
    final height = bottom - top;
    final imageArea = imageWidth * imageHeight;
    final cropArea = width * height;
    if (width < imageWidth * 0.25 || height < imageHeight * 0.18) return null;
    if (cropArea < imageArea * 0.08) return null;

    return Rect.fromLTWH(left, top, width, height);
  }
}

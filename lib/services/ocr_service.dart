import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/parsed_receipt.dart';
import 'receipt_parser.dart';

class OcrService {
  static final OcrService instance = OcrService._init();
  final ImagePicker _picker = ImagePicker();
  TextRecognizer? _textRecognizer;

  OcrService._init() {
    // Only initialize native TextRecognizer on supported mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    }
  }

  /// Dispose OCR recognizer resources to prevent memory leaks
  void dispose() {
    _textRecognizer?.close();
  }

  /// Pick an image from camera or gallery and process OCR
  Future<ParsedReceipt?> processFromImageSource(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      // Save persistent receipt image to local app documents directory
      String? savedImagePath;
      try {
        if (!kIsWeb) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
          final savedFile = await File(pickedFile.path).copy(p.join(directory.path, fileName));
          savedImagePath = savedFile.path;
        } else {
          savedImagePath = pickedFile.path;
        }
      } catch (e) {
        savedImagePath = pickedFile.path;
      }

      return await recognizeTextFromPath(pickedFile.path, savedImagePath: savedImagePath);
    } catch (e) {
      debugPrint('OCR Image Pick Error: $e');
      rethrow;
    }
  }

  /// Recognizes text from image path using ML Kit
  Future<ParsedReceipt> recognizeTextFromPath(String imagePath, {String? savedImagePath}) async {
    if (_textRecognizer != null) {
      try {
        final inputImage = InputImage.fromFilePath(imagePath);
        final RecognizedText recognizedText = await _textRecognizer!.processImage(inputImage);
        final rawText = recognizedText.text;

        return ReceiptParser.parse(rawText, imagePath: savedImagePath ?? imagePath);
      } catch (e) {
        debugPrint('ML Kit recognition failed: $e, falling back to heuristic mock');
      }
    }

    // Fallback if running on simulator / web / desktop without native camera ML Kit
    return _generateFallbackReceipt(imagePath: savedImagePath ?? imagePath);
  }

  /// Parse directly from custom/pasted raw text
  ParsedReceipt parseFromRawText(String rawText, {String? imagePath}) {
    return ReceiptParser.parse(rawText, imagePath: imagePath);
  }

  ParsedReceipt _generateFallbackReceipt({String? imagePath}) {
    const sampleText = '''
HIGHLANDS COFFEE
Tầng 1, VKU Campus, Đà Nẵng
ĐT: 0236 3667 113
HÓA ĐƠN THANH TOÁN
Ngày: 22/10/2026 09:30
Thu ngân: Thu_Ngan_01

1. Phin Sữa Đá (L)     39.000
2. Trà Sen Vàng (M)    45.000
3. Bánh Chuối          29.000

Cộng tiền hàng:       113.000
VAT (8%):               9.040
TỔNG CỘNG:            122.040 đ

Thanh toán: TIỀN MẶT
Cảm ơn Quý khách & Hẹn gặp lại!
''';
    return ReceiptParser.parse(sampleText, imagePath: imagePath);
  }
}

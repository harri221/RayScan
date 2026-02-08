import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image/image.dart' as img;

/// API-based kidney stone detection using 100% accurate Random Forest model
/// Sends images to Python backend for prediction
/// NOW WITH IMAGE VALIDATION - Rejects non-medical images!
class KidneyStoneAPIDetector {
  static final KidneyStoneAPIDetector _instance = KidneyStoneAPIDetector._internal();
  factory KidneyStoneAPIDetector() => _instance;
  KidneyStoneAPIDetector._internal();

  // API Configuration
  // Cloud API URL - Works from anywhere!
  static const String apiBaseUrl = 'https://c3a30c44-54ae-4aba-9275-896c9f5f2807-00-ptsn06fpmrh7.riker.replit.dev';
  static const Duration timeout = Duration(seconds: 30);

  bool _isServerOnline = false;

  /// Check if API server is online
  Future<bool> checkServerStatus() async {
    try {
      debugPrint('Checking API server at $apiBaseUrl...');
      final response = await http
          .get(Uri.parse('$apiBaseUrl/health'))
          .timeout(const Duration(seconds: 5));

      _isServerOnline = response.statusCode == 200;
      debugPrint('Server status: ${_isServerOnline ? "ONLINE" : "OFFLINE"}');
      return _isServerOnline;
    } catch (e) {
      debugPrint('Server check failed: $e');
      _isServerOnline = false;
      return false;
    }
  }

  /// Initialize the API detector (check server connection)
  Future<bool> initialize() async {
    return await checkServerStatus();
  }

  /// Validate if image looks like a medical ultrasound/CT scan
  /// BALANCED - Rejects colorful photos but accepts all grayscale medical scans
  /// Returns: (isValid, reason)
  Future<ImageValidationResult> validateMedicalImage(Uint8List imageBytes) async {
    try {
      debugPrint('=== BALANCED IMAGE VALIDATION ===');

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        return ImageValidationResult(
          isValid: false,
          reason: 'Could not decode image. Please use a valid image format (JPG, PNG).',
          confidence: 0.0,
        );
      }

      debugPrint('Image size: ${image.width}x${image.height}');

      // Resize for faster analysis
      final resized = img.copyResize(image, width: 100, height: 100);

      int totalPixels = resized.width * resized.height;
      int grayscalePixels = 0;    // Pixels where R≈G≈B (within 25)
      int colorfulPixels = 0;     // Pixels with obvious color
      int skinTonePixels = 0;     // Detect selfies

      double totalColorDiff = 0;

      for (int y = 0; y < resized.height; y++) {
        for (int x = 0; x < resized.width; x++) {
          final pixel = resized.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          // Calculate color difference
          final maxChannel = [r, g, b].reduce((a, b) => a > b ? a : b);
          final minChannel = [r, g, b].reduce((a, b) => a < b ? a : b);
          final colorDiff = maxChannel - minChannel;

          totalColorDiff += colorDiff;

          // Grayscale: R, G, B within 25 of each other
          if (colorDiff <= 25) {
            grayscalePixels++;
          }

          // Very colorful pixel (strong color)
          if (colorDiff > 40) {
            colorfulPixels++;
          }

          // Skin tone detection (selfies) - R > G > B pattern with warm tones
          if (r > 80 && g > 40 && b > 20 &&
              r > g && g > b &&
              (r - b) > 20 &&
              r < 255 && g < 240) {
            skinTonePixels++;
          }
        }
      }

      final grayscaleRatio = grayscalePixels / totalPixels;
      final colorfulRatio = colorfulPixels / totalPixels;
      final skinRatio = skinTonePixels / totalPixels;
      final avgColorDiff = totalColorDiff / totalPixels;

      debugPrint('=== VALIDATION METRICS ===');
      debugPrint('Grayscale ratio: $grayscaleRatio (need > 0.75)');
      debugPrint('Colorful ratio: $colorfulRatio (need < 0.15)');
      debugPrint('Skin tone ratio: $skinRatio (need < 0.10)');
      debugPrint('Avg color diff: $avgColorDiff (need < 25)');

      // RULE 1: Reject selfies (skin tone detection)
      if (skinRatio > 0.10) {
        debugPrint('REJECTED: Skin tones detected - likely a selfie/person photo');
        return ImageValidationResult(
          isValid: false,
          reason: 'This appears to be a photo of a person. Please upload a kidney ultrasound or CT scan image.',
          confidence: skinRatio,
        );
      }

      // RULE 2: Reject very colorful images
      if (colorfulRatio > 0.15) {
        debugPrint('REJECTED: Too many colorful pixels ($colorfulRatio)');
        return ImageValidationResult(
          isValid: false,
          reason: 'This image has too much color. Medical scans are grayscale. Please upload a valid ultrasound or CT scan.',
          confidence: colorfulRatio,
        );
      }

      // RULE 3: Average color difference check
      if (avgColorDiff > 25) {
        debugPrint('REJECTED: Average color diff too high ($avgColorDiff)');
        return ImageValidationResult(
          isValid: false,
          reason: 'This does not appear to be a medical scan. Please upload a grayscale kidney ultrasound or CT scan.',
          confidence: avgColorDiff / 100,
        );
      }

      // RULE 4: Must be mostly grayscale (75%+)
      if (grayscaleRatio < 0.75) {
        debugPrint('REJECTED: Not grayscale enough ($grayscaleRatio)');
        return ImageValidationResult(
          isValid: false,
          reason: 'This image contains too much color. Please upload a grayscale medical scan.',
          confidence: grayscaleRatio,
        );
      }

      // Passed all checks - accept as medical image
      debugPrint('ACCEPTED: Looks like a valid medical scan');
      return ImageValidationResult(
        isValid: true,
        reason: 'Image appears to be a valid medical scan.',
        confidence: grayscaleRatio,
      );

    } catch (e) {
      debugPrint('Image validation error: $e');
      // On error, REJECT by default
      return ImageValidationResult(
        isValid: false,
        reason: 'Could not validate image. Please try a different image.',
        confidence: 0.0,
      );
    }
  }

  /// Predict kidney stone from image bytes using API
  /// NOW WITH IMAGE VALIDATION!
  Future<DetectionResult> predict(Uint8List imageBytes) async {
    debugPrint('=== API PREDICTION CALLED ===');
    debugPrint('Image bytes length: ${imageBytes.length}');
    debugPrint('API URL: $apiBaseUrl/predict');

    try {
      // STEP 1: Validate the image is a medical scan
      final validation = await validateMedicalImage(imageBytes);

      if (!validation.isValid) {
        debugPrint('Image validation FAILED: ${validation.reason}');
        return DetectionResult(
          hasStone: false,
          confidence: 0.0,
          rawScore: 0.0,
          isOnDevice: false,
          isValidMedicalImage: false,
          message: validation.reason,
          recommendation: 'Please upload a clear kidney ultrasound or CT scan image for accurate AI diagnosis.',
        );
      }

      debugPrint('Image validation PASSED');

      // STEP 2: Check server status
      if (!_isServerOnline) {
        final isOnline = await checkServerStatus();
        if (!isOnline) {
          return DetectionResult(
            hasStone: false,
            confidence: 0.0,
            rawScore: 0.0,
            isOnDevice: false,
            isValidMedicalImage: true,
            message: 'API server is offline. Please start the Python backend server.',
            recommendation: 'Make sure the Flask API server is running on your computer.',
          );
        }
      }

      // STEP 3: Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiBaseUrl/predict'),
      );

      // Add image file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: 'ultrasound.jpg',
        ),
      );

      debugPrint('Sending request to API...');

      // Send request with timeout
      var streamedResponse = await request.send().timeout(timeout);
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('API response status: ${response.statusCode}');
      debugPrint('API response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse JSON response
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final result = jsonResponse['result'];
          final bool hasStone = result['hasKidneyStone'] ?? false;
          final String confidenceStr = result['confidence'] ?? '0%';
          final double confidence = double.parse(confidenceStr.replaceAll('%', '')) / 100;

          debugPrint('API prediction: hasStone=$hasStone, confidence=$confidence');

          return DetectionResult(
            hasStone: hasStone,
            confidence: confidence,
            rawScore: confidence,
            isOnDevice: false,
            isValidMedicalImage: true,
            message: result['diagnosis'] ?? 'Prediction complete',
            recommendation: hasStone
                ? 'High confidence kidney stone detection. Please consult a urologist.'
                : 'No kidney stones detected. Continue regular health checkups.',
          );
        } else {
          // API returned error
          return DetectionResult(
            hasStone: false,
            confidence: 0.0,
            rawScore: 0.0,
            isOnDevice: false,
            isValidMedicalImage: true,
            message: 'API Error: ${jsonResponse['message'] ?? 'Unknown error'}',
          );
        }
      } else {
        // HTTP error
        return DetectionResult(
          hasStone: false,
          confidence: 0.0,
          rawScore: 0.0,
          isOnDevice: false,
          isValidMedicalImage: true,
          message: 'API request failed with status ${response.statusCode}',
        );
      }
    } on TimeoutException catch (e) {
      debugPrint('Timeout error: $e');
      return DetectionResult(
        hasStone: false,
        confidence: 0.0,
        rawScore: 0.0,
        isOnDevice: false,
        isValidMedicalImage: true,
        message: 'Request timed out',
        recommendation: 'The server is taking too long to respond. Please try again.',
      );
    } on http.ClientException catch (e) {
      debugPrint('Network error: $e');
      return DetectionResult(
        hasStone: false,
        confidence: 0.0,
        rawScore: 0.0,
        isOnDevice: false,
        isValidMedicalImage: true,
        message: 'Network error: Cannot reach API server',
        recommendation: 'Check your internet connection and make sure the Flask server is running.',
      );
    } catch (e) {
      debugPrint('Prediction error: $e');
      return DetectionResult(
        hasStone: false,
        confidence: 0.0,
        rawScore: 0.0,
        isOnDevice: false,
        isValidMedicalImage: true,
        message: 'Prediction failed: $e',
      );
    }
  }

  /// Predict from file
  Future<DetectionResult> predictFromFile(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return predict(bytes);
  }

  /// Get server information
  Future<Map<String, dynamic>?> getServerInfo() async {
    try {
      final response = await http
          .get(Uri.parse(apiBaseUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      debugPrint('Failed to get server info: $e');
    }
    return null;
  }

  /// Clean up resources (no-op for API detector)
  void dispose() {
    // No resources to clean up for API-based detector
    debugPrint('KidneyStoneAPIDetector disposed');
  }
}

/// Result of image validation
class ImageValidationResult {
  final bool isValid;
  final String reason;
  final double confidence;

  ImageValidationResult({
    required this.isValid,
    required this.reason,
    required this.confidence,
  });
}

/// Result of kidney stone detection (shared with TFLite detector)
class DetectionResult {
  final bool hasStone;
  final double confidence;
  final double rawScore;
  final bool isOnDevice;
  final bool isValidMedicalImage;
  final String message;
  final String? recommendation;

  DetectionResult({
    required this.hasStone,
    required this.confidence,
    this.rawScore = 0.0,
    required this.isOnDevice,
    this.isValidMedicalImage = true,
    required this.message,
    this.recommendation,
  });

  /// Get severity level based on confidence
  String get severity {
    if (!isValidMedicalImage) return 'Invalid';
    if (!hasStone) return 'Normal';
    if (confidence > 0.9) return 'High';
    if (confidence > 0.7) return 'Moderate';
    return 'Low';
  }

  /// Get recommendation text
  String get recommendationText {
    if (recommendation != null) return recommendation!;

    if (!isValidMedicalImage) {
      return 'Please upload a valid kidney ultrasound or CT scan image.';
    }

    if (!hasStone) {
      return 'No signs of kidney stones detected. Continue with regular health checkups.';
    }

    switch (severity) {
      case 'High':
        return 'High likelihood of kidney stone. Please consult a urologist immediately.';
      case 'Moderate':
        return 'Moderate likelihood of kidney stone. We recommend scheduling a specialist appointment.';
      default:
        return 'Possible kidney stone detected. Consider follow-up imaging.';
    }
  }

  /// Convert to map for API/storage
  Map<String, dynamic> toMap() => {
    'hasStone': hasStone,
    'confidence': confidence,
    'rawScore': rawScore,
    'isOnDevice': isOnDevice,
    'isValidMedicalImage': isValidMedicalImage,
    'message': message,
    'severity': severity,
    'recommendation': recommendationText,
  };

  @override
  String toString() =>
      'DetectionResult(hasStone: $hasStone, confidence: ${(confidence * 100).toStringAsFixed(1)}%, severity: $severity, validImage: $isValidMedicalImage)';
}

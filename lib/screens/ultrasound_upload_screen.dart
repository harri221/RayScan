import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/kidney_stone_api_detector.dart';
import 'ml_result_screen.dart';

class UltrasoundUploadScreen extends StatefulWidget {
  const UltrasoundUploadScreen({super.key});

  @override
  State<UltrasoundUploadScreen> createState() => _UltrasoundUploadScreenState();
}

class _UltrasoundUploadScreenState extends State<UltrasoundUploadScreen> {
  File? _selectedImage;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();
  final _detector = KidneyStoneAPIDetector();
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      final loaded = await _detector.initialize();
      setState(() {
        _modelLoaded = loaded;
      });

      if (!loaded && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Warning: ML model failed to load. App may not work correctly.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Model initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ML model error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    print('=== PROCESS IMAGE CALLED ===');

    if (_selectedImage == null) {
      print('ERROR: No image selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    print('Image selected: ${_selectedImage!.path}');
    print('Model loaded: $_modelLoaded');

    // Don't block - just show warning but continue
    if (!_modelLoaded) {
      print('WARNING: Model not loaded, will use DEMO mode');
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      print('Reading image bytes...');
      final bytes = await _selectedImage!.readAsBytes();
      print('Image bytes loaded: ${bytes.length} bytes');

      print('Running ML prediction...');
      final result = await _detector.predict(bytes);
      print('Prediction result: ${result.toString()}');
      print('>>> isValidMedicalImage: ${result.isValidMedicalImage}');
      print('>>> hasStone: ${result.hasStone}');
      print('>>> message: ${result.message}');

      if (!mounted) {
        print('Widget unmounted, aborting navigation');
        return;
      }

      // Convert to format expected by ML Result Screen
      final formattedResult = {
        'hasKidneyStone': result.hasStone,
        'confidence': result.confidence * 100, // Convert to percentage
        'confidenceScore': result.rawScore,
        'prediction': result.message,
        'isOnDevice': result.isOnDevice,
        'isValidMedicalImage': result.isValidMedicalImage, // CRITICAL: Pass validation result!
        'severity': result.severity,
        'recommendation': result.recommendationText,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      print('Formatted result: $formattedResult');
      print('Navigating to results screen...');

      // ALWAYS navigate - no matter what
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MLResultScreen(
            result: formattedResult,
            imageFile: _selectedImage!,
          ),
        ),
      );

      print('Returned from results screen');

      // Reset state after navigation returns
      if (mounted) {
        setState(() {
          _selectedImage = null;
          _isProcessing = false;
        });
      }

    } catch (e, stackTrace) {
      print('CRITICAL ERROR in _processImage: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Show error but don't crash
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kidney Stone Detection'),
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0E807F), Color(0xFF2E8B57)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 60,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'AI-Powered Kidney Stone Detection',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload ultrasound image for instant analysis',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Image Preview or Upload Button
            if (_selectedImage == null)
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF0E807F).withValues(alpha: 0.3),
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tap to upload ultrasound image',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'JPG, PNG (Max 10MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      _selectedImage!,
                      height: 300,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedImage = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Action Buttons
            if (_selectedImage != null) ...[
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processImage,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.analytics),
                label: Text(
                  _isProcessing ? 'Analyzing...' : 'Analyze Image',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E807F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isProcessing ? null : _showImageSourceDialog,
                icon: const Icon(Icons.change_circle),
                label: const Text('Change Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0E807F),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF0E807F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Information Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Important Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Upload clear ultrasound images for best results\n'
                    '• AI provides preliminary analysis only\n'
                    '• Always consult a doctor for final diagnosis\n'
                    '• Results are stored in your medical history',
                    style: TextStyle(
                      color: Colors.blue[800],
                      height: 1.5,
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
}

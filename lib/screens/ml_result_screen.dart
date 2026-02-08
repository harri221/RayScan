import 'package:flutter/material.dart';
import 'dart:io';
import '../services/pdf_report_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'doctor_list.dart' show DoctorsListScreen;

class MLResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final File imageFile;

  const MLResultScreen({
    super.key,
    required this.result,
    required this.imageFile,
  });

  @override
  State<MLResultScreen> createState() => _MLResultScreenState();
}

class _MLResultScreenState extends State<MLResultScreen> {
  bool _isGeneratingPDF = false;

  /// Check if this is an invalid/non-medical image
  bool get _isInvalidImage {
    final isValid = widget.result['isValidMedicalImage'];
    final severity = widget.result['severity'];
    print('>>> ML RESULT SCREEN: isValidMedicalImage=$isValid, severity=$severity');
    print('>>> FULL RESULT: ${widget.result}');
    return isValid == false || severity == 'Invalid';
  }

  Future<void> _generatePDFReport() async {
    setState(() => _isGeneratingPDF = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('userName') ?? 'Patient';

      final filePath = await PDFReportService.generateKidneyStoneReport(
        result: widget.result,
        patientName: userName,
        ultrasoundImage: widget.imageFile,
      );

      setState(() => _isGeneratingPDF = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Report generated successfully!'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OPEN',
              textColor: Colors.white,
              onPressed: () => PDFReportService.openPDF(filePath),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isGeneratingPDF = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToDoctors() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorsListScreen()),
    );
  }

  Color _getResultColor() {
    if (_isInvalidImage) {
      return Colors.orange; // Warning color for invalid images
    }
    final hasStone = widget.result['hasKidneyStone'];
    if (hasStone == true) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  IconData _getResultIcon() {
    if (_isInvalidImage) {
      return Icons.image_not_supported_rounded; // Invalid image icon
    }
    final hasStone = widget.result['hasKidneyStone'];
    if (hasStone == true) {
      return Icons.warning_amber_rounded;
    } else {
      return Icons.check_circle;
    }
  }

  String _getResultTitle() {
    if (_isInvalidImage) {
      return 'Invalid Image';
    }
    return widget.result['prediction'] ?? 'Analysis Complete';
  }

  String _formatConfidence(dynamic confidence) {
    if (_isInvalidImage) return '0.0';
    if (confidence == null) return '0.0';
    if (confidence is int) return confidence.toDouble().toStringAsFixed(1);
    if (confidence is double) return confidence.toStringAsFixed(1);
    return confidence.toString();
  }

  String _formatConfidenceScore(dynamic score) {
    if (score == null) return '0.0000';
    if (score is int) return score.toDouble().toStringAsFixed(4);
    if (score is double) return score.toStringAsFixed(4);
    return score.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Show special UI for invalid images
    if (_isInvalidImage) {
      return _buildInvalidImageScreen();
    }

    return _buildNormalResultScreen();
  }

  /// Build screen for INVALID (non-medical) images
  Widget _buildInvalidImageScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Invalid Image Warning Card
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange,
                    Colors.orange.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Not a Medical Scan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.result['prediction'] ?? 'This image does not appear to be a kidney ultrasound or CT scan.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Uploaded Image Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Uploaded Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Invalid',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Image.file(
                      widget.imageFile,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // What to Upload Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[200] ?? Colors.blue),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'What Should You Upload?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCheckItem('Kidney ultrasound images'),
                  _buildCheckItem('CT scan images of kidneys'),
                  _buildCheckItem('Medical imaging reports'),
                  _buildCheckItem('Grayscale medical scans'),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.block, color: Colors.red[400], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Do NOT upload:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Regular photos, selfies, or screenshots\n• Non-medical images\n• Documents or text images',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Try Again Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Go back to upload screen
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again with Valid Image'),
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

            // Cancel Button
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Go back to main screen
              },
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[600], size: 18),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Build screen for VALID medical images (normal flow)
  Widget _buildNormalResultScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: const Color(0xFF0E807F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Result Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getResultColor(),
                    _getResultColor().withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _getResultColor().withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    _getResultIcon(),
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getResultTitle(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Confidence: ${_formatConfidence(widget.result['confidence'])}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Image Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.image,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analyzed Image',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    child: Image.file(
                      widget.imageFile,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.analytics,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Analysis Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildDetailRow('Report ID', '#${widget.result['id'] ?? 'N/A'}'),
                    _buildDetailRow('Scan Type', 'Kidney Ultrasound'),
                    _buildDetailRow(
                      'Result',
                      widget.result['hasKidneyStone'] == true
                          ? 'Stone Detected'
                          : 'Normal Kidney',
                    ),
                    _buildDetailRow(
                      'Confidence Score',
                      _formatConfidenceScore(widget.result['confidenceScore']),
                    ),
                    _buildDetailRow(
                      'Analysis Date',
                      DateTime.now().toString().split('.')[0],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recommendation Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange[200] ?? Colors.orange),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_information, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Medical Recommendation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.result['hasKidneyStone'] == true
                        ? '⚠️ Kidney stones detected. Please consult a urologist for proper diagnosis and treatment plan.'
                        : '✓ No kidney stones detected. Continue regular checkups and maintain a healthy lifestyle.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      height: 1.5,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Note: This AI analysis is for preliminary screening only. Always consult with qualified medical professionals for accurate diagnosis.',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Download PDF Button
            ElevatedButton.icon(
              onPressed: _isGeneratingPDF ? null : _generatePDFReport,
              icon: _isGeneratingPDF
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              label: Text(_isGeneratingPDF ? 'Generating PDF...' : 'Download PDF Report'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _navigateToDoctors,
                    icon: const Icon(Icons.medical_services),
                    label: const Text('See Doctors'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0E807F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0E807F),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF0E807F)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

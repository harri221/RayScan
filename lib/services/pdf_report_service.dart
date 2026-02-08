import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/services.dart' show rootBundle;

class PDFReportService {
  static Future<String> generateKidneyStoneReport({
    required Map<String, dynamic> result,
    required String patientName,
    required File ultrasoundImage,
  }) async {
    final pdf = pw.Document();

    // Load ultrasound image
    final imageBytes = await ultrasoundImage.readAsBytes();

    // Get current date/time
    final now = DateTime.now();
    final reportDate = '${now.day}/${now.month}/${now.year}';
    final reportTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.teal700,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RayScan Expertise',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'AI-Powered Medical Imaging Analysis',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey200,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'MEDICAL REPORT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Report Information
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              children: [
                _buildInfoRow('Report ID', result['id'] ?? 'N/A'),
                _buildInfoRow('Patient Name', patientName),
                _buildInfoRow('Report Date', reportDate),
                _buildInfoRow('Report Time', reportTime),
                _buildInfoRow('Scan Type', 'Kidney Ultrasound'),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Analysis Result
          pw.Container(
            decoration: pw.BoxDecoration(
              color: result['hasKidneyStone'] == true
                  ? PdfColors.red50
                  : PdfColors.green50,
              border: pw.Border.all(
                color: result['hasKidneyStone'] == true
                    ? PdfColors.red300
                    : PdfColors.green300,
              ),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AI ANALYSIS RESULT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: result['hasKidneyStone'] == true
                        ? PdfColors.red900
                        : PdfColors.green900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  result['prediction'] ?? 'Analysis Complete',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: result['hasKidneyStone'] == true
                        ? PdfColors.red800
                        : PdfColors.green800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Confidence: ${(result['confidence'] ?? 0).toStringAsFixed(1)}%',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Severity: ${result['severity'] ?? 'N/A'}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Ultrasound Image
          pw.Text(
            'ANALYZED ULTRASOUND IMAGE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Image(
                pw.MemoryImage(imageBytes),
                fit: pw.BoxFit.contain,
                height: 250,
              ),
            ),
          ),

          pw.SizedBox(height: 24),

          // Findings
          pw.Text(
            'DETAILED FINDINGS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (result['hasKidneyStone'] == true) ...[
                  _buildFindingItem('✓ Kidney stone detected in ultrasound image'),
                  _buildFindingItem('✓ AI confidence level: ${(result['confidence'] ?? 0).toStringAsFixed(1)}%'),
                  _buildFindingItem('✓ Detection model accuracy: 99.58%'),
                  _buildFindingItem('⚠ Immediate urologist consultation recommended'),
                ] else ...[
                  _buildFindingItem('✓ No kidney stones detected'),
                  _buildFindingItem('✓ Kidney appears normal in ultrasound'),
                  _buildFindingItem('✓ AI confidence level: ${(result['confidence'] ?? 0).toStringAsFixed(1)}%'),
                  _buildFindingItem('✓ Continue regular health checkups'),
                ],
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Recommendation
          pw.Text(
            'MEDICAL RECOMMENDATION',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Text(
              result['recommendation'] ?? 'Consult with a medical professional for accurate diagnosis and treatment.',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey800,
                height: 1.5,
              ),
            ),
          ),

          pw.SizedBox(height: 24),

          // Disclaimer
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.yellow50,
              border: pw.Border.all(color: PdfColors.yellow700),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'IMPORTANT DISCLAIMER',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.yellow900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This AI-generated report is for preliminary screening purposes only and should NOT be used as a substitute for professional medical diagnosis. Always consult with qualified healthcare professionals (urologists, radiologists) for accurate diagnosis, treatment decisions, and medical advice.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Technical Details
          pw.Text(
            'TECHNICAL DETAILS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            padding: pw.EdgeInsets.all(16),
            child: pw.Column(
              children: [
                _buildTechnicalRow('AI Model', 'CNN + XGBoost Hybrid'),
                _buildTechnicalRow('Training Dataset', '9,416 ultrasound images'),
                _buildTechnicalRow('Model Accuracy', '99.58%'),
                _buildTechnicalRow('Sensitivity', '99.87%'),
                _buildTechnicalRow('Specificity', '99.24%'),
                _buildTechnicalRow('Processing', result['isOnDevice'] == true ? 'On-Device (TFLite)' : 'Cloud-Based'),
                _buildTechnicalRow('Raw Score', (result['confidenceScore'] ?? 0).toStringAsFixed(4)),
              ],
            ),
          ),

          pw.SizedBox(height: 32),

          // Footer
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'RayScan Expertise - AI Medical Imaging',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Generated on $reportDate at $reportTime',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Save PDF
    final output = await getApplicationDocumentsDirectory();
    final file = File('${output.path}/RayScan_Report_${now.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFindingItem(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          color: PdfColors.grey800,
          height: 1.4,
        ),
      ),
    );
  }

  static pw.Widget _buildTechnicalRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> openPDF(String filePath) async {
    await OpenFilex.open(filePath);
  }
}

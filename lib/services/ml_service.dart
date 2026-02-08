import 'api_service.dart';

class MLService {
  // Predict kidney stone from ultrasound image
  static Future<Map<String, dynamic>> predictKidneyStone(String imagePath) async {
    final response = await ApiService.uploadFile(
      '/ml/predict/kidney-stone',
      imagePath,
      fileFieldName: 'image',
    );
    return response['report'];
  }

  // Get all ultrasound reports
  static Future<List<Map<String, dynamic>>> getReports({String? scanType}) async {
    String endpoint = '/ml/reports';
    if (scanType != null) {
      endpoint += '?scanType=$scanType';
    }

    final response = await ApiService.get(endpoint);
    return List<Map<String, dynamic>>.from(response['reports']);
  }

  // Get single report details
  static Future<Map<String, dynamic>> getReport(int reportId) async {
    final response = await ApiService.get('/ml/reports/$reportId');
    return response['report'];
  }

  // Check ML service health
  static Future<Map<String, dynamic>> checkMLServiceHealth() async {
    final response = await ApiService.get('/ml/ml-service/health');
    return response;
  }
}

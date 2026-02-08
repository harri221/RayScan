import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class CallService {
  /// Get missed calls for the current user
  static Future<Map<String, dynamic>> getMissedCalls() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/calls/missed'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch missed calls: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching missed calls: $e');
    }
  }

  /// Get count of missed calls
  static Future<int> getMissedCallsCount() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/calls/missed/count'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to fetch missed calls count: ${response.body}');
      }
    } catch (e) {
      return 0;
    }
  }

  /// Get call history for the current user
  static Future<Map<String, dynamic>> getCallHistory({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/chat/calls/history?page=$page&limit=$limit'),
        headers: ApiService.headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch call history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching call history: $e');
    }
  }

  /// Mark missed calls as seen
  static Future<void> markMissedCallsAsSeen(List<int> callIds) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/chat/calls/missed/mark-seen'),
        headers: ApiService.headers,
        body: json.encode({
          'callIds': callIds,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark missed calls as seen: ${response.body}');
      }
    } catch (e) {
      // Silently fail for marking as seen
    }
  }

  /// Format call duration in minutes:seconds
  static String formatDuration(int seconds) {
    if (seconds == 0) return '0:00';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get call status display text
  static String getCallStatusText(String status) {
    switch (status) {
      case 'initiated':
        return 'Initiated';
      case 'ringing':
        return 'Ringing';
      case 'answered':
        return 'Answered';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      case 'ended':
        return 'Ended';
      case 'failed':
        return 'Failed';
      default:
        return status;
    }
  }
}

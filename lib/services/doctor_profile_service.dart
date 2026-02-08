import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class DoctorProfileService {
  // Get doctor's own profile
  static Future<Map<String, dynamic>> getDoctorProfile() async {
    try {
      final response = await ApiService.get('/doctor/profile');
      return response;
    } catch (e) {
      throw Exception('Failed to load doctor profile: $e');
    }
  }

  // Update doctor profile
  static Future<Map<String, dynamic>> updateDoctorProfile({
    String? bio,
    String? qualification,
    int? experienceYears,
    double? consultationFee,
    String? clinicAddress,
    String? clinicPhone,
    String? specialization,
  }) async {
    try {
      final response = await ApiService.put('/doctor/profile', {
        if (bio != null) 'bio': bio,
        if (qualification != null) 'qualification': qualification,
        if (experienceYears != null) 'experienceYears': experienceYears,
        if (consultationFee != null) 'consultationFee': consultationFee,
        if (clinicAddress != null) 'clinicAddress': clinicAddress,
        if (clinicPhone != null) 'clinicPhone': clinicPhone,
        if (specialization != null) 'specialization': specialization,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/doctor/profile/image'),
      );

      // Add auth header
      if (ApiService.token != null) {
        request.headers['Authorization'] = 'Bearer ${ApiService.token}';
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Get doctor's schedule
  static Future<List<Map<String, dynamic>>> getDoctorSchedule() async {
    try {
      final response = await ApiService.get('/doctor/schedule');
      return List<Map<String, dynamic>>.from(response['schedule']);
    } catch (e) {
      throw Exception('Failed to load schedule: $e');
    }
  }

  // Add a new schedule time slot
  static Future<Map<String, dynamic>> addScheduleSlot({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    bool isAvailable = true,
  }) async {
    try {
      final response = await ApiService.post('/doctor/schedule', {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isAvailable': isAvailable,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to add schedule slot: $e');
    }
  }

  // Update a specific schedule slot by ID
  static Future<Map<String, dynamic>> updateScheduleSlot({
    required int slotId,
    String? startTime,
    String? endTime,
    bool? isAvailable,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (startTime != null) body['startTime'] = startTime;
      if (endTime != null) body['endTime'] = endTime;
      if (isAvailable != null) body['isAvailable'] = isAvailable;

      final response = await ApiService.put('/doctor/schedule/$slotId', body);
      return response;
    } catch (e) {
      throw Exception('Failed to update schedule slot: $e');
    }
  }

  // Delete a specific schedule slot by ID
  static Future<void> deleteScheduleSlot(int slotId) async {
    try {
      await ApiService.delete('/doctor/schedule/slot/$slotId');
    } catch (e) {
      throw Exception('Failed to delete schedule slot: $e');
    }
  }

  // Delete all schedules for a specific day
  static Future<void> deleteScheduleDay(String dayOfWeek) async {
    try {
      await ApiService.delete('/doctor/schedule/day/$dayOfWeek');
    } catch (e) {
      throw Exception('Failed to delete schedules for day: $e');
    }
  }

  // Get doctor's appointments
  static Future<List<Map<String, dynamic>>> getDoctorAppointments({
    String? status,
    bool? upcoming,
  }) async {
    try {
      String endpoint = '/doctor/appointments';

      List<String> queryParams = [];
      if (status != null) queryParams.add('status=$status');
      if (upcoming != null) queryParams.add('upcoming=$upcoming');

      if (queryParams.isNotEmpty) {
        endpoint += '?${queryParams.join('&')}';
      }

      final response = await ApiService.get(endpoint);
      return List<Map<String, dynamic>>.from(response['appointments']);
    } catch (e) {
      throw Exception('Failed to load appointments: $e');
    }
  }

  // Get appointment details
  static Future<Map<String, dynamic>> getAppointmentDetails(int appointmentId) async {
    try {
      final response = await ApiService.get('/doctor/appointments/$appointmentId');
      return response['appointment'];
    } catch (e) {
      throw Exception('Failed to load appointment details: $e');
    }
  }

  // Update appointment status
  static Future<Map<String, dynamic>> updateAppointmentStatus({
    required int appointmentId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await ApiService.put('/doctor/appointments/$appointmentId/status', {
        'status': status,
        if (notes != null) 'notes': notes,
      });
      return response;
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Cancel appointment
  static Future<void> cancelAppointment(int appointmentId, {String? reason}) async {
    try {
      await ApiService.put('/doctor/appointments/$appointmentId/cancel', {
        if (reason != null) 'reason': reason,
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Get doctor statistics
  static Future<Map<String, dynamic>> getDoctorStats() async {
    try {
      final response = await ApiService.get('/doctor/stats');
      return response['stats'];
    } catch (e) {
      throw Exception('Failed to load stats: $e');
    }
  }

  // Get doctor's patients (patients who have booked appointments)
  static Future<List<Map<String, dynamic>>> getDoctorPatients() async {
    try {
      final response = await ApiService.get('/doctor/patients');
      return List<Map<String, dynamic>>.from(response['patients']);
    } catch (e) {
      throw Exception('Failed to load patients: $e');
    }
  }
}

import '../models/doctor.dart';
import 'api_service.dart';

class DoctorService {
  // Get all doctors
  static Future<List<Doctor>> getAllDoctors() async {
    try {
      final response = await ApiService.get('/doctors');
      final doctorsData = response['doctors'] as List;
      return doctorsData.map((doctorJson) => Doctor.fromJson(doctorJson)).toList();
    } catch (e) {
      throw Exception('Failed to load doctors: $e');
    }
  }

  // Get doctor by ID
  static Future<Doctor> getDoctorById(int id) async {
    try {
      final response = await ApiService.get('/doctors/$id');
      return Doctor.fromJson(response['doctor']);
    } catch (e) {
      throw Exception('Failed to load doctor: $e');
    }
  }

  // Search doctors
  static Future<List<Doctor>> searchDoctors(String query) async {
    try {
      final response = await ApiService.get('/doctors/search/$query');
      final doctorsData = response['doctors'] as List;
      return doctorsData.map((doctorJson) => Doctor.fromJson(doctorJson)).toList();
    } catch (e) {
      throw Exception('Failed to search doctors: $e');
    }
  }

  // Get doctors by specialty
  static Future<List<Doctor>> getDoctorsBySpecialty(String specialty) async {
    try {
      final response = await ApiService.get('/doctors?specialty=$specialty');
      final doctorsData = response['doctors'] as List;
      return doctorsData.map((doctorJson) => Doctor.fromJson(doctorJson)).toList();
    } catch (e) {
      throw Exception('Failed to load doctors by specialty: $e');
    }
  }

  // Get doctor specialties
  static Future<List<String>> getSpecialties() async {
    try {
      final response = await ApiService.get('/doctors/specialties/list');
      return List<String>.from(response['specialties']);
    } catch (e) {
      throw Exception('Failed to load specialties: $e');
    }
  }

  // Get doctor's patients
  static Future<List<Map<String, dynamic>>> getDoctorPatients(int doctorId) async {
    try {
      final response = await ApiService.get('/doctors/$doctorId/patients');
      final patientsData = response['patients'] as List;
      return patientsData.map((patient) => patient as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to load doctor patients: $e');
    }
  }
}
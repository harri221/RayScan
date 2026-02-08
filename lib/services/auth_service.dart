import '../models/user.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // User login
  static Future<AuthResponse> login(String email, String password) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final authResponse = AuthResponse.fromJson(response);
    await ApiService.saveToken(authResponse.token);

    // Save user data to SharedPreferences for Socket.io authentication
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', authResponse.user.id);
    await prefs.setString('user_name', authResponse.user.name);

    // Determine user type based on response data
    // If response contains 'userType' or 'role', use it; otherwise default to 'user'
    final userType = response['userType'] ?? response['role'] ?? 'user';
    await prefs.setString('user_type', userType);

    print('✅ Saved to SharedPreferences: user_id=${authResponse.user.id}, user_type=$userType');

    return authResponse;
  }

  // User signup
  static Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
  }) async {
    final response = await ApiService.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
    });

    final authResponse = AuthResponse.fromJson(response);
    await ApiService.saveToken(authResponse.token);

    // Save user data to SharedPreferences for Socket.io authentication
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', authResponse.user.id);
    await prefs.setString('user_name', authResponse.user.name);
    final userType = response['userType'] ?? response['role'] ?? 'user';
    await prefs.setString('user_type', userType);

    return authResponse;
  }

  // Forgot password - request reset code
  static Future<ApiResponse> forgotPassword(String contactInfo, String contactType) async {
    final response = await ApiService.post('/auth/forgot-password', {
      'contactInfo': contactInfo,
      'contactType': contactType,
    });

    return ApiResponse.fromJson(response);
  }

  // Verify reset code
  static Future<Map<String, dynamic>> verifyResetCode({
    required String contactInfo,
    required String contactType,
    required String verificationCode,
  }) async {
    final response = await ApiService.post('/auth/verify-reset-code', {
      'contactInfo': contactInfo,
      'contactType': contactType,
      'verificationCode': verificationCode,
    });

    return response;
  }

  // Reset password
  static Future<ApiResponse> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await ApiService.post('/auth/reset-password', {
      'resetToken': resetToken,
      'newPassword': newPassword,
    });

    return ApiResponse.fromJson(response);
  }

  // Doctor registration
  static Future<AuthResponse> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    String? phone,
    String? gender,
    required String pmdcNumber,
    required String specialization,
    String? qualification,
    int? experienceYears,
    double? consultationFee,
    String? clinicAddress,
    String? clinicPhone,
    String? bio,
  }) async {
    final response = await ApiService.post('/auth/doctor/signup', {
      'fullName': fullName,
      'email': email,
      'password': password,
      if (phone != null) 'phone': phone,
      if (gender != null) 'gender': gender,
      'pmdcNumber': pmdcNumber,
      'specialization': specialization,
      if (qualification != null) 'qualification': qualification,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (consultationFee != null) 'consultationFee': consultationFee,
      if (clinicAddress != null) 'clinicAddress': clinicAddress,
      if (clinicPhone != null) 'clinicPhone': clinicPhone,
      if (bio != null) 'bio': bio,
    });

    final authResponse = AuthResponse.fromJson(response);
    await ApiService.saveToken(authResponse.token);

    // Save user data to SharedPreferences for Socket.io authentication
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', authResponse.user.id);
    await prefs.setString('user_name', authResponse.user.name);
    final userType = response['userType'] ?? response['role'] ?? 'doctor';
    await prefs.setString('user_type', userType);

    return authResponse;
  }

  // Get user profile
  static Future<User> getProfile() async {
    final response = await ApiService.get('/user/profile');
    return User.fromJson(response['user']);
  }

  // Logout
  static Future<void> logout() async {
    await ApiService.clearToken();
  }

  // Check if user is logged in
  static bool get isLoggedIn => ApiService.isLoggedIn;
}
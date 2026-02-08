import 'api_service.dart';

class UserService {
  // Get current user profile
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await ApiService.get('/user/profile');
    return response['user'];
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
  }) async {
    final response = await ApiService.put('/users/profile', {
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (gender != null) 'gender': gender,
      if (address != null) 'address': address,
    });
    return response['user'];
  }

  // Upload profile image
  static Future<Map<String, dynamic>> uploadProfileImage(String imagePath) async {
    final response = await ApiService.uploadFile(
      '/users/profile/image',
      imagePath,
      fileFieldName: 'profileImage',
    );
    return response['user'];
  }
}

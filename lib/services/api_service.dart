import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // DEPLOYMENT MODE: Change this to switch between local and cloud
  // ============================================================
  static const bool USE_CLOUD = true; // Set to true for cloud deployment
  static const bool USE_REAL_DEVICE = true; // Set to false for emulator (when USE_CLOUD is false)
  static const String LAPTOP_IP = '192.168.1.9'; // Your laptop's IP (when USE_CLOUD is false)

  // Cloud backend URL (Railway deployment)
  // TODO: Replace this with your Railway URL after deployment
  static const String CLOUD_URL = 'https://rayscan-production.up.railway.app';

  static String get baseUrl {
    // If using cloud deployment, always use cloud URL
    if (USE_CLOUD) {
      return '$CLOUD_URL/api';
    }

    // Local development mode
    if (kIsWeb) {
      // For web browsers
      return 'http://localhost:3002/api';
    } else if (Platform.isAndroid) {
      // For physical Android device connected via USB or WiFi
      if (USE_REAL_DEVICE) {
        return 'http://$LAPTOP_IP:3002/api';
      }
      // For Android emulator
      return 'http://10.0.2.2:3002/api';
    } else if (Platform.isIOS) {
      // For iOS simulator or physical device
      if (USE_REAL_DEVICE) {
        return 'http://$LAPTOP_IP:3002/api';
      }
      return 'http://localhost:3002/api';
    } else {
      // Default fallback
      return 'http://localhost:3002/api';
    }
  }
  static String? _token;

  // Initialize token from storage
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Save token to storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }

  // Clear token from storage
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
  }

  // Get stored token
  static String? get token => _token;
  static bool get isLoggedIn => _token != null;

  // Get headers with authentication
  static Map<String, String> get headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }

    return headers;
  }

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // PUT request
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // DELETE request
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Upload file with multipart/form-data
  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    String filePath, {
    String fileFieldName = 'file',
    Map<String, String>? additionalData,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );

      // Add authorization header
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }

      // Add file
      final file = await http.MultipartFile.fromPath(fileFieldName, filePath);
      request.files.add(file);

      // Add additional form fields
      if (additionalData != null) {
        request.fields.addAll(additionalData);
      }

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('No internet connection. Please check your network.');
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Handle HTTP response
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = jsonDecode(response.body);

    switch (response.statusCode) {
      case 200:
      case 201:
        return data;
      case 400:
        throw Exception(data['error'] ?? 'Bad request');
      case 401:
        clearToken(); // Clear invalid token
        throw Exception('Session expired. Please login again.');
      case 403:
        throw Exception(data['error'] ?? 'Access forbidden');
      case 404:
        throw Exception(data['error'] ?? 'Resource not found');
      case 500:
        throw Exception('Server error. Please try again later.');
      default:
        throw Exception(data['error'] ?? 'Unexpected error occurred');
    }
  }

  // Health check
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Backend server is not responding');
      }
    } catch (e) {
      throw Exception('Cannot connect to backend server: $e');
    }
  }
}
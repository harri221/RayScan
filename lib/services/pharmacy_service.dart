import '../models/pharmacy.dart';
import 'api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PharmacyService {
  // ==========================================
  // FREE OpenStreetMap API Methods (No Backend Required)
  // ==========================================

  // Get user's current location
  static Future<Position> getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission denied forever. Please enable in settings.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Fetch nearby pharmacies using OpenStreetMap Nominatim API (Free)
  static Future<List<Map<String, dynamic>>> fetchNearbyPharmaciesOSM(
    double lat,
    double lon,
  ) async {
    // Search area: approx 3-4km radius using bounding box
    // 1 degree latitude ≈ 111 km, so 0.036 ≈ 4 km
    final double delta = 0.036; // ~4km radius
    final viewbox =
        '${lon - delta},${lat + delta},${lon + delta},${lat - delta}';

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?'
      'format=json&'
      'q=pharmacy&'
      'limit=50&' // Increased limit to get more pharmacies in larger radius
      'extratags=1&'
      'addressdetails=1&'
      'bounded=1&'
      'viewbox=$viewbox',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'RayScan-Healthcare-App/1.0',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      // Parse and return pharmacy data
      return data.map<Map<String, dynamic>>((pharmacy) {
        // Extract phone number, check multiple fields
        String? phone = pharmacy['extratags']?['phone'] ??
                       pharmacy['extratags']?['contact:phone'] ??
                       pharmacy['address']?['phone'];

        return {
          'id': pharmacy['place_id'] ?? 0,
          'name': pharmacy['display_name']?.split(',')[0] ?? 'Pharmacy',
          'fullAddress': pharmacy['display_name'] ?? 'Address not available',
          'latitude': double.tryParse(pharmacy['lat'] ?? '0') ?? 0.0,
          'longitude': double.tryParse(pharmacy['lon'] ?? '0') ?? 0.0,
          'phone': phone, // null if not available
          'type': pharmacy['type'] ?? 'pharmacy',
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch pharmacies: ${response.statusCode}');
    }
  }

  // Calculate distance between two coordinates (in kilometers)
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // ==========================================
  // Backend API Methods (Original)
  // ==========================================

  // Get all pharmacies
  static Future<List<Pharmacy>> getAllPharmacies({
    double? latitude,
    double? longitude,
    double? radius,
  }) async {
    String endpoint = '/pharmacy';

    if (latitude != null && longitude != null) {
      endpoint += '?latitude=$latitude&longitude=$longitude';
      if (radius != null) {
        endpoint += '&radius=$radius';
      }
    }

    final response = await ApiService.get(endpoint);
    final pharmaciesData = response['pharmacies'] as List;

    return pharmaciesData.map((data) => Pharmacy.fromJson(data)).toList();
  }

  // Get pharmacy by ID with products
  static Future<PharmacyDetail> getPharmacyById(int id) async {
    final response = await ApiService.get('/pharmacy/$id');
    return PharmacyDetail.fromJson(response['pharmacy']);
  }

  // Search pharmacies
  static Future<List<Pharmacy>> searchPharmacies(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    String endpoint = '/pharmacy/search/$query';

    if (latitude != null && longitude != null) {
      endpoint += '?latitude=$latitude&longitude=$longitude';
    }

    final response = await ApiService.get(endpoint);
    final pharmaciesData = response['pharmacies'] as List;

    return pharmaciesData.map((data) => Pharmacy.fromJson(data)).toList();
  }

  // Get pharmacy products
  static Future<List<PharmacyProduct>> getPharmacyProducts(
    int pharmacyId, {
    String? category,
    bool? inStock,
  }) async {
    String endpoint = '/pharmacy/$pharmacyId/products';

    List<String> queryParams = [];
    if (category != null) queryParams.add('category=$category');
    if (inStock != null) queryParams.add('inStock=$inStock');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await ApiService.get(endpoint);
    final productsData = response['products'] as List;

    return productsData.map((data) => PharmacyProduct.fromJson(data)).toList();
  }

  // Search products across all pharmacies
  static Future<List<ProductWithPharmacy>> searchProducts(
    String query, {
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    String endpoint = '/pharmacy/products/search/$query';

    List<String> queryParams = [];
    if (category != null) queryParams.add('category=$category');
    if (latitude != null) queryParams.add('latitude=$latitude');
    if (longitude != null) queryParams.add('longitude=$longitude');

    if (queryParams.isNotEmpty) {
      endpoint += '?${queryParams.join('&')}';
    }

    final response = await ApiService.get(endpoint);
    final productsData = response['products'] as List;

    return productsData.map((data) => ProductWithPharmacy.fromJson(data)).toList();
  }

  // Get product categories
  static Future<List<String>> getProductCategories() async {
    final response = await ApiService.get('/pharmacy/categories/list');
    final categoriesData = response['categories'] as List;

    return categoriesData.map((category) => category.toString()).toList();
  }

  // Get nearby pharmacies with specific product
  static Future<List<Pharmacy>> getNearbyPharmaciesWithProduct(
    String productName, {
    required double latitude,
    required double longitude,
    double radius = 10,
  }) async {
    final endpoint = '/pharmacy/nearby-with-product/$productName'
        '?latitude=$latitude&longitude=$longitude&radius=$radius';

    final response = await ApiService.get(endpoint);
    final pharmaciesData = response['pharmacies'] as List;

    return pharmaciesData.map((data) => Pharmacy.fromJson(data)).toList();
  }
}
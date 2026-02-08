import 'package:flutter/material.dart';
import 'pharmacy_detail_screen.dart';
import '../services/pharmacy_service.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  List<Map<String, dynamic>> pharmacies = [];
  bool isLoading = true;
  String? errorMessage;
  double? userLat;
  double? userLon;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  Future<void> _loadPharmacies() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get user's current location
      final position = await PharmacyService.getUserLocation();
      userLat = position.latitude;
      userLon = position.longitude;

      // DEBUG: Print actual GPS coordinates
      print('DEBUG: User location: $userLat, $userLon');

      // Fetch nearby pharmacies from OpenStreetMap (FREE API)
      final loadedPharmacies = await PharmacyService.fetchNearbyPharmaciesOSM(
        userLat!,
        userLon!,
      );

      // Calculate distance for each pharmacy
      for (var pharmacy in loadedPharmacies) {
        final distance = PharmacyService.calculateDistance(
          userLat!,
          userLon!,
          pharmacy['latitude'],
          pharmacy['longitude'],
        );
        pharmacy['distance'] = distance.toStringAsFixed(2);
      }

      // Sort by distance
      loadedPharmacies.sort((a, b) =>
          double.parse(a['distance']).compareTo(double.parse(b['distance'])));

      setState(() {
        pharmacies = loadedPharmacies;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Nearby Pharmacies',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadPharmacies,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0E807F)),
            SizedBox(height: 16),
            Text('Loading pharmacies...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading pharmacies',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPharmacies,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E807F),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (pharmacies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_pharmacy_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pharmacies found nearby',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Try searching in a different location',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPharmacies,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pharmacies.length,
        itemBuilder: (context, index) {
          final pharmacy = pharmacies[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _pharmacyCard(pharmacy: pharmacy),
          );
        },
      ),
    );
  }

  Widget _pharmacyCard({required Map<String, dynamic> pharmacy}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacyDetailScreen(
              pharmacy: pharmacy,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF0E807F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_pharmacy,
                color: Color(0xFF0E807F),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy['name'] ?? 'Pharmacy',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pharmacy['fullAddress'] ?? 'Address not available',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${pharmacy['distance']} km away',
                        style: const TextStyle(
                          color: Color(0xFF0E807F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

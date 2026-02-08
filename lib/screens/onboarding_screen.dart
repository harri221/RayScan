import 'package:flutter/material.dart';
import 'role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> introData = [
    {
      'title': 'Doctor Consultation',
      'desc': 'Connect with certified doctors anytime, anywhere.',
      'img': 'https://cdn-icons-png.flaticon.com/512/3621/3621384.png',
    },
    {
      'title': 'Ultrasound Scans',
      'desc': 'Upload your scan and get AI-based evaluation.',
      'img': 'https://cdn-icons-png.flaticon.com/512/2920/2920244.png',
    },
    {
      'title': 'AI-Based Analysis',
      'desc': 'Smart detection for breast cancer & kidney stones.',
      'img': 'https://cdn-icons-png.flaticon.com/512/6063/6063811.png',
    },
    {
      'title': 'Nearby Pharmacy',
      'desc': 'Locate and contact nearby pharmacies with ease.',
      'img': 'https://cdn-icons-png.flaticon.com/512/3119/3119338.png',
    },
  ];

  void nextPage() {
    if (_currentIndex < introData.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: introData.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.network(
                    introData[index]['img']!,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 200,
                        color: Colors.grey,
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  Text(
                    introData[index]['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    introData[index]['desc']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 30,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                );
              },
              child: const Text('Skip'),
            ),
          ),
          Positioned(
            bottom: 50,
            right: 30,
            child: ElevatedButton(
              onPressed: nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0E807F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
              ),
              child: Text(
                _currentIndex == introData.length - 1 ? 'Start' : 'Next',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

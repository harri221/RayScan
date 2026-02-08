import 'package:flutter/material.dart';
import 'search_results_screen.dart';
import '../services/doctor_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchSuggestions = [
    'Cardiologist',
    'Psychologist',
    'Orthopedist',
    'Urologist',
    'Dermatologist',
    'Pediatrician',
    'Neurologist',
    'Gynecologist',
  ];
  List<String> _filteredSuggestions = [];
  bool _isLoadingSpecialties = false;

  @override
  void initState() {
    super.initState();
    _filteredSuggestions = _searchSuggestions;
    _searchController.addListener(_onSearchChanged);
    _loadSpecialties();

    // Request focus after the widget is built to prevent rapid keyboard show/hide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<void> _loadSpecialties() async {
    setState(() => _isLoadingSpecialties = true);
    try {
      final specialties = await DoctorService.getSpecialties();
      if (!mounted) return;
      setState(() {
        _searchSuggestions = specialties;
        _filteredSuggestions = specialties;
        _isLoadingSpecialties = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingSpecialties = false);
      // Keep default suggestions if API fails
    }
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredSuggestions = _searchSuggestions;
      } else {
        _filteredSuggestions = _searchSuggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: const InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: Colors.black, fontSize: 16),
          onSubmitted: (query) {
            if (query.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(query: query),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _filteredSuggestions[index];
          return ListTile(
            leading: const Icon(Icons.search, color: Colors.black),
            title: RichText(
              text: TextSpan(
                children: _buildHighlightedText(suggestion, _searchController.text),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchResultsScreen(query: suggestion),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<TextSpan> _buildHighlightedText(String suggestion, String query) {
    if (query.isEmpty) {
      return [
        TextSpan(
          text: suggestion,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ];
    }

    final lowerSuggestion = suggestion.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final startIndex = lowerSuggestion.indexOf(lowerQuery);

    if (startIndex == -1) {
      return [
        TextSpan(
          text: suggestion,
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      ];
    }

    return [
      if (startIndex > 0)
        TextSpan(
          text: suggestion.substring(0, startIndex),
          style: const TextStyle(color: Colors.black, fontSize: 16),
        ),
      TextSpan(
        text: suggestion.substring(startIndex, startIndex + query.length),
        style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      if (startIndex + query.length < suggestion.length)
        TextSpan(
          text: suggestion.substring(startIndex + query.length),
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
    ];
  }
}
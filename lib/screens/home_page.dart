import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/screens/upload_ingredients_screen.dart';
import 'package:untitled/screens/view_ingredients_screen.dart';
import 'package:untitled/screens/recommendation_screen.dart';
import 'package:untitled/components/base_auth_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<dynamic> latestRecommendations = [];
  bool _isFetchingRecommendations = false;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchLatestRecommendations(); // Load history on init
  }

  Future<void> _checkAuth() async {
    await BaseAuth.redirectIfNotAuthenticated(context);
    setState(() {});
  }

  void _logout() async {
    await BaseAuth.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == 4) {
      _logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() {
      _isFetchingRecommendations = true;
      _recommendationError = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${BaseAuth.baseUrl}/recommend-recipes'),
        headers: {'Authorization': 'Bearer ${BaseAuth.getAccessToken()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          latestRecommendations = data['recommendations'] ?? [];
        });
      } else {
        setState(() {
          _recommendationError =
              'Failed to fetch recommendations: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _recommendationError = 'Error fetching recommendations: $e';
      });
    } finally {
      setState(() => _isFetchingRecommendations = false);
    }
  }

  Future<void> _fetchLatestRecommendations() async {
    try {
      final response = await http.get(
        Uri.parse(
          '${BaseAuth.baseUrl}/home',
        ), // Use /home to get user data including latestRecommendations
        headers: {'Authorization': 'Bearer ${BaseAuth.getAccessToken()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          latestRecommendations = data['user']['latestRecommendations'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching latest recommendations: $e');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const UploadIngredientsScreen();
      case 2:
        return const ViewIngredientsScreen();
      case 3:
        return const RecommendationsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return BaseAuthScreen(
      headerText: 'Welcome Home',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF123B42),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  BaseAuth.getUsername() ?? 'User',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123B42),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(0xFF123B42)),
                  onPressed: _logout,
                  tooltip: 'Logout',
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed:
                  _isFetchingRecommendations ? null : _fetchRecommendations,
              icon:
                  _isFetchingRecommendations
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.recommend, color: Colors.white),
              label: Text(
                _isFetchingRecommendations
                    ? 'Fetching...'
                    : 'Get a Recommendation',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF123B42),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 5,
              ),
            ),
            const SizedBox(height: 20),
            if (_recommendationError != null)
              Text(
                _recommendationError!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            const Text(
              'Latest Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B42),
              ),
            ),
            const SizedBox(height: 10),
            latestRecommendations.isEmpty
                ? const Text(
                  'No recent recommendations yet.',
                  style: TextStyle(color: Colors.grey),
                )
                : SizedBox(
                  height: 200, // Fixed height for history
                  child: ListView.builder(
                    itemCount: latestRecommendations.length,
                    itemBuilder: (context, index) {
                      final rec = latestRecommendations[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: ListTile(
                          title: Text(
                            rec['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF123B42),
                            ),
                          ),
                          subtitle: Text(
                            'Matched: ${rec['matchedIngredients'].join(', ')}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'View'),
            BottomNavigationBarItem(
              icon: Icon(Icons.recommend),
              label: 'Recommendations',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF123B42),
        ),
      ),
    );
  }
}

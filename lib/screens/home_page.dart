import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/screens/upload_ingredients_screen.dart';
import 'package:untitled/screens/view_ingredients_screen.dart';
import 'package:untitled/screens/recommendations_screen.dart';
import 'package:untitled/screens/recipe_details_screen.dart'; // Import the new screen
import 'package:untitled/components/base_auth_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<dynamic> recommendations = [];
  List<dynamic> lastCookedDishes = [];
  List<dynamic> favoriteDishes = [];
  bool _isFetchingRecommendations = false;
  String? _recommendationError;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchUserData();
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
          recommendations = data['recommendations'] ?? [];
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

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${BaseAuth.baseUrl}/home'),
        headers: {'Authorization': 'Bearer ${BaseAuth.getAccessToken()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          lastCookedDishes = data['user']['lastCookedDishes'] ?? [];
          favoriteDishes = data['user']['favoriteDishes'] ?? [];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _markAsCooked(dynamic dish) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/mark-cooked'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dish),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          lastCookedDishes = data['lastCookedDishes'] ?? lastCookedDishes;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark as cooked: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking as cooked: $e')));
    }
  }

  Future<void> _toggleFavorite(dynamic dish) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/toggle-favorite'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(dish),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          favoriteDishes = data['favoriteDishes'] ?? favoriteDishes;
          favoriteDishes = favoriteDishes.toSet().toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle favorite: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error toggling favorite: $e')));
    }
  }

  Future<void> _clearCookedHistory() async {
    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/clear-cooked-history'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          lastCookedDishes = data['lastCookedDishes'] ?? [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cooked history cleared successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear history: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error clearing history: $e')));
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
        child: SingleChildScrollView(
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
              if (recommendations.isNotEmpty) ...[
                const Text(
                  'Recommended Dishes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123B42),
                  ),
                ),

                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: recommendations.length,
                    itemBuilder: (context, index) {
                      final rec = recommendations[index];
                      final isFavorited = favoriteDishes.any(
                        (fav) => fav['name'] == rec['name'],
                      );
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        RecipeDetailsScreen(recipe: rec),
                              ),
                            );
                          },
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
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFavorited
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color:
                                        isFavorited ? Colors.red : Colors.grey,
                                  ),
                                  onPressed: () => _toggleFavorite(rec),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.green,
                                  ),
                                  onPressed: () => _markAsCooked(rec),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Favorite Dishes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 10),
              favoriteDishes.isEmpty
                  ? const Text(
                    'No favorite dishes yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                  : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: favoriteDishes.length,
                      itemBuilder: (context, index) {
                        final fav = favoriteDishes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              fav['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF123B42),
                              ),
                            ),
                            subtitle: Text(
                              'Matched: ${fav['matchedIngredients'].join(', ')}',
                              style: const TextStyle(color: Colors.green),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _toggleFavorite(fav),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Last Cooked Dishes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123B42),
                    ),
                  ),
                  if (lastCookedDishes.isNotEmpty)
                    TextButton(
                      onPressed: _clearCookedHistory,
                      child: const Text(
                        'Clear History',
                        style: TextStyle(
                          color: Color(0xFF123B42),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              lastCookedDishes.isEmpty
                  ? const Text(
                    'No dishes cooked yet.',
                    style: TextStyle(color: Colors.grey),
                  )
                  : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: lastCookedDishes.length,
                      itemBuilder: (context, index) {
                        final cooked = lastCookedDishes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: ListTile(
                            title: Text(
                              cooked['name'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF123B42),
                              ),
                            ),
                            subtitle: Text(
                              'Cooked on: ${cooked['timestamp'].substring(0, 10)}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            ],
          ),
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

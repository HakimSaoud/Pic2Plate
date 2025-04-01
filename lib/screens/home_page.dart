import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/screens/upload_ingredients_screen.dart';
import 'package:untitled/screens/view_ingredients_screen.dart';
import 'package:untitled/screens/recommendations_screen.dart';
import 'package:untitled/screens/recipe_details_screen.dart';
import 'package:untitled/screens/account_settings_screen.dart';
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
  bool _showFullHistory = false;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          _showFullHistory = false; // Reset to hide history after clearing
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

  Future<void> _removeCookedDish(String dishName) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/remove-cooked-dish'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': dishName}),
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
          SnackBar(content: Text('Failed to remove dish: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing dish: $e')));
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
      case 4:
        return const AccountSettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    const referenceWidth = 375.0; // Reference width (e.g., iPhone 11)
    const baseFontSize = 16.0; // Base font size for reference width
    final responsiveFontSize = (screenWidth / referenceWidth) * baseFontSize;
    final fontSize = responsiveFontSize.clamp(12.0, 18.0); // Clamp font size
    final listTilePadding =
        screenWidth < 360 ? 6.0 : 8.0; // Adjust ListTile padding

    return BaseAuthScreen(
      headerText: 'Welcome Home',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: screenWidth < 360 ? 16 : 20,
                    backgroundColor: const Color(0xFF123B42),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: screenWidth < 360 ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      BaseAuth.getUsername() ?? 'User',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF123B42),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: const Color(0xFF123B42),
                      size: screenWidth < 360 ? 20 : 24,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 4; // Navigate to Account Settings
                      });
                    },
                    tooltip: 'Account Settings',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed:
                        _isFetchingRecommendations
                            ? null
                            : _fetchRecommendations,
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
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF123B42),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 16 : 20,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_recommendationError != null)
                    Text(
                      _recommendationError!,
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: fontSize * 0.9,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  const SizedBox(height: 10),
                  if (recommendations.isNotEmpty) ...[
                    Text(
                      'Recommended Dishes',
                      style: TextStyle(
                        fontSize: fontSize * 1.1,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF123B42),
                      ),
                    ),
                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: recommendations.length,
                        itemBuilder: (context, index) {
                          final rec = recommendations[index];
                          final isFavorited = favoriteDishes.any(
                            (fav) => fav['name'] == rec['name'],
                          );
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
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
                                contentPadding: EdgeInsets.all(listTilePadding),
                                title: Text(
                                  rec['name'],
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF123B42),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Matched: ${rec['matchedIngredients'].join(', ')}',
                                  style: const TextStyle(color: Colors.green),
                                  overflow: TextOverflow.ellipsis,
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
                                            isFavorited
                                                ? Colors.red
                                                : Colors.grey,
                                        size: screenWidth < 360 ? 18 : 20,
                                      ),
                                      onPressed: () => _toggleFavorite(rec),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: screenWidth < 360 ? 18 : 20,
                                      ),
                                      onPressed: () => _markAsCooked(rec),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
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
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Favorite Dishes',
                style: TextStyle(
                  fontSize: fontSize * 1.1,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 5),
              favoriteDishes.isEmpty
                  ? Text(
                    'No favorite dishes yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: fontSize * 0.9,
                    ),
                  )
                  : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: favoriteDishes.length,
                    itemBuilder: (context, index) {
                      final fav = favoriteDishes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        RecipeDetailsScreen(recipe: fav),
                              ),
                            );
                          },
                          child: ListTile(
                            contentPadding: EdgeInsets.all(listTilePadding),
                            title: Text(
                              fav['name'],
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF123B42),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              'Matched: ${fav['matchedIngredients'].join(', ')}',
                              style: const TextStyle(color: Colors.green),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red,
                                size: screenWidth < 360 ? 18 : 20,
                              ),
                              onPressed: () => _toggleFavorite(fav),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Cooked Dishes',
                    style: TextStyle(
                      fontSize: fontSize * 1.1,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF123B42),
                    ),
                  ),
                  if (lastCookedDishes.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showFullHistory = !_showFullHistory;
                        });
                      },
                      child: Text(
                        _showFullHistory ? 'Hide History' : 'Show All History',
                        style: TextStyle(
                          color: const Color(0xFF123B42),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              lastCookedDishes.isEmpty
                  ? Text(
                    'No dishes cooked yet.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: fontSize * 0.9,
                    ),
                  )
                  : _showFullHistory
                  ? Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: lastCookedDishes.length,
                        itemBuilder: (context, index) {
                          final cooked = lastCookedDishes[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            RecipeDetailsScreen(recipe: cooked),
                                  ),
                                );
                              },
                              child: ListTile(
                                contentPadding: EdgeInsets.all(listTilePadding),
                                title: Text(
                                  cooked['name'],
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF123B42),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  'Cooked on: ${cooked['timestamp'].substring(0, 10)}',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: fontSize * 0.9,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: screenWidth < 360 ? 18 : 20,
                                  ),
                                  onPressed:
                                      () => _removeCookedDish(cooked['name']),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _clearCookedHistory,
                        child: Text(
                          'Clear All History',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => RecipeDetailsScreen(
                                  recipe: lastCookedDishes.last,
                                ),
                          ),
                        );
                      },
                      child: ListTile(
                        contentPadding: EdgeInsets.all(listTilePadding),
                        title: Text(
                          lastCookedDishes.last['name'],
                          style: TextStyle(
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF123B42),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Cooked on: ${lastCookedDishes.last['timestamp'].substring(0, 10)}',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: fontSize * 0.9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
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

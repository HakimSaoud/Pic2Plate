import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/components/base_auth_screen.dart';

class ViewIngredientsScreen extends StatefulWidget {
  const ViewIngredientsScreen({super.key});

  @override
  State<ViewIngredientsScreen> createState() => _ViewIngredientsScreenState();
}

class _ViewIngredientsScreenState extends State<ViewIngredientsScreen> {
  List<Map<String, String>> ingredients = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuth();
    _fetchIngredients();
  }

  Future<void> _checkAuth() async {
    await BaseAuth.redirectIfNotAuthenticated(context);
  }

  Future<void> _fetchIngredients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${BaseAuth.baseUrl}/identify-ingredients'),
        headers: {'Authorization': 'Bearer ${BaseAuth.getAccessToken()}'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['newAccessToken'] != null &&
            data['newAccessToken'] is String) {
          BaseAuth.updateTokens(accessToken: data['newAccessToken']);
        }
        setState(() {
          ingredients =
              (data['ingredients'] as List<dynamic>)
                  .map(
                    (item) => {
                      'imagePath': (item['imagePath'] ?? '').toString(),
                      'ingredient':
                          (item['ingredient'] ?? 'unknown').toString(),
                    },
                  )
                  .toList();
        });
      } else {
        setState(() {
          ingredients = [];
          _errorMessage = 'Failed to load ingredients: ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        ingredients = [];
        _errorMessage = 'Error loading ingredients: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeIngredient(String imagePath) async {
    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/remove-ingredient'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'imagePath': imagePath}),
      );
      if (response.statusCode == 200) {
        if (jsonDecode(response.body)['newAccessToken'] != null) {
          BaseAuth.updateTokens(
            accessToken: jsonDecode(response.body)['newAccessToken'],
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingredient removed successfully!')),
        );
        _fetchIngredients();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove ingredient: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing ingredient: $e')));
    }
  }

  // Inside ViewIngredientsScreen
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage != null
        ? BaseAuthScreen(
          headerText: 'Your Ingredients',
          child: Center(
            child: Text(
              'You Have no ingredients at the moment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF123B42),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        )
        : BaseAuthScreen(
          headerText: 'Your Ingredients',
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ingredients.isEmpty
                    ? const Center(
                      child: Text(
                        'No ingredients added yet.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : Expanded(
                      child: ListView.builder(
                        itemCount: ingredients.length,
                        itemBuilder: (context, index) {
                          final item = ingredients[index];
                          final imagePath = item['imagePath']!;
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Image.network(
                                '${BaseAuth.baseUrl}/$imagePath',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.error),
                              ),
                              title: Text(item['ingredient']!),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeIngredient(imagePath),
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
}

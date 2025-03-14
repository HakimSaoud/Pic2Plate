import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:untitled/components/base_auth.dart';

class AddIngredientsScreen extends StatefulWidget {
  const AddIngredientsScreen({super.key});

  @override
  State<AddIngredientsScreen> createState() => _AddIngredientsScreenState();
}

class _AddIngredientsScreenState extends State<AddIngredientsScreen> {
  final _ingredientController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await BaseAuth.redirectIfNotAuthenticated(context);
  }

  Future<void> _addIngredient() async {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an ingredient name.')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${BaseAuth.baseUrl}/add-ingredient'),
        headers: {
          'Authorization': 'Bearer ${BaseAuth.getAccessToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'ingredient': ingredient}),
      );
      print(
        'Add Ingredient Response: Status=${response.statusCode}, Body=${response.body}',
      );
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingredient added successfully!')),
        );
        _ingredientController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to add ingredient. Status: ${response.statusCode}, Body: ${response.body}',
            ),
          ),
        );
      }
    } catch (e) {
      print('Add Ingredient Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding ingredient: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),
              const Text(
                'Add Ingredients',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _ingredientController,
                decoration: InputDecoration(
                  hintText: 'Enter ingredient name (e.g., carrot)',
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 20,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addIngredient,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF123B42),
                  minimumSize: const Size(180, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add Ingredient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

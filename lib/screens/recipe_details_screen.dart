import 'package:flutter/material.dart';
import 'package:untitled/components/base_auth_screen.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const RecipeDetailsScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: 'Recipe Details',
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe['name'],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe['ingredients'].join(', '),
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              const Text(
                'Matched Ingredients',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe['matchedIngredients'].join(', '),
                style: const TextStyle(fontSize: 16, color: Colors.green),
              ),
              const SizedBox(height: 20),
              const Text(
                'Recipe Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe['recipe'],
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

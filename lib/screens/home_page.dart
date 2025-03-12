import 'package:flutter/material.dart';
import 'package:untitled/components/BaseAuth.dart';
import 'sign_in_screen.dart'; // Import this for reference (not strictly needed with named routes)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: 'Welcome Home',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Welcome message
          const Text(
            'Hello User!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF123B42),
            ),
          ),
          const SizedBox(height: 20),
          // Some content container
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'This is your home page content. You can add more widgets here!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Logout Button
          ElevatedButton(
            onPressed: () {
              // Navigate to SignInScreen and remove all previous routes
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/signin',
                    (Route<dynamic> route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF123B42),
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Additional info
          const Text(
            'Signed in successfully',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
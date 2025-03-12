import 'package:flutter/material.dart';
import 'social_media_button.dart';

class BaseAuthScreen extends StatelessWidget {
  final Widget child; // The main content (sign-up or sign-in fields)
  final String headerText; // Header text like "Let's Join" or "Welcome Back"

  const BaseAuthScreen({
    super.key,
    required this.child,
    required this.headerText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background triangle shape
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: TrianglePainter(),
            ),
          ),
          // Back arrow
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          // Logo
          Positioned(
            top: 85,
            left: MediaQuery.of(context).size.width / 2 - 80,
            child: Image.asset(
              'assets/images/logo.png',
              width: 160,
              height: 180,
            ),
          ),
          // Header text (e.g., "Let's Join" or "Welcome Back")
          Positioned(
            top: 80,
            left: 15,
            child: Text(
              headerText,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3C34),
              ),
            ),
          ),
          // Main content (passed as a parameter)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 250), // Space for the header
                child, // The main content (sign-up or sign-in fields)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
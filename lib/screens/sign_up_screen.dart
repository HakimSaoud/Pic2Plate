import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'package:untitled/components/BaseAuth.dart';
import 'package:untitled/components/social_media_button.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: "Let's Join",
      child: Column(
        children: [
          // Username field
          TextField(
            decoration: InputDecoration(
              hintText: 'USERNAME',
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
          // Email field
          TextField(
            decoration: InputDecoration(
              hintText: 'EMAIL',
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
          // Password field
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'PASSWORD',
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
              suffixIcon: const Icon(
                Icons.visibility_off,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Confirm Password field
          TextField(
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'CONFIRM PASSWORD',
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
              suffixIcon: const Icon(
                Icons.visibility_off,
                size: 20,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Sign Up Button
          ElevatedButton(
            onPressed: () {
              // Navigate to HomePage using named route
              Navigator.pushReplacementNamed(context, '/home');
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
              'Sign Up',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // "Do you have an account?" text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Do you have an account? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate to SignInScreen using named route
                  Navigator.pushNamed(context, '/signin');
                },
                child: const Text(
                  "Sign In",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF123B42),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Social Media Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SocialMediaButton(
                icon: const Text(
                  'f',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF3B5998),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {},
              ),
              SocialMediaButton(
                icon: const Icon(
                  Icons.apple,
                  color: Colors.black,
                  size: 30,
                ),
                onPressed: () {},
              ),
              SocialMediaButton(
                icon: const Text(
                  'G',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFFDB4437),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'BaseAuth.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseAuthScreen(
      headerText: "Welcome Back",
      child: Column(
        children: [
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
          const SizedBox(height: 30),
          // Sign In Button
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF123B42),
              foregroundColor: Colors.white,
              minimumSize: const Size(180, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // "Don't have an account?" text
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navigate back to the SignUpScreen
                  Navigator.pop(context);
                },
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF123B42),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
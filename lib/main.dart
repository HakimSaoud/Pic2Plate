import 'package:flutter/material.dart';
import 'screens/sign_up_screen.dart'; // Import the SignUpScreen
import 'screens/sign_in_screen.dart'; // Import the SignInScreen

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Auth Screens',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const SignUpScreen(), // Start with the SignUpScreen
    );
  }
}
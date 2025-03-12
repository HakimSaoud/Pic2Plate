import 'package:flutter/material.dart';
import 'screens/sign_up_screen.dart'; // Ensure this path matches your project structure
import 'screens/sign_in_screen.dart'; // Ensure this path matches your project structure
import 'screens/home_page.dart'; // Ensure this path matches your project structure

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
        primaryColor: const Color(0xFF123B42), // Consistent with your app's color scheme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF123B42),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      initialRoute: '/home', // Start with the SignUpScreen
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
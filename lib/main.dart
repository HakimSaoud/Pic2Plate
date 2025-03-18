import 'package:flutter/material.dart';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/screens/sign_in_screen.dart';
import 'package:untitled/screens/sign_up_screen.dart';
import 'package:untitled/screens/home_page.dart';
import 'package:untitled/screens/upload_ingredients_screen.dart';
import 'package:untitled/screens/view_ingredients_screen.dart';
import 'package:untitled/screens/recommendation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth Demo',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const AuthWrapper(),
      routes: {
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomePage(),
        '/upload-ingredients': (context) => const UploadIngredientsScreen(),
        '/view-ingredients': (context) => const ViewIngredientsScreen(),
        '/recommendations': (context) => const RecommendationsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authenticated = await BaseAuth.isAuthenticated();
    setState(() {
      _isAuthenticated = authenticated;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isAuthenticated ? const HomePage() : const SignInScreen();
  }
}

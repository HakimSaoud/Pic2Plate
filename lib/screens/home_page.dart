import 'package:flutter/material.dart';
import 'package:untitled/components/base_auth.dart';
import 'package:untitled/screens/upload_ingredients_screen.dart';
import 'package:untitled/screens/view_ingredients_screen.dart';
import 'package:untitled/components/base_auth_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await BaseAuth.redirectIfNotAuthenticated(context);
    setState(() {}); // Refresh UI after auth check
  }

  void _logout() async {
    await BaseAuth.logout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/signin',
      (Route<dynamic> route) => false,
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) {
      _logout();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const UploadIngredientsScreen();
      case 2:
        return const ViewIngredientsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return BaseAuthScreen(
      headerText: 'Welcome Home',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                BaseAuth.getUsername() ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF123B42),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.logout, color: Color(0xFF123B42)),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12), // Top left radius
          topRight: Radius.circular(12), // Top right radius
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
            BottomNavigationBarItem(icon: Icon(Icons.view_list), label: 'View'),
            BottomNavigationBarItem(icon: Icon(Icons.logout), label: 'Logout'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF123B42),
        ),
      ),
    );
  }
}

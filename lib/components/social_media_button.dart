import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sign Up Screen',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const SignUpScreen(),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

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
              onPressed: () {},
            ),
          ),
          // Logo
          Positioned(
            top: 70, // Adjust this value to position the logo below the triangle
            left: MediaQuery.of(context).size.width / 2 - 80, // Center the logo horizontally
            child: Image.asset(
              'assets/images/logo.png', // Replace with your logo path
              width: 160, // Adjust width to fit your logo
              height: 180, // Adjust height to fit your logo
            ),
          ),
          // Let's join text
          const Positioned(
            top: 80, // Adjusted to place text below the logo
            left: 15,
            child: Text(
              "Let's Join",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3C34), // Dark teal color
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 250), // Increased space for the header (logo + text)
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
                    fillColor: const Color(0xFFF5F5F5), // Light grey
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
                    fillColor: const Color(0xFFF5F5F5), // Light grey
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
                    fillColor: const Color(0xFFF5F5F5), // Light grey
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
                    fillColor: const Color(0xFFF5F5F5), // Light grey
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

                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF123B42), // Dark teal
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
                // Social Media Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SocialMediaButton(
                      icon: const Text(
                        'f',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF3B5998), // Facebook blue
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
                          color: Color(0xFFDB4437), // Google red
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,    // Gradient starts from top
        end: Alignment.bottomCenter,   // Gradient ends at bottom
        colors: const [
          Color(0xFF41686F),          // Lighter teal color
          Color(0xFF0B1A21),          // Darker teal color
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(40, size.height * 1.3);       // Bottom-left corner
    path.lineTo(size.width, size.height * 0.1); // Top-right corner
    path.lineTo(size.width, size.height * 1.3); // Bottom-right corner
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Social Media Button Widget
class SocialMediaButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const SocialMediaButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Colors.grey, width: 1),
        ),
        minimumSize: const Size(60, 50),
        padding: const EdgeInsets.all(0),
      ),
      child: icon,
    );
  }
}
import 'package:flutter/material.dart';

class BaseAuthScreen extends StatelessWidget {
  final String headerText;
  final Widget child;

  const BaseAuthScreen({
    super.key,
    required this.headerText,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Triangle background
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: Size(
                screenWidth,
                screenHeight * 0.25,
              ), // 25% of screen height
              painter: TrianglePainter(),
            ),
          ),
          // Back button
          Positioned(
            top: screenHeight * 0.05, // 5% from top
            left: screenWidth * 0.03, // 3% from left
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: screenWidth * 0.07, // Scales with screen width
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Logo
          Positioned(
            top: screenHeight * 0.12, // 12% from top
            left: screenWidth / 2 - (screenWidth * 0.2), // Centered, width 40%
            child: Image.asset(
              'assets/images/logo.png',
              width: screenWidth * 0.4, // 40% of screen width
              height: screenHeight * 0.22, // 22% of screen height
              fit: BoxFit.contain, // Ensure logo scales properly
            ),
          ),
          // Header text
          Positioned(
            top: screenHeight * 0.10, // 10% from top
            left: screenWidth * 0.04, // 4% from left
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: screenWidth * 0.6, // Limit text width to 60%
              ),
              child: Text(
                headerText,
                style: TextStyle(
                  fontSize: screenWidth * 0.06, // Scales with screen width
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A3C34),
                ),
                overflow: TextOverflow.ellipsis, // Handle long text
              ),
            ),
          ),
          // Child content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.08,
            ), // 8% padding
            child: SizedBox(
              height: screenHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: screenHeight * 0.35), // 35% spacer
                  Expanded(child: child),
                ],
              ),
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
    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0xFF41686F), Color(0xFF0B1A21)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 1.3); // Responsive scaling
    path.lineTo(size.width, size.height * 0.1);
    path.lineTo(size.width, size.height * 1.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

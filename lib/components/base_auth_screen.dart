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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 200),
              painter: TrianglePainter(),
            ),
          ),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 100,
            left: MediaQuery.of(context).size.width / 2 - 80,
            child: Image.asset(
              'assets/images/logo.png',
              width: 160,
              height: 180,
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [const SizedBox(height: 300), Expanded(child: child)],
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
    path.moveTo(40, size.height * 1.3);
    path.lineTo(size.width, size.height * 0.1);
    path.lineTo(size.width, size.height * 1.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';

class SocialMediaButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;

  const SocialMediaButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

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

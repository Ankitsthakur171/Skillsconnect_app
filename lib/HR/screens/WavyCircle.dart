import 'package:flutter/material.dart';
import 'dart:math';

class WavyAvatar extends StatelessWidget {
  final String name;
  const WavyAvatar({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final firstLetter = (name.isNotEmpty ? name[0].toUpperCase() : "?");

    return Stack(
      alignment: Alignment.center,
      children: [
        // 🔮 Glowing circle behind
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005e6a).withOpacity(0.6),
                blurRadius: 30,
                spreadRadius: 8,
              ),
            ],
          ),
        ),

        // 🌊 Wavy border circle
        CustomPaint(
          painter: _WavyCirclePainter(),
          child: Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF005e6a), Color(0x020005e6a)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WavyCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF005e6a), Color(0xFF5A003A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const waveCount = 0;
    const waveDepth = 0;

    for (int i = 0; i <= waveCount; i++) {
      double angle = (2 * pi / waveCount) * i;
      double r = radius + (i.isEven ? waveDepth : -waveDepth);
      double x = center.dx + r * cos(angle);
      double y = center.dy + r * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

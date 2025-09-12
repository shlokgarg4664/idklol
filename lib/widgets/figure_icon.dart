import 'package:flutter/material.dart';

class FigureIcon extends StatelessWidget {
  const FigureIcon({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF1565C0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FigurePainter(color),
      ),
    );
  }
}

class _FigurePainter extends CustomPainter {
  _FigurePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerX = size.width / 2;
    final headRadius = size.shortestSide * 0.18;

    canvas.drawCircle(Offset(centerX, size.height * 0.2), headRadius, paint);

    final neck = Offset(centerX, size.height * 0.28 + headRadius);
    final hip = Offset(centerX, size.height * 0.62);
    canvas.drawLine(neck, hip, paint);

    final leftShoulder = Offset(centerX - size.width * 0.18, size.height * 0.42);
    final rightShoulder = Offset(centerX + size.width * 0.18, size.height * 0.42);
    canvas.drawLine(Offset(centerX, size.height * 0.42), leftShoulder, paint);
    canvas.drawLine(Offset(centerX, size.height * 0.42), rightShoulder, paint);

    final leftFoot = Offset(centerX - size.width * 0.18, size.height * 0.92);
    final rightFoot = Offset(centerX + size.width * 0.18, size.height * 0.92);
    canvas.drawLine(hip, leftFoot, paint);
    canvas.drawLine(hip, rightFoot, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

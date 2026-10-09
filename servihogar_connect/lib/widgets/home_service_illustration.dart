import 'package:flutter/material.dart';

class HomeServiceIllustration extends StatelessWidget {
  final double size;

  const HomeServiceIllustration({
    super.key,
    this.size = 112,
  });

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _HomeServicePainter(),
        ),
      ),
    );
  }
}

class _HomeServicePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 112;
    canvas.save();
    canvas.scale(scale);

    final glowPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x557DD3FC), Color(0x007DD3FC)],
      ).createShader(Rect.fromCircle(center: Offset(58, 55), radius: 53));
    canvas.drawCircle(const Offset(58, 55), 53, glowPaint);

    final houseFill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFDBEAFE), Color(0xFFBFDBFE)],
      ).createShader(const Rect.fromLTWH(27, 39, 59, 52));
    final house = Path()
      ..moveTo(31, 49)
      ..lineTo(56, 29)
      ..lineTo(82, 49)
      ..lineTo(82, 85)
      ..quadraticBezierTo(82, 89, 78, 89)
      ..lineTo(35, 89)
      ..quadraticBezierTo(31, 89, 31, 85)
      ..close();
    canvas.drawShadow(house, const Color(0x660A0A16), 7, true);
    canvas.drawPath(house, houseFill);

    final roof = Path()
      ..moveTo(22, 50)
      ..lineTo(56, 23)
      ..lineTo(90, 50);
    canvas.drawPath(
      roof,
      Paint()
        ..color = const Color(0xFFF8FAFC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final windowPaint = Paint()..color = const Color(0xFF7C3AED);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(39, 53, 12, 12),
        const Radius.circular(3),
      ),
      windowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(62, 53, 12, 12),
        const Radius.circular(3),
      ),
      windowPaint,
    );
    final windowLine = Paint()
      ..color = const Color(0xFFDDE7FF)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(45, 54), const Offset(45, 64), windowLine);
    canvas.drawLine(const Offset(40, 59), const Offset(50, 59), windowLine);
    canvas.drawLine(const Offset(68, 54), const Offset(68, 64), windowLine);
    canvas.drawLine(const Offset(63, 59), const Offset(73, 59), windowLine);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(51, 69, 14, 20),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF4F46E5),
    );
    canvas.drawCircle(const Offset(61, 80), 1.2, Paint()..color = Colors.white);

    final toolShadow = Paint()
      ..color = const Color(0x55202040)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(70, 75), const Offset(89, 57), toolShadow);
    final toolHandle = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF22D3EE), Color(0xFF38BDF8)],
      ).createShader(const Rect.fromLTWH(67, 57, 26, 28))
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(68, 78), const Offset(87, 59), toolHandle);
    final wrench = Paint()
      ..color = const Color(0xFFE0F2FE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final wrenchHead = Path()
      ..moveTo(81, 54)
      ..quadraticBezierTo(84, 48, 91, 49)
      ..lineTo(87, 54)
      ..lineTo(91, 58)
      ..quadraticBezierTo(91, 65, 85, 67);
    canvas.drawPath(wrenchHead, wrench);

    final sparkle = Paint()..color = const Color(0xFFFFD166);
    canvas.drawCircle(const Offset(22, 34), 2.1, sparkle);
    canvas.drawCircle(const Offset(91, 32), 1.6, sparkle);
    canvas.drawCircle(const Offset(20, 73), 1.4, Paint()..color = Colors.white70);
    final sparklePath = Path()
      ..moveTo(93, 77)
      ..lineTo(95, 82)
      ..lineTo(100, 84)
      ..lineTo(95, 86)
      ..lineTo(93, 91)
      ..lineTo(91, 86)
      ..lineTo(86, 84)
      ..lineTo(91, 82)
      ..close();
    canvas.drawPath(sparklePath, sparkle);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeServicePainter oldDelegate) => false;
}

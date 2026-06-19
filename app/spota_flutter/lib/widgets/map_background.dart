import 'package:flutter/material.dart';

class MapBackground extends StatelessWidget {
  const MapBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MapPainter(), child: const SizedBox.expand());
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base — Google Maps light green-grey
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = const Color(0xFFE8EAE0),
    );

    // Block fills (buildings / city blocks)
    _blocks(canvas, w, h);

    // Roads — major (white, thick)
    _roads(canvas, w, h);

    // Water — Mediterranean coast at bottom
    _water(canvas, w, h);

    // Park — small green patch
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * .33, h * .53, w * .09, h * .08), const Radius.circular(5)),
      Paint()..color = const Color(0xFFC5D9AA),
    );

    // Parking markers
    _marker(canvas, Offset(w * .20, h * .32), const Color(0xFF16A34A));   // available
    _marker(canvas, Offset(w * .62, h * .42), const Color(0xFF16A34A));   // available
    _marker(canvas, Offset(w * .43, h * .19), const Color(0xFFD97706));   // limited
    _marker(canvas, Offset(w * .76, h * .28), const Color(0xFFDC2626));   // full
    _marker(canvas, Offset(w * .11, h * .55), const Color(0xFF6B7280));   // closed
  }

  void _blocks(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFFD9DCD0);
    for (final r in [
      Rect.fromLTWH(w * .04, h * .06, w * .14, h * .10),
      Rect.fromLTWH(w * .22, h * .08, w * .07, h * .08),
      Rect.fromLTWH(w * .34, h * .12, w * .18, h * .07),
      Rect.fromLTWH(w * .57, h * .07, w * .13, h * .11),
      Rect.fromLTWH(w * .74, h * .05, w * .20, h * .09),
      Rect.fromLTWH(w * .04, h * .35, w * .16, h * .09),
      Rect.fromLTWH(w * .24, h * .33, w * .07, h * .07),
      Rect.fromLTWH(w * .56, h * .30, w * .20, h * .09),
      Rect.fromLTWH(w * .80, h * .32, w * .14, h * .08),
      Rect.fromLTWH(w * .08, h * .57, w * .18, h * .11),
      Rect.fromLTWH(w * .43, h * .55, w * .28, h * .08),
      Rect.fromLTWH(w * .77, h * .54, w * .18, h * .10),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), paint);
    }
  }

  void _roads(Canvas canvas, double w, double h) {
    // Major roads
    final major = Paint()..color = Colors.white..strokeWidth = 12..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(0, h * .25), Offset(w, h * .25), major);
    canvas.drawLine(Offset(0, h * .49), Offset(w, h * .49), major);
    canvas.drawLine(Offset(w * .29, 0), Offset(w * .29, h), major);
    canvas.drawLine(Offset(w * .70, 0), Offset(w * .70, h), major);

    // Minor roads
    final minor = Paint()..color = const Color(0xFFF5F5F5)..strokeWidth = 6..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(0,        h * .38), Offset(w,        h * .38), minor);
    canvas.drawLine(Offset(0,        h * .62), Offset(w,        h * .62), minor);
    canvas.drawLine(Offset(w * .14,  0),       Offset(w * .14,  h),       minor);
    canvas.drawLine(Offset(w * .47,  0),       Offset(w * .47,  h),       minor);
    canvas.drawLine(Offset(w * .85,  0),       Offset(w * .85,  h),       minor);

    // Diagonal — like a coastline road
    final diagonal = Paint()..color = Colors.white..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, h * .68), Offset(w * .55, h * .72), diagonal);
  }

  void _water(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(0, h * .75)
      ..cubicTo(w * .15, h * .72, w * .35, h * .80, w * .55, h * .76)
      ..cubicTo(w * .72, h * .72, w * .88, h * .78, w, h * .74)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFB8D4F0));

    // Subtle wave lines on the water
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 3; i++) {
      final yOff = h * (.80 + i * .05);
      final p = Path()
        ..moveTo(w * .05, yOff)
        ..cubicTo(w * .20, yOff - h * .01, w * .35, yOff + h * .01, w * .50, yOff)
        ..cubicTo(w * .65, yOff - h * .01, w * .80, yOff + h * .01, w * .95, yOff);
      canvas.drawPath(p, wave);
    }
  }

  void _marker(Canvas canvas, Offset c, Color color) {
    // Drop shadow
    canvas.drawCircle(c + const Offset(0, 2), 15,
        Paint()..color = Colors.black.withValues(alpha: 0.14)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    // White ring
    canvas.drawCircle(c, 15, Paint()..color = Colors.white);
    // Colored fill
    canvas.drawCircle(c, 12, Paint()..color = color);
    // "P" letter
    final tp = TextPainter(
      text: const TextSpan(
        text: 'P',
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, height: 1),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

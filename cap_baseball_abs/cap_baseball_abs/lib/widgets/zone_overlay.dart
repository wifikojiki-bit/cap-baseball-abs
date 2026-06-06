import 'package:flutter/material.dart';
import '../models/strike_zone.dart';

class ZoneOverlay extends StatelessWidget {
  final StrikeZone zone;
  const ZoneOverlay({super.key, required this.zone});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ZonePainter(zone: zone),
    );
  }
}

class _ZonePainter extends CustomPainter {
  final StrikeZone zone;

  _ZonePainter({required this.zone});

  @override
  void paint(Canvas canvas, Size size) {
    final tl = _toPixel(zone.topLeft, size);
    final tr = _toPixel(zone.topRight, size);
    final bl = _toPixel(zone.bottomLeft, size);
    final br = _toPixel(zone.bottomRight, size);

    final path = Path()
      ..moveTo(tl.dx, tl.dy)
      ..lineTo(tr.dx, tr.dy)
      ..lineTo(br.dx, br.dy)
      ..lineTo(bl.dx, bl.dy)
      ..close();

    // 半透明塗りつぶし
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00FF88).withOpacity(0.06)
        ..style = PaintingStyle.fill,
    );

    // 枠線（実線）
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF00FF88).withOpacity(0.7)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
    );

    // コーナードット
    for (final corner in [tl, tr, bl, br]) {
      canvas.drawCircle(
        corner,
        5,
        Paint()
          ..color = const Color(0xFF00FF88)
          ..style = PaintingStyle.fill,
      );
    }

    // ゾーン中心の十字線（小さく）
    final center = _toPixel(zone.center, size);
    final crossPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.4)
      ..strokeWidth = 1;
    canvas.drawLine(
        center.translate(-8, 0), center.translate(8, 0), crossPaint);
    canvas.drawLine(
        center.translate(0, -8), center.translate(0, 8), crossPaint);
  }

  Offset _toPixel(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  @override
  bool shouldRepaint(_ZonePainter oldDelegate) =>
      oldDelegate.zone != zone;
}

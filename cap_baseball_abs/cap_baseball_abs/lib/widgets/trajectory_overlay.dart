import 'package:flutter/material.dart';
import '../models/tracked_object.dart';

class TrajectoryOverlay extends StatelessWidget {
  final List<TrackedObject> trajectory;
  final TrackedObject? currentDetection;
  final bool isTracking;

  const TrajectoryOverlay({
    super.key,
    required this.trajectory,
    required this.currentDetection,
    required this.isTracking,
  });

  @override
  Widget build(BuildContext context) {
    if (trajectory.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      painter: _TrajectoryPainter(
        trajectory: trajectory,
        currentDetection: currentDetection,
        isTracking: isTracking,
      ),
    );
  }
}

class _TrajectoryPainter extends CustomPainter {
  final List<TrackedObject> trajectory;
  final TrackedObject? currentDetection;
  final bool isTracking;

  _TrajectoryPainter({
    required this.trajectory,
    required this.currentDetection,
    required this.isTracking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trajectory.isEmpty) return;

    // 軌道線の描画（グラデーション風: 古いほど薄く）
    final trailPaint = Paint()
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final count = trajectory.length;
    for (int i = 1; i < count; i++) {
      final progress = i / count; // 0 → 1 (古い → 新しい)
      final opacity = (progress * 0.8).clamp(0.05, 0.8);

      trailPaint.color = isTracking
          ? Color.fromRGBO(255, 165, 0, opacity)    // 追跡中: オレンジ
          : Color.fromRGBO(0, 255, 136, opacity);   // 判定後: 緑

      final p1 = _toPixel(trajectory[i - 1].position, size);
      final p2 = _toPixel(trajectory[i].position, size);
      canvas.drawLine(p1, p2, trailPaint);
    }

    // 現在検出位置のハイライト
    if (currentDetection != null) {
      final pos = _toPixel(currentDetection!.position, size);
      final radius = (currentDetection!.radius * (size.width + size.height) / 2)
          .clamp(8.0, 30.0);

      // 外枠
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = Colors.orange.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      // 中心点
      canvas.drawCircle(
        pos,
        3,
        Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill,
      );
    }

    // 軌道の先端に最新点を強調
    final latest = trajectory.last;
    final latestPos = _toPixel(latest.position, size);
    canvas.drawCircle(
      latestPos,
      5,
      Paint()
        ..color = isTracking ? Colors.orange : const Color(0xFF00FF88)
        ..style = PaintingStyle.fill,
    );
  }

  Offset _toPixel(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  @override
  bool shouldRepaint(_TrajectoryPainter oldDelegate) => true;
}

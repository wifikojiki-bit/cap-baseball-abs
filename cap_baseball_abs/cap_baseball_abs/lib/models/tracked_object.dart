import 'package:flutter/material.dart';

/// 追跡されたキャップの1フレーム情報
class TrackedObject {
  final Offset position;   // 正規化座標 (0.0〜1.0)
  final double radius;     // 正規化半径
  final double confidence; // 検出信頼度 (0.0〜1.0)
  final int frameIndex;
  final DateTime timestamp;

  const TrackedObject({
    required this.position,
    required this.radius,
    required this.confidence,
    required this.frameIndex,
    required this.timestamp,
  });

  /// ピクセル座標から正規化座標に変換
  factory TrackedObject.fromPixels({
    required Offset pixelPosition,
    required double pixelRadius,
    required Size frameSize,
    required double confidence,
    required int frameIndex,
  }) {
    return TrackedObject(
      position: Offset(
        pixelPosition.dx / frameSize.width,
        pixelPosition.dy / frameSize.height,
      ),
      radius: pixelRadius / ((frameSize.width + frameSize.height) / 2),
      confidence: confidence,
      frameIndex: frameIndex,
      timestamp: DateTime.now(),
    );
  }

  /// フレーム間の速度計算（正規化座標/秒）
  static double velocity(TrackedObject prev, TrackedObject curr) {
    final dx = curr.position.dx - prev.position.dx;
    final dy = curr.position.dy - prev.position.dy;
    final dt = curr.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0) return 0;
    return (dx * dx + dy * dy) / (dt * dt);
  }

  /// 2点間の距離（正規化）
  double distanceTo(TrackedObject other) {
    final dx = position.dx - other.position.dx;
    final dy = position.dy - other.position.dy;
    return (dx * dx + dy * dy);
  }
}

/// キャップ追跡の状態
enum TrackingState {
  idle,        // 待機中
  detecting,   // 検出中
  tracking,    // 追跡中（投球開始）
  judging,     // 判定処理中
  showing,     // 結果表示中
}

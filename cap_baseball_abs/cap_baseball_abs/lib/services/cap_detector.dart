import 'dart:math';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import '../models/tracked_object.dart';

/// キャップ検出設定
class DetectionConfig {
  /// キャップの色範囲（HSV）- デフォルト: 赤〜白の広範囲
  final int hueMin;
  final int hueMax;
  final int satMin;
  final int valMin;

  /// サイズフィルタ（正規化）
  final double minRadiusNorm;
  final double maxRadiusNorm;

  /// 動体検出の感度
  final double motionThreshold;

  const DetectionConfig({
    this.hueMin = 0,
    this.hueMax = 360,
    this.satMin = 0,
    this.valMin = 100,
    this.minRadiusNorm = 0.010, // キャップ約4cm, 3mで約1.3%
    this.maxRadiusNorm = 0.080, // 近距離最大
    this.motionThreshold = 0.002, // 正規化速度閾値
  });
}

/// キャップ検出エンジン
/// Priority: 1.色認識 → 2.円形検出 → 3.動体追跡
class CapDetector {
  final DetectionConfig config;

  img.Image? _prevFrame;
  int _frameCount = 0;

  CapDetector({this.config = const DetectionConfig()});

  /// カメラフレームからキャップを検出
  /// Returns: 検出されたオブジェクトのリスト（信頼度順）
  List<TrackedObject> detect(CameraImage cameraImage) {
    _frameCount++;
    final frame = _convertToImage(cameraImage);
    if (frame == null) return [];

    final candidates = <TrackedObject>[];

    // Step1: 色ベース検出
    final colorCandidates = _detectByColor(frame);
    candidates.addAll(colorCandidates);

    // Step2: 動体検出で補完
    if (_prevFrame != null) {
      final motionCandidates = _detectByMotion(frame, _prevFrame!);
      // 色検出と重複しないものを追加
      for (final mc in motionCandidates) {
        bool isDuplicate = false;
        for (final cc in colorCandidates) {
          if (cc.distanceTo(mc) < 0.005) {
            isDuplicate = true;
            break;
          }
        }
        if (!isDuplicate) {
          candidates.add(mc.copyWithConfidence(mc.confidence * 0.7));
        }
      }
    }

    _prevFrame = frame;

    // 信頼度でソートして返す
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));
    return candidates.take(3).toList();
  }

  /// YUV420 → RGB変換
  img.Image? _convertToImage(CameraImage cameraImage) {
    try {
      // YUV420SP形式の処理
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(cameraImage);
      }
      // BGRA8888形式の処理（iOS）
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(cameraImage);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  img.Image _convertYUV420(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    // パフォーマンスのため1/4解像度で処理
    final scaledW = width ~/ 4;
    final scaledH = height ~/ 4;
    final result = img.Image(width: scaledW, height: scaledH);

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    for (int j = 0; j < scaledH; j++) {
      for (int i = 0; i < scaledW; i++) {
        final srcX = i * 4;
        final srcY = j * 4;

        final yIndex = srcY * yPlane.bytesPerRow + srcX;
        final uvIndex = (srcY ~/ 2) * uPlane.bytesPerRow + (srcX ~/ 2);

        if (yIndex >= yPlane.bytes.length || uvIndex >= uPlane.bytes.length) {
          continue;
        }

        final y = yPlane.bytes[yIndex];
        final u = uPlane.bytes[uvIndex] - 128;
        final v = vPlane.bytes[uvIndex] - 128;

        final r = (y + 1.370705 * v).clamp(0, 255).toInt();
        final g = (y - 0.337633 * u - 0.698001 * v).clamp(0, 255).toInt();
        final b = (y + 1.732446 * u).clamp(0, 255).toInt();

        result.setPixelRgb(i, j, r, g, b);
      }
    }
    return result;
  }

  img.Image _convertBGRA8888(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final scaledW = width ~/ 4;
    final scaledH = height ~/ 4;
    final result = img.Image(width: scaledW, height: scaledH);
    final bytes = cameraImage.planes[0].bytes;

    for (int j = 0; j < scaledH; j++) {
      for (int i = 0; i < scaledW; i++) {
        final srcX = i * 4;
        final srcY = j * 4;
        final idx = (srcY * width + srcX) * 4;
        if (idx + 3 >= bytes.length) continue;
        result.setPixelRgb(i, j, bytes[idx + 2], bytes[idx + 1], bytes[idx]);
      }
    }
    return result;
  }

  /// 色認識によるキャップ検出
  List<TrackedObject> _detectByColor(img.Image frame) {
    final w = frame.width;
    final h = frame.height;
    final detected = <TrackedObject>[];

    // ピクセルごとに白/明るい色を検出（キャップは多くの場合白や原色）
    // 複数の色領域を探索
    final colorMasks = [
      _findColorRegions(frame, _isWhiteOrLight),  // 白・薄色
      _findColorRegions(frame, _isRedCap),        // 赤系
      _findColorRegions(frame, _isYellowCap),     // 黄系
    ];

    for (final mask in colorMasks) {
      final blobs = _findBlobs(mask, w, h);
      for (final blob in blobs) {
        final normRadius = blob.radius / ((w + h) / 2.0);
        if (normRadius < config.minRadiusNorm || normRadius > config.maxRadiusNorm) {
          continue;
        }

        // 円形度チェック
        final circularity = _checkCircularity(blob);
        if (circularity < 0.4) continue;

        final normX = blob.center.dx / w;
        final normY = blob.center.dy / h;

        detected.add(TrackedObject(
          position: Offset(normX, normY),
          radius: normRadius,
          confidence: circularity * blob.pixelCount / 100.0,
          frameIndex: _frameCount,
          timestamp: DateTime.now(),
        ));
      }
    }

    return detected;
  }

  /// 動体検出
  List<TrackedObject> _detectByMotion(img.Image curr, img.Image prev) {
    final w = curr.width;
    final h = curr.height;
    final detected = <TrackedObject>[];

    // フレーム差分
    final diff = img.Image(width: w, height: h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final cp = curr.getPixel(x, y);
        final pp = prev.getPixel(x, y);

        final dr = (cp.r - pp.r).abs();
        final dg = (cp.g - pp.g).abs();
        final db = (cp.b - pp.b).abs();
        final motion = (dr + dg + db) / 3;

        if (motion > 30) {
          diff.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }

    // ブロブ検出
    final blobs = _findBlobs(diff, w, h);
    for (final blob in blobs) {
      final normRadius = blob.radius / ((w + h) / 2.0);
      if (normRadius < config.minRadiusNorm || normRadius > config.maxRadiusNorm) {
        continue;
      }

      detected.add(TrackedObject(
        position: Offset(blob.center.dx / w, blob.center.dy / h),
        radius: normRadius,
        confidence: 0.5,
        frameIndex: _frameCount,
        timestamp: DateTime.now(),
      ));
    }

    return detected;
  }

  // ---- 色判定ヘルパー ----

  bool _isWhiteOrLight(img.Pixel p) {
    return p.r > 200 && p.g > 200 && p.b > 200;
  }

  bool _isRedCap(img.Pixel p) {
    return p.r > 150 && p.g < 80 && p.b < 80;
  }

  bool _isYellowCap(img.Pixel p) {
    return p.r > 180 && p.g > 160 && p.b < 80;
  }

  img.Image _findColorRegions(img.Image frame, bool Function(img.Pixel) colorTest) {
    final result = img.Image(width: frame.width, height: frame.height);
    for (int y = 0; y < frame.height; y++) {
      for (int x = 0; x < frame.width; x++) {
        final p = frame.getPixel(x, y);
        if (colorTest(p)) {
          result.setPixelRgb(x, y, 255, 255, 255);
        }
      }
    }
    return result;
  }

  // ---- ブロブ検出 ----

  List<_Blob> _findBlobs(img.Image mask, int w, int h) {
    final visited = List.generate(h, (_) => List.filled(w, false));
    final blobs = <_Blob>[];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (visited[y][x]) continue;
        final p = mask.getPixel(x, y);
        if (p.r < 128) continue;

        // BFSでブロブを拡大
        final blobPixels = <Offset>[];
        final queue = <Point<int>>[Point(x, y)];
        visited[y][x] = true;

        while (queue.isNotEmpty) {
          final curr = queue.removeLast();
          blobPixels.add(Offset(curr.x.toDouble(), curr.y.toDouble()));

          for (final neighbor in [
            Point(curr.x - 1, curr.y),
            Point(curr.x + 1, curr.y),
            Point(curr.x, curr.y - 1),
            Point(curr.x, curr.y + 1),
          ]) {
            if (neighbor.x < 0 || neighbor.x >= w ||
                neighbor.y < 0 || neighbor.y >= h) continue;
            if (visited[neighbor.y][neighbor.x]) continue;
            final np = mask.getPixel(neighbor.x, neighbor.y);
            if (np.r < 128) continue;
            visited[neighbor.y][neighbor.x] = true;
            queue.add(neighbor);
          }
        }

        if (blobPixels.length >= 5) {
          blobs.add(_Blob.fromPixels(blobPixels));
        }
      }
    }
    return blobs;
  }

  double _checkCircularity(_Blob blob) {
    if (blob.pixelCount == 0) return 0;
    // 円形度 = 4π * 面積 / 周長^2
    final expectedArea = pi * blob.radius * blob.radius;
    return (blob.pixelCount / expectedArea).clamp(0.0, 1.0);
  }

  void reset() {
    _prevFrame = null;
    _frameCount = 0;
  }
}

class _Blob {
  final Offset center;
  final double radius;
  final int pixelCount;

  const _Blob({required this.center, required this.radius, required this.pixelCount});

  factory _Blob.fromPixels(List<Offset> pixels) {
    double sumX = 0, sumY = 0;
    for (final p in pixels) {
      sumX += p.dx;
      sumY += p.dy;
    }
    final cx = sumX / pixels.length;
    final cy = sumY / pixels.length;

    double maxDist = 0;
    for (final p in pixels) {
      final dx = p.dx - cx;
      final dy = p.dy - cy;
      final d = sqrt(dx * dx + dy * dy);
      if (d > maxDist) maxDist = d;
    }

    return _Blob(
      center: Offset(cx, cy),
      radius: maxDist,
      pixelCount: pixels.length,
    );
  }
}

extension _TrackedObjectExtension on TrackedObject {
  TrackedObject copyWithConfidence(double newConfidence) {
    return TrackedObject(
      position: position,
      radius: radius,
      confidence: newConfidence,
      frameIndex: frameIndex,
      timestamp: timestamp,
    );
  }
}

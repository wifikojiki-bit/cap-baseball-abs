import 'dart:math';
import 'package:flutter/material.dart';

/// ストライクゾーンの四隅座標（正規化座標 0.0〜1.0）
class StrikeZone {
  final Offset topLeft;
  final Offset topRight;
  final Offset bottomLeft;
  final Offset bottomRight;

  const StrikeZone({
    required this.topLeft,
    required this.topRight,
    required this.bottomLeft,
    required this.bottomRight,
  });

  /// デフォルトゾーン（画面中央）
  factory StrikeZone.defaultZone() {
    return const StrikeZone(
      topLeft: Offset(0.35, 0.25),
      topRight: Offset(0.65, 0.25),
      bottomLeft: Offset(0.35, 0.75),
      bottomRight: Offset(0.65, 0.75),
    );
  }

  /// JSONから復元
  factory StrikeZone.fromJson(Map<String, dynamic> json) {
    return StrikeZone(
      topLeft: Offset(json['tlx'] as double, json['tly'] as double),
      topRight: Offset(json['trx'] as double, json['try'] as double),
      bottomLeft: Offset(json['blx'] as double, json['bly'] as double),
      bottomRight: Offset(json['brx'] as double, json['bry'] as double),
    );
  }

  /// JSONに変換
  Map<String, dynamic> toJson() {
    return {
      'tlx': topLeft.dx, 'tly': topLeft.dy,
      'trx': topRight.dx, 'try': topRight.dy,
      'blx': bottomLeft.dx, 'bly': bottomLeft.dy,
      'brx': bottomRight.dx, 'bry': bottomRight.dy,
    };
  }

  /// 正規化座標がゾーン内にあるか判定（平行四辺形対応）
  bool contains(Offset point) {
    return _isInsideQuadrilateral(point, topLeft, topRight, bottomRight, bottomLeft);
  }

  /// 四角形内部判定（クロス積を使用）
  bool _isInsideQuadrilateral(
      Offset p, Offset a, Offset b, Offset c, Offset d) {
    return _cross(a, b, p) >= 0 &&
        _cross(b, c, p) >= 0 &&
        _cross(c, d, p) >= 0 &&
        _cross(d, a, p) >= 0;
  }

  double _cross(Offset o, Offset a, Offset b) {
    return (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
  }

  /// バウンディングボックス（表示用）
  Rect get boundingBox {
    final xs = [topLeft.dx, topRight.dx, bottomLeft.dx, bottomRight.dx];
    final ys = [topLeft.dy, topRight.dy, bottomLeft.dy, bottomRight.dy];
    return Rect.fromLTRB(
      xs.reduce(min), ys.reduce(min),
      xs.reduce(max), ys.reduce(max),
    );
  }

  /// ゾーンの中心点
  Offset get center {
    return Offset(
      (topLeft.dx + topRight.dx + bottomLeft.dx + bottomRight.dx) / 4,
      (topLeft.dy + topRight.dy + bottomLeft.dy + bottomRight.dy) / 4,
    );
  }

  StrikeZone copyWith({
    Offset? topLeft,
    Offset? topRight,
    Offset? bottomLeft,
    Offset? bottomRight,
  }) {
    return StrikeZone(
      topLeft: topLeft ?? this.topLeft,
      topRight: topRight ?? this.topRight,
      bottomLeft: bottomLeft ?? this.bottomLeft,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }
}

/// ゾーン設定のコーナー種別
enum ZoneCorner { topLeft, topRight, bottomLeft, bottomRight, none }

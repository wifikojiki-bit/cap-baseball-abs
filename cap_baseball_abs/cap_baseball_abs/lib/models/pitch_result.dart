import 'package:flutter/material.dart';

enum PitchJudgment { strike, ball, none }

/// 1投球の判定結果
class PitchResult {
  final PitchJudgment judgment;
  final List<Offset> trajectory; // 正規化座標の軌道
  final DateTime timestamp;
  final int inning;
  final int balls;
  final int strikes;

  const PitchResult({
    required this.judgment,
    required this.trajectory,
    required this.timestamp,
    required this.inning,
    required this.balls,
    required this.strikes,
  });

  bool get isStrike => judgment == PitchJudgment.strike;
  bool get isBall => judgment == PitchJudgment.ball;

  String get judgmentText {
    switch (judgment) {
      case PitchJudgment.strike:
        return 'STRIKE';
      case PitchJudgment.ball:
        return 'BALL';
      case PitchJudgment.none:
        return '';
    }
  }

  String get judgmentJapanese {
    switch (judgment) {
      case PitchJudgment.strike:
        return 'ストライク';
      case PitchJudgment.ball:
        return 'ボール';
      case PitchJudgment.none:
        return '';
    }
  }

  Color get judgmentColor {
    switch (judgment) {
      case PitchJudgment.strike:
        return const Color(0xFF00FF88);
      case PitchJudgment.ball:
        return const Color(0xFFFF4444);
      case PitchJudgment.none:
        return Colors.white;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'judgment': judgment.name,
      'trajectory': trajectory.map((o) => {'x': o.dx, 'y': o.dy}).toList(),
      'timestamp': timestamp.toIso8601String(),
      'inning': inning,
      'balls': balls,
      'strikes': strikes,
    };
  }

  factory PitchResult.fromJson(Map<String, dynamic> json) {
    return PitchResult(
      judgment: PitchJudgment.values.firstWhere(
          (e) => e.name == json['judgment'],
          orElse: () => PitchJudgment.none),
      trajectory: (json['trajectory'] as List)
          .map((p) => Offset(p['x'] as double, p['y'] as double))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      inning: json['inning'] as int,
      balls: json['balls'] as int,
      strikes: json['strikes'] as int,
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/tracked_object.dart';
import '../models/pitch_result.dart';
import '../models/strike_zone.dart';
import 'cap_detector.dart';

/// ABSメインサービス
/// カメラフレームの処理・追跡・判定を管理
class ABSService extends ChangeNotifier {
  final CapDetector _detector = CapDetector();
  final FlutterTts _tts = FlutterTts();

  // 追跡状態
  TrackingState _state = TrackingState.idle;
  final List<TrackedObject> _trajectory = [];
  TrackedObject? _currentDetection;

  // 判定結果
  PitchResult? _lastResult;
  Timer? _resultTimer;

  // 投球検知パラメータ
  static const int _minTrackingFrames = 5;    // 投球開始に必要なフレーム数
  static const int _pitchEndFrames = 10;      // 消失後、投球終了とみなすフレーム数
  static const double _minVelocity = 0.0003;  // 最低速度閾値（正規化）
  static const Duration _resultDisplayDuration = Duration(seconds: 3);

  int _noDetectionFrames = 0;
  bool _pitchInProgress = false;

  // Getters
  TrackingState get state => _state;
  List<TrackedObject> get trajectory => List.unmodifiable(_trajectory);
  TrackedObject? get currentDetection => _currentDetection;
  PitchResult? get lastResult => _lastResult;
  bool get isTracking => _state == TrackingState.tracking;
  bool get isShowingResult => _state == TrackingState.showing;

  ABSService() {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('ja-JP');
    await _tts.setSpeechRate(0.8);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// カメラフレームを処理
  void processFrame(CameraImage frame, StrikeZone strikeZone) {
    if (_state == TrackingState.showing) return; // 結果表示中は処理しない

    // キャップ検出
    final detections = _detector.detect(frame);

    if (detections.isEmpty) {
      _handleNoDetection(strikeZone);
      return;
    }

    _noDetectionFrames = 0;
    final best = detections.first;
    _currentDetection = best;

    _trajectory.add(best);
    if (_trajectory.length > 60) _trajectory.removeAt(0);

    // 状態遷移
    switch (_state) {
      case TrackingState.idle:
      case TrackingState.detecting:
        _state = TrackingState.detecting;
        if (_trajectory.length >= 3) {
          final velocity = _calcRecentVelocity();
          if (velocity > _minVelocity) {
            _startTracking();
          }
        }
        break;

      case TrackingState.tracking:
        // 軌道蓄積中
        _pitchInProgress = true;
        break;

      default:
        break;
    }

    notifyListeners();
  }

  void _handleNoDetection(StrikeZone strikeZone) {
    _currentDetection = null;
    _noDetectionFrames++;

    if (_state == TrackingState.tracking && _pitchInProgress) {
      if (_noDetectionFrames >= _pitchEndFrames) {
        _judgeAndFinish(strikeZone);
      }
    } else if (_state == TrackingState.detecting) {
      if (_noDetectionFrames > 5) {
        _clearTrajectory();
        _state = TrackingState.idle;
        notifyListeners();
      }
    }
  }

  void _startTracking() {
    _state = TrackingState.tracking;
    _pitchInProgress = false;
    notifyListeners();
  }

  void _judgeAndFinish(StrikeZone strikeZone) {
    if (_trajectory.length < _minTrackingFrames) {
      _resetTracking();
      return;
    }

    _state = TrackingState.judging;

    // 判定：ゾーン通過チェック
    final judgment = _determineJudgment(strikeZone);

    _lastResult = PitchResult(
      judgment: judgment,
      trajectory: _trajectory.map((t) => t.position).toList(),
      timestamp: DateTime.now(),
      inning: 1,
      balls: 0,
      strikes: 0,
    );

    _announceResult(judgment);
    _state = TrackingState.showing;
    notifyListeners();

    // 3秒後にリセット
    _resultTimer?.cancel();
    _resultTimer = Timer(_resultDisplayDuration, () {
      _clearAfterResult();
    });
  }

  PitchJudgment _determineJudgment(StrikeZone zone) {
    // 軌道のうち、ストライクゾーン中央付近（水平方向50-75%）で判定
    final relevantPoints = _getRelevantTrajectoryPoints();

    for (final point in relevantPoints) {
      if (zone.contains(point)) {
        return PitchJudgment.strike;
      }
    }
    return PitchJudgment.ball;
  }

  /// 軌道から判定に使う部分を抽出（キャッチャー方向への到達点付近）
  List<Offset> _getRelevantTrajectoryPoints() {
    if (_trajectory.isEmpty) return [];

    // 軌道の後半部分（キャッチャー付近）を優先
    final startIdx = (_trajectory.length * 0.4).toInt();
    return _trajectory
        .sublist(startIdx)
        .map((t) => t.position)
        .toList();
  }

  double _calcRecentVelocity() {
    if (_trajectory.length < 2) return 0;
    final recent = _trajectory.length > 5
        ? _trajectory.sublist(_trajectory.length - 5)
        : _trajectory;

    double totalVelocity = 0;
    for (int i = 1; i < recent.length; i++) {
      totalVelocity += TrackedObject.velocity(recent[i - 1], recent[i]);
    }
    return totalVelocity / (recent.length - 1);
  }

  Future<void> _announceResult(PitchJudgment judgment) async {
    final text = judgment == PitchJudgment.strike ? 'ストライク' : 'ボール';
    await _tts.speak(text);
  }

  void _clearTrajectory() {
    _trajectory.clear();
    _pitchInProgress = false;
    _noDetectionFrames = 0;
  }

  void _clearAfterResult() {
    _clearTrajectory();
    _state = TrackingState.idle;
    notifyListeners();
  }

  void _resetTracking() {
    _clearTrajectory();
    _state = TrackingState.idle;
    _pitchInProgress = false;
    notifyListeners();
  }

  /// 手動リセット
  void resetDetection() {
    _resultTimer?.cancel();
    _lastResult = null;
    _resetTracking();
    _detector.reset();
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    _tts.stop();
    super.dispose();
  }
}

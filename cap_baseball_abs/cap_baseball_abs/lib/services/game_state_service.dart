import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pitch_result.dart';
import '../models/strike_zone.dart';

class GameStateService extends ChangeNotifier {
  // BSOカウント
  int _balls = 0;
  int _strikes = 0;
  int _outs = 0;
  int _inning = 1;
  bool _isTopInning = true; // 表/裏

  // 判定履歴
  final List<PitchResult> _pitchHistory = [];

  // ストライクゾーン
  StrikeZone _strikeZone = StrikeZone.defaultZone();
  bool _zoneConfigured = false;

  // Getters
  int get balls => _balls;
  int get strikes => _strikes;
  int get outs => _outs;
  int get inning => _inning;
  bool get isTopInning => _isTopInning;
  List<PitchResult> get pitchHistory => List.unmodifiable(_pitchHistory);
  StrikeZone get strikeZone => _strikeZone;
  bool get zoneConfigured => _zoneConfigured;

  String get inningText => '$_inning回${_isTopInning ? "表" : "裏"}';

  GameStateService() {
    _loadFromPrefs();
  }

  /// ストライクゾーン設定
  void setStrikeZone(StrikeZone zone) {
    _strikeZone = zone;
    _zoneConfigured = true;
    _saveZoneToPrefs();
    notifyListeners();
  }

  /// 判定結果を適用してカウントを更新
  void applyPitchResult(PitchResult result) {
    _pitchHistory.insert(0, result);
    if (_pitchHistory.length > 100) _pitchHistory.removeLast();

    if (result.isStrike) {
      _strikes++;
      if (_strikes >= 3) {
        _addOut();
      }
    } else if (result.isBall) {
      _balls++;
      if (_balls >= 4) {
        // フォアボール
        _resetCount();
      }
    }

    _savePitchHistory();
    notifyListeners();
  }

  void _addOut() {
    _outs++;
    _resetCount();
    if (_outs >= 3) {
      _nextHalfInning();
    }
    notifyListeners();
  }

  void _resetCount() {
    _balls = 0;
    _strikes = 0;
    notifyListeners();
  }

  void _nextHalfInning() {
    _outs = 0;
    if (!_isTopInning) {
      _inning++;
    }
    _isTopInning = !_isTopInning;
    notifyListeners();
  }

  /// カウント手動リセット
  void resetCount() {
    _balls = 0;
    _strikes = 0;
    notifyListeners();
  }

  /// 全リセット（新しいゲーム）
  void resetGame() {
    _balls = 0;
    _strikes = 0;
    _outs = 0;
    _inning = 1;
    _isTopInning = true;
    _pitchHistory.clear();
    notifyListeners();
  }

  /// イニング手動切替
  void nextInning() {
    _nextHalfInning();
  }

  /// ストライク手動追加
  void addStrike() {
    _strikes = (_strikes + 1).clamp(0, 3);
    notifyListeners();
  }

  /// ボール手動追加
  void addBall() {
    _balls = (_balls + 1).clamp(0, 4);
    notifyListeners();
  }

  /// アウト手動追加
  void addOut() {
    _addOut();
  }

  // ---- 永続化 ----

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final zoneJson = prefs.getString('strike_zone');
    if (zoneJson != null) {
      try {
        _strikeZone = StrikeZone.fromJson(
            jsonDecode(zoneJson) as Map<String, dynamic>);
        _zoneConfigured = true;
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _saveZoneToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('strike_zone', jsonEncode(_strikeZone.toJson()));
  }

  Future<void> _savePitchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = jsonEncode(
        _pitchHistory.take(50).map((r) => r.toJson()).toList());
    await prefs.setString('pitch_history', historyJson);
  }

  Future<List<PitchResult>> loadSavedHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('pitch_history');
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => PitchResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}

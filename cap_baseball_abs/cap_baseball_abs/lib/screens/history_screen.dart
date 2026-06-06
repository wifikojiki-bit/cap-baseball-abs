import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/pitch_result.dart';
import '../services/game_state_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateService>();
    final history = gameState.pitchHistory;

    final strikes = history.where((r) => r.isStrike).length;
    final balls = history.where((r) => r.isBall).length;
    final total = history.length;
    final strikeRate = total > 0 ? (strikes / total * 100).toStringAsFixed(1) : '0.0';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '判定履歴',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // 統計サマリー
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(label: '投球数', value: '$total', color: Colors.white),
                _StatItem(label: 'ストライク', value: '$strikes', color: const Color(0xFF00FF88)),
                _StatItem(label: 'ボール', value: '$balls', color: const Color(0xFFFF4444)),
                _StatItem(label: 'S率', value: '$strikeRate%', color: Colors.amber),
              ],
            ),
          ),

          // 履歴リスト
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.sports_baseball, color: Colors.white24, size: 48),
                        SizedBox(height: 12),
                        Text('まだ判定がありません',
                            style: TextStyle(color: Colors.white38, fontSize: 16)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: history.length,
                    itemBuilder: (ctx, i) {
                      final result = history[i];
                      return _HistoryTile(result: result, index: i + 1);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final PitchResult result;
  final int index;

  const _HistoryTile({required this.result, required this.index});

  @override
  Widget build(BuildContext context) {
    final color = result.judgmentColor;
    final fmt = DateFormat('HH:mm:ss');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          // 番号
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              '$index',
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // 判定
          Text(
            result.judgmentText,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // カウント
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.inning}回 B${result.balls}-S${result.strikes}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Text(
                fmt.format(result.timestamp),
                style: const TextStyle(color: Colors.white30, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

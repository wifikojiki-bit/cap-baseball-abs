import 'package:flutter/material.dart';
import '../services/game_state_service.dart';

class BSOCounter extends StatelessWidget {
  final GameStateService gameState;

  const BSOCounter({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8, top: 60, bottom: 60),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CountRow(
            label: 'B',
            count: gameState.balls,
            max: 4,
            activeColor: const Color(0xFF4CAF50),
            onTap: () => gameState.addBall(),
          ),
          const SizedBox(height: 12),
          _CountRow(
            label: 'S',
            count: gameState.strikes,
            max: 3,
            activeColor: const Color(0xFFFF9800),
            onTap: () => gameState.addStrike(),
          ),
          const SizedBox(height: 12),
          _CountRow(
            label: 'O',
            count: gameState.outs,
            max: 3,
            activeColor: const Color(0xFFF44336),
            onTap: () => gameState.addOut(),
          ),
          const SizedBox(height: 16),
          // カウントリセットボタン
          GestureDetector(
            onTap: () => gameState.resetCount(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'RST',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color activeColor;
  final VoidCallback onTap;

  const _CountRow({
    required this.label,
    required this.count,
    required this.max,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: activeColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Column(
            children: List.generate(max, (i) {
              final isActive = i < count;
              return Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  border: Border.all(
                    color: isActive ? activeColor : Colors.white24,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

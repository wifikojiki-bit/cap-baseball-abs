import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_state_service.dart';
import 'game_screen.dart';
import 'zone_setup_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAP BASEBALL',
                        style: TextStyle(
                          color: const Color(0xFF00FF88),
                          fontSize: 13,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Text(
                        'ABS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                          letterSpacing: -2,
                        ),
                      ),
                    ],
                  ),
                  // ゾーン設定状態
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: gameState.zoneConfigured
                          ? const Color(0xFF00FF88).withOpacity(0.15)
                          : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: gameState.zoneConfigured
                            ? const Color(0xFF00FF88)
                            : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          gameState.zoneConfigured
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_outlined,
                          color: gameState.zoneConfigured
                              ? const Color(0xFF00FF88)
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          gameState.zoneConfigured ? 'ゾーン設定済' : 'ゾーン未設定',
                          style: TextStyle(
                            color: gameState.zoneConfigured
                                ? const Color(0xFF00FF88)
                                : Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // メインボタン
              Expanded(
                child: Column(
                  children: [
                    // 試合開始（最大ボタン）
                    _BigButton(
                      label: '試合開始',
                      sublabel: gameState.zoneConfigured ? '準備完了' : 'ゾーン設定が必要です',
                      icon: Icons.sports_baseball,
                      color: const Color(0xFF00FF88),
                      textColor: Colors.black,
                      enabled: gameState.zoneConfigured,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        // ゾーン設定
                        Expanded(
                          child: _MediumButton(
                            label: 'ゾーン設定',
                            icon: Icons.crop_free,
                            color: const Color(0xFF1A1A1A),
                            borderColor: const Color(0xFF333333),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ZoneSetupScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 判定履歴
                        Expanded(
                          child: _MediumButton(
                            label: '判定履歴',
                            icon: Icons.history,
                            color: const Color(0xFF1A1A1A),
                            borderColor: const Color(0xFF333333),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ゲームリセット
                    _MediumButton(
                      label: 'ゲームリセット',
                      icon: Icons.refresh,
                      color: const Color(0xFF1A1A1A),
                      borderColor: Colors.red.withOpacity(0.4),
                      textColor: Colors.red.shade300,
                      iconColor: Colors.red.shade300,
                      onTap: () => _showResetDialog(context, gameState),
                    ),
                  ],
                ),
              ),

              // バージョン
              Center(
                child: Text(
                  'v1.0.0 MVP',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, GameStateService gameState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('ゲームリセット',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('カウントと履歴をリセットしますか？',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              gameState.resetGame();
              Navigator.pop(ctx);
            },
            child: const Text('リセット',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  final Color color;
  final Color textColor;
  final bool enabled;
  final VoidCallback onTap;

  const _BigButton({
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: enabled ? color : Colors.grey.shade800,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 40),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediumButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback onTap;

  const _MediumButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 70,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: textColor ?? Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

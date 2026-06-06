import 'package:flutter/material.dart';
import '../models/pitch_result.dart';

class JudgmentDisplay extends StatefulWidget {
  final PitchResult result;

  const JudgmentDisplay({super.key, required this.result});

  @override
  State<JudgmentDisplay> createState() => _JudgmentDisplayState();
}

class _JudgmentDisplayState extends State<JudgmentDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isStrike = widget.result.isStrike;
    final color = widget.result.judgmentColor;
    final text = widget.result.judgmentText;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Container(
            color: Colors.black.withOpacity(0.45),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // メイン判定テキスト
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: color.withOpacity(0.8),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // 英語
                          Text(
                            text,
                            style: TextStyle(
                              color: color,
                              fontSize: 72,
                              fontWeight: FontWeight.w900,
                              letterSpacing: isStrike ? -2 : 2,
                              height: 1.0,
                              shadows: [
                                Shadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 日本語
                          Text(
                            widget.result.judgmentJapanese,
                            style: TextStyle(
                              color: color.withOpacity(0.8),
                              fontSize: 24,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // カウント情報（現在のカウント）
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CountBadge(
                              label: 'B',
                              count: widget.result.balls,
                              color: const Color(0xFF4CAF50)),
                          const SizedBox(width: 8),
                          _CountBadge(
                              label: 'S',
                              count: widget.result.strikes,
                              color: const Color(0xFFFF9800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountBadge(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(width: 4),
        Text('$count',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

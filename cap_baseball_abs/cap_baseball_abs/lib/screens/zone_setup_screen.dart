import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../models/strike_zone.dart';
import '../services/game_state_service.dart';

class ZoneSetupScreen extends StatefulWidget {
  const ZoneSetupScreen({super.key});

  @override
  State<ZoneSetupScreen> createState() => _ZoneSetupScreenState();
}

class _ZoneSetupScreenState extends State<ZoneSetupScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String _errorMessage = '';

  // タップ設定の進捗
  ZoneCorner _nextCorner = ZoneCorner.topLeft;
  Map<ZoneCorner, Offset> _corners = {};

  @override
  void initState() {
    super.initState();
    _initCamera();

    // 既存設定があればロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final zone = context.read<GameStateService>().strikeZone;
      if (context.read<GameStateService>().zoneConfigured) {
        setState(() {
          _corners = {
            ZoneCorner.topLeft: zone.topLeft,
            ZoneCorner.topRight: zone.topRight,
            ZoneCorner.bottomLeft: zone.bottomLeft,
            ZoneCorner.bottomRight: zone.bottomRight,
          };
          _nextCorner = ZoneCorner.none;
        });
      }
    });
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'カメラが見つかりません');
      return;
    }

    // 背面カメラを優先
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'カメラの初期化に失敗しました: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onTap(TapDownDetails details, BoxConstraints constraints) {
    if (_nextCorner == ZoneCorner.none) return;

    final norm = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    setState(() {
      _corners[_nextCorner] = norm;
      _nextCorner = _nextCornerAfter(_nextCorner);
    });
  }

  ZoneCorner _nextCornerAfter(ZoneCorner corner) {
    switch (corner) {
      case ZoneCorner.topLeft: return ZoneCorner.topRight;
      case ZoneCorner.topRight: return ZoneCorner.bottomLeft;
      case ZoneCorner.bottomLeft: return ZoneCorner.bottomRight;
      case ZoneCorner.bottomRight: return ZoneCorner.none;
      case ZoneCorner.none: return ZoneCorner.none;
    }
  }

  String _cornerName(ZoneCorner corner) {
    switch (corner) {
      case ZoneCorner.topLeft: return '左上';
      case ZoneCorner.topRight: return '右上';
      case ZoneCorner.bottomLeft: return '左下';
      case ZoneCorner.bottomRight: return '右下';
      case ZoneCorner.none: return '';
    }
  }

  bool get _allCornersSet => _corners.length == 4;

  void _saveZone() {
    if (!_allCornersSet) return;
    final zone = StrikeZone(
      topLeft: _corners[ZoneCorner.topLeft]!,
      topRight: _corners[ZoneCorner.topRight]!,
      bottomLeft: _corners[ZoneCorner.bottomLeft]!,
      bottomRight: _corners[ZoneCorner.bottomRight]!,
    );
    context.read<GameStateService>().setStrikeZone(zone);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ストライクゾーンを保存しました'),
        backgroundColor: Color(0xFF00FF88),
      ),
    );
    Navigator.pop(context);
  }

  void _resetCorners() {
    setState(() {
      _corners.clear();
      _nextCorner = ZoneCorner.topLeft;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // カメラ＋ゾーン描画エリア
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) => _onTap(details, constraints),
                  child: Stack(
                    children: [
                      // カメラプレビュー
                      if (_cameraReady && _cameraController != null)
                        SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _cameraController!.value.previewSize!.height,
                              height: _cameraController!.value.previewSize!.width,
                              child: CameraPreview(_cameraController!),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF0A0A0A),
                          child: Center(
                            child: _errorMessage.isNotEmpty
                                ? Text(_errorMessage,
                                    style: const TextStyle(color: Colors.red))
                                : const CircularProgressIndicator(
                                    color: Color(0xFF00FF88)),
                          ),
                        ),

                      // ゾーン描画オーバーレイ
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: ZoneSetupPainter(
                          corners: _corners,
                          canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
                        ),
                      ),

                      // タップガイドUI
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: _buildGuideBar(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ボタンバー
          Container(
            color: const Color(0xFF0A0A0A),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 戻る
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white54),
                ),
                const SizedBox(width: 8),
                // リセット
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetCorners,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('再設定'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 保存
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _allCornersSet ? _saveZone : null,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF88),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBar() {
    if (_nextCorner == ZoneCorner.none && _allCornersSet) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF00FF88).withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '✓ 四隅の設定完了 — 保存してください',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    if (_nextCorner == ZoneCorner.none) return const SizedBox.shrink();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF00FF88), width: 1.5),
        ),
        child: Text(
          'ストライクゾーンの【${_cornerName(_nextCorner)}】をタップ',
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// ゾーン設定用カスタムペインター
class ZoneSetupPainter extends CustomPainter {
  final Map<ZoneCorner, Offset> corners;
  final Size canvasSize;

  ZoneSetupPainter({required this.corners, required this.canvasSize});

  @override
  void paint(Canvas canvas, Size size) {
    final zonePaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF00FF88).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..style = PaintingStyle.fill;

    // 設定済みコーナーを描画
    for (final entry in corners.entries) {
      final pixel = _toPixel(entry.value, size);
      canvas.drawCircle(pixel, 10, dotPaint);

      // ラベル
      final label = _cornerLabel(entry.key);
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pixel.translate(12, -8));
    }

    // 四角形を描画
    if (corners.length == 4) {
      final tl = _toPixel(corners[ZoneCorner.topLeft]!, size);
      final tr = _toPixel(corners[ZoneCorner.topRight]!, size);
      final bl = _toPixel(corners[ZoneCorner.bottomLeft]!, size);
      final br = _toPixel(corners[ZoneCorner.bottomRight]!, size);

      final path = Path()
        ..moveTo(tl.dx, tl.dy)
        ..lineTo(tr.dx, tr.dy)
        ..lineTo(br.dx, br.dy)
        ..lineTo(bl.dx, bl.dy)
        ..close();

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, zonePaint);
    } else if (corners.length >= 2) {
      // 設定途中の線
      final points = corners.values.map((n) => _toPixel(n, size)).toList();
      final linePaint = Paint()
        ..color = const Color(0xFF00FF88).withOpacity(0.5)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], linePaint);
      }
    }
  }

  Offset _toPixel(Offset norm, Size size) {
    return Offset(norm.dx * size.width, norm.dy * size.height);
  }

  String _cornerLabel(ZoneCorner corner) {
    switch (corner) {
      case ZoneCorner.topLeft: return '左上';
      case ZoneCorner.topRight: return '右上';
      case ZoneCorner.bottomLeft: return '左下';
      case ZoneCorner.bottomRight: return '右下';
      case ZoneCorner.none: return '';
    }
  }

  @override
  bool shouldRepaint(ZoneSetupPainter oldDelegate) =>
      oldDelegate.corners != corners;
}

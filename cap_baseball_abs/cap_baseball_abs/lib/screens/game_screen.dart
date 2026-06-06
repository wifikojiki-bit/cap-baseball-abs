import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../models/tracked_object.dart';
import '../models/pitch_result.dart';
import '../services/game_state_service.dart';
import '../services/abs_service.dart';
import '../widgets/bso_counter.dart';
import '../widgets/trajectory_overlay.dart';
import '../widgets/judgment_display.dart';
import '../widgets/zone_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  String _errorMessage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'カメラが見つかりません');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _cameraController!.initialize();

      // フレームストリームを開始
      await _cameraController!.startImageStream(_onFrame);

      if (mounted) setState(() => _cameraReady = true);
    } catch (e) {
      setState(() => _errorMessage = 'カメラ初期化エラー: $e');
    }
  }

  void _onFrame(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    final absService = context.read<ABSService>();
    final gameState = context.read<GameStateService>();

    absService.processFrame(image, gameState.strikeZone);

    // 結果が出たらカウントに反映
    if (absService.lastResult != null &&
        absService.state == TrackingState.showing) {
      final result = absService.lastResult!;
      // 重複適用を防ぐためにタイムスタンプチェック
      _applyResultIfNew(result, gameState);
    }

    _isProcessing = false;
  }

  DateTime? _lastAppliedTimestamp;

  void _applyResultIfNew(PitchResult result, GameStateService gameState) {
    if (_lastAppliedTimestamp == result.timestamp) return;
    _lastAppliedTimestamp = result.timestamp;

    final updated = PitchResult(
      judgment: result.judgment,
      trajectory: result.trajectory,
      timestamp: result.timestamp,
      inning: gameState.inning,
      balls: gameState.balls,
      strikes: gameState.strikes,
    );
    gameState.applyPitchResult(updated);
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameStateService>();
    final absService = context.watch<ABSService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── カメラプレビュー ──
          if (_cameraReady && _cameraController != null)
            Positioned.fill(
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
              color: const Color(0xFF050505),
              child: Center(
                child: _errorMessage.isNotEmpty
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(_errorMessage,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      )
                    : const CircularProgressIndicator(
                        color: Color(0xFF00FF88)),
              ),
            ),

          // ── ストライクゾーンオーバーレイ ──
          Positioned.fill(
            child: ZoneOverlay(zone: gameState.strikeZone),
          ),

          // ── 軌道オーバーレイ ──
          Positioned.fill(
            child: TrajectoryOverlay(
              trajectory: absService.trajectory,
              currentDetection: absService.currentDetection,
              isTracking: absService.isTracking,
            ),
          ),

          // ── 判定結果表示 ──
          if (absService.isShowingResult && absService.lastResult != null)
            Positioned.fill(
              child: JudgmentDisplay(result: absService.lastResult!),
            ),

          // ── トップバー（イニング情報） ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: _buildTopBar(gameState, absService),
            ),
          ),

          // ── BSOカウンター（右側） ──
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: BSOCounter(gameState: gameState),
            ),
          ),

          // ── 追跡状態インジケーター ──
          Positioned(
            bottom: 16,
            left: 16,
            child: _TrackingIndicator(state: absService.state),
          ),

          // ── 手動操作ボタン ──
          Positioned(
            bottom: 16,
            right: 80,
            child: _ManualControls(
              gameState: gameState,
              absService: absService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(GameStateService gameState, ABSService absService) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          // 戻るボタン
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 16),
          // イニング表示
          Text(
            gameState.inningText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // ABS状態
          _ABSStatusBadge(state: absService.state),
        ],
      ),
    );
  }
}

class _ABSStatusBadge extends StatelessWidget {
  final TrackingState state;
  const _ABSStatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (state) {
      case TrackingState.tracking:
        color = Colors.orange;
        label = '● 追跡中';
        break;
      case TrackingState.showing:
        color = const Color(0xFF00FF88);
        label = '✓ 判定済';
        break;
      default:
        color = Colors.white38;
        label = '○ 待機中';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _TrackingIndicator extends StatelessWidget {
  final TrackingState state;
  const _TrackingIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state == TrackingState.idle) return const SizedBox.shrink();

    Color color = Colors.orange;
    if (state == TrackingState.showing) color = const Color(0xFF00FF88);

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6, spreadRadius: 2)],
      ),
    );
  }
}

class _ManualControls extends StatelessWidget {
  final GameStateService gameState;
  final ABSService absService;
  const _ManualControls({required this.gameState, required this.absService});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ManualButton(
            icon: Icons.refresh,
            label: 'リセット',
            onTap: () {
              absService.resetDetection();
              gameState.resetCount();
            },
          ),
          const Divider(color: Colors.white12, height: 1),
          _ManualButton(
            icon: Icons.skip_next,
            label: '次の回',
            onTap: () => gameState.nextInning(),
          ),
        ],
      ),
    );
  }
}

class _ManualButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ManualButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

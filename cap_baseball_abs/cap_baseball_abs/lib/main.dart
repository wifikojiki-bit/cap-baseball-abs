import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'screens/home_screen.dart';
import 'services/game_state_service.dart';
import 'services/abs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 横向き固定（カメラ映像の安定表示のため）
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // 画面常時ON
  await WakelockPlus.enable();

  runApp(const CapBaseballABSApp());
}

class CapBaseballABSApp extends StatelessWidget {
  const CapBaseballABSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameStateService()),
        ChangeNotifierProvider(create: (_) => ABSService()),
      ],
      child: MaterialApp(
        title: 'キャップ野球 ABS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.dark(
            primary: const Color(0xFF00FF88),
            secondary: const Color(0xFFFF4444),
            surface: const Color(0xFF0A0A0A),
          ),
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

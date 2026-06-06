# キャップ野球 ABS（Automatic Ball/Strike System）

スマートフォン1台でキャップ野球の投球を自動判定するFlutterアプリです。

---

## 📱 対応環境

| 項目 | 詳細 |
|------|------|
| プラットフォーム | Android（iOS移植容易） |
| Flutter SDK | 3.0.0 以上 |
| 最低Android | API 21 (Android 5.0) |
| カメラ | 背面カメラ必須、60fps推奨 |
| 動作環境 | 完全オフライン |

---

## 🗂️ プロジェクト構成

```
lib/
├── main.dart                    # エントリーポイント
├── models/
│   ├── strike_zone.dart         # ストライクゾーンモデル
│   ├── tracked_object.dart      # 追跡オブジェクトモデル
│   └── pitch_result.dart        # 投球判定結果モデル
├── services/
│   ├── game_state_service.dart  # ゲーム状態管理（BSOカウント等）
│   ├── abs_service.dart         # ABS主制御（投球検知・判定）
│   └── cap_detector.dart        # キャップ検出エンジン
├── screens/
│   ├── home_screen.dart         # ホーム画面
│   ├── zone_setup_screen.dart   # ストライクゾーン設定画面
│   ├── game_screen.dart         # 試合画面（メイン）
│   └── history_screen.dart      # 判定履歴画面
└── widgets/
    ├── bso_counter.dart          # BSOカウンター
    ├── zone_overlay.dart         # ゾーンオーバーレイ
    ├── trajectory_overlay.dart   # 軌道描画
    └── judgment_display.dart     # 判定結果表示
```

---

## 🚀 セットアップ

### 1. 依存パッケージのインストール

```bash
flutter pub get
```

### 2. Android ビルド設定

`android/app/build.gradle` を確認：

```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
    }
}
```

### 3. 実機へのデプロイ

```bash
flutter run --release
```

---

## 📋 使用方法

### 試合前セットアップ（必須）

1. **ゾーン設定** をタップ
2. カメラをホームプレート方向に向けて固定
3. 画面上のストライクゾーン四隅を順番にタップ
   - 左上 → 右上 → 左下 → 右下 の順
4. **保存** をタップ

### 試合中の操作

1. スマートフォンを捕手後方に固定（三脚等推奨）
2. **試合開始** をタップ
3. 投球ごとに自動判定：
   - STRIKE（緑）または BALL（赤）が表示
   - 日本語音声で読み上げ
4. BSOカウントは右側に常時表示
5. カウントは自動更新（手動修正も可）

### 手動操作

| 操作 | 方法 |
|------|------|
| カウントリセット | BSOの「RST」ボタン |
| イニング切替 | 「次の回」ボタン |
| ストライク手動 | S列をタップ |
| ボール手動 | B列をタップ |
| アウト手動 | O列をタップ |

---

## 🔧 キャップ検出の仕組み

### 検出優先順位

```
1. 色認識（白・赤・黄色系）
   ↓ 見つからない場合
2. 動体検出（フレーム差分）
   ↓ 組み合わせ
3. ブロブ解析（円形度・サイズフィルタ）
```

### チューニング

`lib/services/cap_detector.dart` の `DetectionConfig` を調整：

```dart
const DetectionConfig(
  // キャップの色範囲（白・薄色）
  valMin: 100,       // 明度の最低値（増やすと白系のみ）
  
  // サイズフィルタ（3m先での約4cmキャップ）
  minRadiusNorm: 0.010,   // 小さすぎる検出を除外
  maxRadiusNorm: 0.080,   // 大きすぎる検出を除外
  
  // 投球判定速度
  motionThreshold: 0.002, // 大きくすると速い動きのみ追跡
);
```

---

## 📐 判定ロジック

```
投球検知条件:
  └ キャップが5フレーム以上連続検出
  └ 速度 > minVelocity

判定処理:
  └ キャップ消失後10フレームで投球終了
  └ 軌道後半40%の座標をゾーン内チェック
  └ 1点でもゾーン内 → STRIKE
  └ すべてゾーン外 → BALL
```

---

## 🔮 将来の拡張（設計済み）

- [ ] **TensorFlow Lite統合** — キャップ専用モデルで精度向上
- [ ] **2台スマホ3D判定** — WebSocket連携
- [ ] **投球速度測定** — フレームレートと座標変化から計算
- [ ] **リプレイ機能** — 投球動画クリップ保存
- [ ] **試合データ分析** — CSV/JSON エクスポート
- [ ] **クラウド同期** — Firebase対応

---

## 🐛 トラブルシューティング

| 問題 | 対処法 |
|------|--------|
| 誤検出が多い | `minRadiusNorm` を増加、`motionThreshold` を増加 |
| キャップを見逃す | `minRadiusNorm` を減少、撮影距離を調整 |
| 判定が遅い | 端末のパフォーマンスモードをON、解像度を下げる |
| 音声が出ない | 端末の音量確認、TTS言語パックのインストール |

---

## 📄 ライセンス

MIT License - キャップ野球普及のため自由にご利用ください

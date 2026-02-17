# brevet_map

A new Flutter project.

## Google Maps API キー（Dart 側・.env で「flutter run」のみで動かす）

**「flutter run」だけで動かす場合（推奨）**

1. プロジェクトルートで `.env` を作成する（初回のみ）
   ```bash
   cp env.example .env
   ```
2. `.env` を開き、`GOOGLE_MAPS_API_KEY=` に API キーを追加
3. `flutter run` のみで OK（`--dart-define` 不要）

`.env` は .gitignore 済み 
Android は `android/local.properties` の `google.maps.api.key`、iOS は `ios/Runner/Secrets.xcconfig` の設定も必要（地図表示用）

`--dart-define` を使う場合:  
`flutter run --dart-define=GOOGLE_MAPS_API_KEY=あなたのキー`  
（.env より優先される）

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

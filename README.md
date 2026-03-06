# brevet_map

A new Flutter project.

## Google Maps API キーの必須設定

地図表示と Directions API を利用するため、以下の 3 か所に API キーを設定する必要があります。いずれも `.gitignore` 済みのため、GitHub には公開されません。

| プラットフォーム | 設定先 | 用途 |
|-----------------|--------|------|
| **Dart** | `.env`（flutter_dotenv） | Directions API（ルート取得） |
| **Android** | `local.properties` | 地図表示（ネイティブ SDK） |
| **iOS** | `ios/Runner/Secrets.xcconfig` | 地図表示（ネイティブ SDK） |

### 設定手順

**1. Dart 用（.env）**

```bash
cp env.example .env
```

`.env` を開き、`GOOGLE_MAPS_API_KEY=あなたのキー` を記述。

**2. Android 用（local.properties）**

`android/local.properties` に以下を追加（ファイルがなければ作成）:

```
google.maps.api.key=あなたのキー
```

**3. iOS 用（Secrets.xcconfig）**

`ios/Runner/Secrets.xcconfig` を作成し、以下を記述:

```
GOOGLE_MAPS_API_KEY=あなたのキー
```

※ `Secrets.xcconfig` は `ios/Flutter/*.xcconfig` から参照されます。

### Dart のみ別の方法を使う場合

`--dart-define` で渡すことも可能（.env より優先）:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=あなたのキー
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

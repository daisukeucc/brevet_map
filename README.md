# brevet_map

Flutter アプリ（brevet_map）。

## Google Maps API キーの必須設定

地図・Directions 用のキーは、プロジェクトルートの **`.env`**（`flutter_dotenv`）に記述します。`.env` は `.gitignore` 済みです。

```bash
cp env.example .env
```

`.env` を開き、`GOOGLE_MAPS_API_KEY=あなたのキー` を記述。

### 別の方法（.env を使わない場合）

`--dart-define` で渡すことも可能（.env より優先）:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=あなたのキー
```

## iOS での動作確認

iOS 14 以降では、デバッグモード（`flutter run`）でアプリをタスクキル後に再起動するとクラッシュする場合があります。本番動作に近い挙動の確認には、リリース版で実行することを推奨します。

```bash
flutter run --release
```

## CI とリリース（GitHub Actions）

### 全体の流れ

# brevet_map

Flutter アプリ（brevet_map）。

## Google Maps API キーの必須設定

地図・Directions 用のキーは、プロジェクトルートの **`.env`**（`flutter_dotenv`）に記述します。`.env` は `.gitignore` 済みです。

```bash
cp env.example .env
```

`.env` を開き、`GOOGLE_MAPS_API_KEY=あなたのキー` を記述。

### 別の方法（.env を使わない場合）

`--dart-define` で渡すことも可能（.env より優先）:

```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=あなたのキー
```

## iOS での動作確認

iOS 14 以降では、デバッグモード（`flutter run`）でアプリをタスクキル後に再起動するとクラッシュする場合があります。本番動作に近い挙動の確認には、リリース版で実行することを推奨します。

```bash
flutter run --release
```

## CI とリリース（GitHub Actions）

### 全体の流れ

| ワークフロー | いつ動くか | 何をするか |
|--------------|------------|------------|
| **CI**（`.github/workflows/ci.yml`） | `main` / `master` への push、または PR の作成・更新 | `flutter pub get` → `flutter analyze` → `flutter test` |
| **Release (Fastlane)**（`release.yml`） | **手動のみ**（Actions の「Run workflow」） | 署名付きビルド → **TestFlight**（iOS）／**Play internal**（Android）へアップロード |
| **Build**（`build.yml`） | **手動のみ** | リリース APK と、`--no-codesign` の iOS ビルドを **Artifact** に保存（ストアには上げない） |

- **ストアへ実際にビルドを載せる**のは **Release ワークフロー**だけです。CI や Build ではアップロードしません。
- **App Store の審査提出・本番公開**は、このリポジトリのワークフローでは自動化していません。**App Store Connect** 上の操作が必要です。

### リリース（TestFlight / Play internal）の手順

1. **GitHub Secrets** に、`.github/workflows/release.yml` 先頭コメントに記載の名前で必要な値を登録する（iOS は Distribution `.p12`、App Store 用プロビジョニングプロファイル 2 本、Team ID、App Store Connect API キーなど）。
2. リポジトリの **Actions** → **Release (Fastlane)** → **Run workflow**。
3. **platform** で `android` / `ios` / `both` を選んで実行する。

ビルドとアップロードの具体的なコマンドは **Fastlane**（`ios/fastlane/Fastfile`、`android/fastlane/Fastfile`）に定義されています。CI の YAML は環境構築のあと `bundle exec fastlane …` を呼び出します。

### 補足

| ワークフロー | いつ動くか | 何をするか |
|--------------|------------|------------|
| **CI**（`.github/workflows/ci.yml`） | `main` / `master` への push、または PR の作成・更新 | `flutter pub get` → `flutter analyze` → `flutter test` |
| **Release (Fastlane)**（`release.yml`） | **手動のみ**（Actions の「Run workflow」） | 署名付きビルド → **TestFlight**（iOS）／**Play internal**（Android）へアップロード |
| **Build**（`build.yml`） | **手動のみ** | リリース APK と、`--no-codesign` の iOS ビルドを **Artifact** に保存（ストアには上げない） |

- **ストアへ実際にビルドを載せる**のは **Release ワークフロー**だけです。CI や Build ではアップロードしません。
- **App Store の審査提出・本番公開**は、このリポジトリのワークフローでは自動化していません。**App Store Connect** 上の操作が必要です。

### リリース（TestFlight / Play internal）の手順

1. **GitHub Secrets** に、`.github/workflows/release.yml` 先頭コメントに記載の名前で必要な値を登録する（iOS は Distribution `.p12`、App Store 用プロビジョニングプロファイル 2 本、Team ID、App Store Connect API キーなど）。
2. リポジトリの **Actions** → **Release (Fastlane)** → **Run workflow**。
3. **platform** で `android` / `ios` / `both` を選んで実行する。

ビルドとアップロードの具体的なコマンドは **Fastlane**（`ios/fastlane/Fastfile`、`android/fastlane/Fastfile`）に定義されています。CI の YAML は環境構築のあと `bundle exec fastlane …` を呼び出します。

### 補足

- **同じビルド番号の再アップロード**はストア側で拒否されやすいです。再実行する前に `pubspec.yaml` の `version:` の **`+` 右（ビルド番号）**を上げることを推奨します。

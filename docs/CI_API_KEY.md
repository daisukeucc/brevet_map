# CI（GitHub Actions）での API キー運用

## 結論

- **ローカル**: `.env` を使う運用
- **CI**: `.env` はリポジトリに含めないため、**GitHub Secrets からキーを注入**する  
  `.env` はCI 内で Secrets から生成する

## 推奨: GitHub Secrets で一元管理

1. **GitHub リポジトリ**  
   **Settings → Secrets and variables → Actions** で次を追加する:
   - `GOOGLE_MAPS_API_KEY` … Google Maps / Directions API 用キー

2. **CI での渡し方（3通り、どれかで OK）**

   | 方法 | 内容 | 備考 |
   |------|------|------|
   | **A. .env を CI で生成** | ワークフロー内で `echo "GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}" > .env` してからビルド | 今の .env 運用をそのまま使える |
   | **B. --dart-define** | `flutter build ... --dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}` | Dart 側は既に `fromEnvironment` 対応済み。キーをビルド引数で渡すだけ |
   | **C. 両方** | A と B のどちらでも動くようにしておく | ローカルは .env、CI は B だけでも可 |

3. **Android / iOS 用**

   - **Android**: CI で `android/local.properties` に  
     `google.maps.api.key=${{ secrets.GOOGLE_MAPS_API_KEY }}` を追記（または生成）
   - **iOS**: CI で `ios/Runner/Secrets.xcconfig` を生成し  
     `GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}` を書き込む

## .env 運用で問題ないか

- **ローカル**: このまま .env 運用で問題ありません。
- **CI**:  
  - .env は Git に含めないので、CI 実行時には「リポジトリ内に .env は存在しない」状態
  - そのため **CI では「.env を Secrets から毎回生成する」** か、**Dart には --dart-define で渡す**かのどちらかが必要
  - 上記のとおり対応すれば、**.env をローカル用の主な方法として使いつつ、CI でも同じキーを安全に使う運用で問題ない**

## より CI 向きの方法（オプション）

- **キーはすべて GitHub Secrets にだけ持つ**
- **CI では**  
  - Dart: `--dart-define=GOOGLE_MAPS_API_KEY=${{ secrets.GOOGLE_MAPS_API_KEY }}`  
  - Android: Secrets から `local.properties` の `google.maps.api.key` を生成  
  - iOS: Secrets から `Secrets.xcconfig` を生成  
- **ローカル**  
  - 従来どおり .env / local.properties / Secrets.xcconfig にキーを記述
  - または CI と同じく dart-define で渡す  

このように「本番・CI は Secrets のみ、ローカルは .env など」に分ける運用が、ストア公開まで自動化する場合の**最適に近い方法**です

---

## サンプルワークフロー

`.github/workflows/build.yml` → Secrets からキーを注入してビルドするサンプル

**事前準備**
1. リポジトリの **Settings → Secrets and variables → Actions** で `GOOGLE_MAPS_API_KEY` を追加
2. リポジトリ構成に合わせて、ワークフロー内の「Set project directory」のパス（`pubspec.yaml` の場所）を確認

**ストア公開まで自動化する場合**
- **Android**: 署名用の keystore を Secrets に登録し、`flutter build appbundle` とアップロードステップを追加
- **iOS**: 証明書・Provisioning Profile を Secrets に登録し、`flutter build ipa` と App Store Connect へのアップロード（fastlane や apple-actions など）を追加

必要に応じて上記サンプルをベースに、ストア提出用のジョブを追加する

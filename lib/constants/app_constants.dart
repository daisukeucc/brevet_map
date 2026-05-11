/// お問い合わせ先メールアドレス
const String kContactEmail = 'brevetmap@gmail.com';

/// 現在地共有用 Google Maps URL のテンプレート
String kGoogleMapsLocationUrl(double lat, double lng) =>
    'https://maps.google.com/maps?q=$lat,$lng';

/// プライバシーポリシー URL
const String kPrivacyPolicyUrl = 'https://daisukeucc.github.io/privacy_policy/';

/// 標準の Apple 利用規約（EULA）。App Store の説明文にも同 URL を含めてください。
const String kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// サブスクリプション管理 URL
const String kManageSubscriptionIosUrl =
    'https://apps.apple.com/account/subscriptions';
const String kManageSubscriptionAndroidUrl =
    'https://play.google.com/store/account/subscriptions';

/// 機能全解放（RevenueCat の `premium` なしで POI 編集等を利用可）の対象ビルド。
/// [pubspec.yaml] の `version: x.y.z+build` と同じ表記（例 `1.1.0+18`）を [Set] に追加する。
const Set<String> kAppVersionsWithFullFeatureUnlock = {
  '1.1.0+18',
  '1.2.0+19',
  '1.2.1+20',
};

/// リリースノート（バージョン説明）ダイアログを出す [pubspec] の `x.y.z+build` 一覧。文言は l10n（例: releaseNotesV11018Message）と `release_notes_dialog` の分岐を対に追加する。
const Set<String> kReleaseNoteDialogVersionBuildIds = {
  '1.1.0+18',
  '1.2.0+19',
};

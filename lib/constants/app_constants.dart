/// お問い合わせ先メールアドレス
const String kContactEmail = 'brevetmap@gmail.com';

/// 現在地共有用 Google Maps URL のテンプレート
String kGoogleMapsLocationUrl(double lat, double lng) =>
    'https://maps.google.com/maps?q=$lat,$lng';

/// プライバシーポリシー URL
const String kPrivacyPolicyUrl =
    'https://daisukeucc.github.io/privacy_policy/';

/// 利用規約（EULA）。専用ページを用意したら差し替えてください。
const String kTermsOfUseUrl =
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

/// サブスクリプション管理 URL
const String kManageSubscriptionIosUrl =
    'https://apps.apple.com/account/subscriptions';
const String kManageSubscriptionAndroidUrl =
    'https://play.google.com/store/account/subscriptions';

/// お問い合わせ先メールアドレス
const String kContactEmail = 'brevetmap@gmail.com';

/// 現在地共有用 Google Maps URL のテンプレート
String kGoogleMapsLocationUrl(double lat, double lng) =>
    'https://maps.google.com/maps?q=$lat,$lng';

/// 購読規約 URL
const String kSubscriptionTermsUrl =
    'https://daisukeucc.github.io/privacy_policy/';

/// サブスクリプション管理 URL
const String kManageSubscriptionIosUrl =
    'https://apps.apple.com/account/subscriptions';
const String kManageSubscriptionAndroidUrl =
    'https://play.google.com/store/account/subscriptions';

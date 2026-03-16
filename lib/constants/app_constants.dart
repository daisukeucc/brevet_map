/// お問い合わせ先メールアドレス
const String kContactEmail = 'brevetmap@gmail.com';

/// 現在地共有用 Google Maps URL のテンプレート
String kGoogleMapsLocationUrl(double lat, double lng) =>
    'https://maps.google.com/maps?q=$lat,$lng';

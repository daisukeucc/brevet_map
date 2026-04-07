import 'dart:ui' show Locale;

/// 言語が en / fr / de / es / it など「その他」のときの既定座標（従来どおり）
const double kDefaultInstallOtherLat = 48.659149;
const double kDefaultInstallOtherLng = 1.817959;

/// アプリの保存言語コード（[language_handler] の `localeToCode` と同じキー）から、
/// 初回インストール時に保存するフォールバック座標を返す。
({double lat, double lng}) defaultInstallCoordinatesForLocaleCode(String? code) {
  switch (code) {
    case 'ja':
      return (lat: 35.6812, lng: 139.7671); // 東京
    case 'th':
      return (lat: 13.7563, lng: 100.5018); // バンコク
    case 'zh':
      return (lat: 39.9042, lng: 116.4074); // 北京（简体）
    case 'zh_Hant':
      return (lat: 25.0330, lng: 121.5654); // 台北（繁體）
    case 'ko':
      return (lat: 37.5665, lng: 126.9780); // ソウル
    default:
      return (lat: kDefaultInstallOtherLat, lng: kDefaultInstallOtherLng);
  }
}

/// システム言語に従う（言語プリファレンスが未設定のとき）用。
/// 端末ロケールが ja / th / zh / ko に近い場合はそれに合わせ、それ以外は [その他]。
({double lat, double lng}) defaultInstallCoordinatesForSystemLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ja':
      return defaultInstallCoordinatesForLocaleCode('ja');
    case 'th':
      return defaultInstallCoordinatesForLocaleCode('th');
    case 'ko':
      return defaultInstallCoordinatesForLocaleCode('ko');
    case 'zh':
      if (locale.scriptCode == 'Hant') {
        return defaultInstallCoordinatesForLocaleCode('zh_Hant');
      }
      return defaultInstallCoordinatesForLocaleCode('zh');
    default:
      return defaultInstallCoordinatesForLocaleCode(null);
  }
}

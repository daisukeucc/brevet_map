import 'package:package_info_plus/package_info_plus.dart';

/// OpenStreetMap タイルの設定。
/// 選択言語に応じてタイルを切り替える（日本語: OSMFJ、その他: 標準OSM）。
class TileConfig {
  TileConfig._();

  /// 日本語タイル（OSMFJ）
  static const String _tileUrlTemplateJa =
      'https://tile.openstreetmap.jp/styles/osm-bright-ja/{z}/{x}/{y}.png';

  /// 英語・その他用の標準OSMタイル
  static const String _tileUrlTemplateEn =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// 言語コードに応じたタイルURLテンプレート（{z}/{x}/{y} が置換される）
  static String getTileUrlTemplate(String languageCode) {
    return languageCode == 'ja' ? _tileUrlTemplateJa : _tileUrlTemplateEn;
  }

  /// デバッグ専用: CARTO Voyager ラスタ（kDebugMode のみで使用）
  static const String debugCartoVoyagerTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';

  /// デバッグ専用: CARTO light_all ラスタ（kDebugMode のみで使用）
  static const String debugCartoLightTileUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png';

  /// デバッグ用 CARTO テンプレートを返す。[light] が true のとき light_all。
  static String getDebugCartoTileUrlTemplate({required bool light}) {
    return light ? debugCartoLightTileUrlTemplate : debugCartoVoyagerTileUrlTemplate;
  }

  /// [urlTemplate] に応じた帰属表示文
  static String attributionForTemplate(String urlTemplate) {
    if (urlTemplate.contains('basemaps.cartocdn.com')) {
      return '© OpenStreetMap contributors © CARTO';
    }
    return attribution;
  }

  /// @deprecated 代わりに getTileUrlTemplate(languageCode) を使用する
  static String get tileUrlTemplate => _tileUrlTemplateJa;

  /// タイルのクレジット表示
  static const String attribution = '© OpenStreetMap Contributors';

  /// pubspec.yaml の name（PackageInfo 失敗時のフォールバック用）
  static const String _fallbackPackageSlug = 'brevet_map';

  /// pubspec.yaml の version（PackageInfo 失敗時のフォールバック用。更新時に合わせること）
  static const String _fallbackVersion = '1.0.0';

  /// User-Agent用のパッケージ名。main()で初期化。未初期化時はフォールバック値。
  static String userAgentPackageName = _fallbackPackageSlug;

  /// OSMタイルサーバー用のUser-Agent。
  /// tile.openstreetmap.org は厳格なポリシーを適用するため、アプリを明確に識別する必要がある。
  static String userAgent =
      'BrevetMap/$_fallbackVersion ($_fallbackPackageSlug)';

  /// FMTC（タイルキャッシュ）の初期化に成功したかどうか。
  /// main() で true にセットされる。false のときは NetworkTileProvider を使う。
  static bool fmtcReady = false;

  /// アプリのパッケージ名・バージョンで userAgentPackageName と userAgent を初期化。
  static Future<void> initUserAgentPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform()
          .timeout(const Duration(seconds: 3));
      userAgentPackageName = info.packageName;
      userAgent = 'BrevetMap/${info.version} ($userAgentPackageName)';
    } catch (_) {}
  }
}

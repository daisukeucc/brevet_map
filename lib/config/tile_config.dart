import 'package:package_info_plus/package_info_plus.dart';

/// OpenStreetMap タイルの設定。
/// 日本語ラベル版（OSMFJ）を使用。
class TileConfig {
  TileConfig._();

  /// タイルURLテンプレート（{z}/{x}/{y} が置換される）
  static const String tileUrlTemplate =
      'https://tile.openstreetmap.jp/styles/osm-bright-ja/{z}/{x}/{y}.png';

  /// タイルのクレジット表示
  static const String attribution =
      '© OpenStreetMap Contributors';

  /// User-Agent用のパッケージ名。main()で初期化。未初期化時はフォールバック値。
  static String userAgentPackageName = 'dev.brevet_map.app';

  /// アプリのパッケージ名で userAgentPackageName を初期化。
  static Future<void> initUserAgentPackageName() async {
    try {
      final info = await PackageInfo.fromPlatform();
      userAgentPackageName = info.packageName;
    } catch (_) {}
  }
}

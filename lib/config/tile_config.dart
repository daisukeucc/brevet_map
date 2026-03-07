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
}

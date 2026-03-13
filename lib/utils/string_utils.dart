/// 全角のローマ字・数字・スペースを半角に変換する。
/// 日本語のひらがな・カタカナ・漢字はそのまま。
String toHalfwidthAscii(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final c = String.fromCharCode(rune);
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      // 全角英数字・記号 (U+FF01-FF5E) → 半角 (U+0021-007E)
      buffer.writeCharCode(rune - 0xFEE0);
    } else if (rune == 0x3000) {
      // 全角スペース → 半角スペース
      buffer.writeCharCode(0x0020);
    } else {
      buffer.write(c);
    }
  }
  return buffer.toString();
}

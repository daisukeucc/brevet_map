/// App Store / Play の商品名に付く末尾のサブタイトル・アプリ名を表示用に取り除く。
/// ストア側の登録はそのままでよい。除去後が空になる場合は [rawTitle] を返す。
String storeProductTitleForDisplay(String rawTitle) {
  var s = rawTitle.trim();
  if (s.isEmpty) return s;
  final original = s;

  // 末尾のサブタイトル「（ブルベMAP オフライン GPS）」など「（…）」「(...)」を繰り返し除去
  final reFull = RegExp(r'（[^）]*）\s*$');
  final reHalf = RegExp(r'\([^)]*\)\s*$');
  while (true) {
    final next = s.replaceFirst(reFull, '').trimRight();
    if (next == s) break;
    s = next;
  }
  while (true) {
    final next = s.replaceFirst(reHalf, '').trimRight();
    if (next == s) break;
    s = next;
  }

  const suffixes = <String>[
    ' - Brevet Map',
    ' – Brevet Map', // en dash
    ' — Brevet Map', // em dash
    ': Brevet Map',
    '：Brevet Map',
    '(Brevet Map)',
    '（Brevet Map）',
    ' - ブルベMAP',
    ' – ブルベMAP',
    '：ブルベMAP',
    '（ブルベMAP）',
  ];
  for (final suf in suffixes) {
    if (s.endsWith(suf)) {
      s = s.substring(0, s.length - suf.length).trimRight();
      break;
    }
  }

  return s.isEmpty ? original : s;
}

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

import 'package:intl/date_symbol_data_local.dart';

/// [initializeDateFormatting] を1回だけ実行する。
///
/// - [DateFormat] を使う画面（定期購入・位置共有コールアウト等）向け。
/// - 起動の [main] では await せず、ホーム表示後のバックグラウンド開始と、
///   ダイアログ表示直前の [await] の両方から呼べる。
Future<void>? _dateFormattingFuture;

/// 日付ロケールデータを初期化する。既に開始済みなら同一 [Future] を返す。
Future<void> ensureDateFormattingInitialized() {
  return _dateFormattingFuture ??= initializeDateFormatting().timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      // 起動優先。未初期化のまま一部 DateFormat が弱くなる可能性はあるがクラッシュは避ける
    },
  );
}

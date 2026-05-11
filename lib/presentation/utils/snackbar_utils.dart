import 'package:flutter/material.dart';

/// アプリ全体で使用する SnackBar の共通スタイル（暗い背景・白文字）
const Color _kDarkBackground = Color(0x99000000);
const TextStyle _kDarkTextStyle = TextStyle(fontSize: 16, color: Colors.white);

/// SnackBar を表示する共通ユーティリティ。
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SafeArea(
        bottom: false,
        child: Text(message, style: _kDarkTextStyle),
      ),
      backgroundColor: _kDarkBackground,
      action: action,
    ),
  );
}

/// ScaffoldMessenger を直接指定する場合（ダイアログコールバック内など、context が変わる可能性があるとき）。
void showAppSnackBarWithMessenger(
  ScaffoldMessengerState messenger,
  String message,
) {
  messenger.showSnackBar(
    SnackBar(
      content: SafeArea(
        bottom: false,
        child: Text(message, style: _kDarkTextStyle),
      ),
      backgroundColor: _kDarkBackground,
    ),
  );
}

/// [ScaffoldMessenger] の SnackBar より手前に表示する（画面中央）。
/// 画面タップで閉じる。一定時間後に自動で閉じる。
///
/// `showModalBottomSheet` 内など、[ScaffoldMessenger] のスナックバーが
/// シートの背面に回って見えないときに使う。
void showAppSnackBarOverlaid(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;
  final padding = MediaQuery.paddingOf(context);
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) {
      void dismiss() {
        if (entry.mounted) entry.remove();
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: dismiss,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: padding.top + 8,
              bottom: padding.bottom + 8,
            ),
            child: Center(
              child: GestureDetector(
                onTap: dismiss,
                child: Material(
                  color: _kDarkBackground,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Text(
                      message,
                      style: _kDarkTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  overlay.insert(entry);
  Future<void>.delayed(duration).then((_) {
    if (entry.mounted) entry.remove();
  });
}

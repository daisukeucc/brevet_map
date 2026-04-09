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

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// 本文とボタンのみの確認ダイアログを表示する。
/// キャンセルで false、確認で true を返す。
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String message,
  required String cancelText,
  required String confirmText,
  /// true のとき、下層ダイアログと重ねた際の二重オーバーレイを避けるためバリアを透明にする
  bool transparentBarrier = false,
}) {
  final compactButtonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(Size.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  return showDialog<bool>(
    context: context,
    barrierColor: transparentBarrier ? Colors.transparent : Colors.black54,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
      content: Text(message, style: AppTextStyles.title),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelText, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmText, style: AppTextStyles.button),
        ),
      ],
    ),
  );
}

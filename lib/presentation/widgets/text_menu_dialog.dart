import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// テキストのみのメニューを表示するダイアログ。
/// 選択した項目のインデックスを返す。キャンセル時は null。
Future<int?> showTextMenuDialog(
  BuildContext context, {
  required List<String> items,
}) {
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            ListTile(
              title: Text(items[i], style: AppTextStyles.label),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              onTap: () => Navigator.pop(context, i),
            ),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../theme/app_text_styles.dart';

/// ラジオボタンで項目を選択するダイアログを表示する。
void showRadioSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<(T value, String label)> options,
  required T initialValue,
  required void Function(T) onChanged,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) {
      T selected = initialValue;
      return StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: Text(title, style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) const SizedBox(height: 5),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setDialogState(() => selected = options[i].$1);
                    onChanged(options[i].$1);
                    Future.delayed(const Duration(milliseconds: 400), () {
                      if (ctx.mounted) Navigator.pop(ctx);
                    });
                  },
                  child: SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Radio<T>(
                          value: options[i].$1,
                          groupValue: selected,
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => selected = v);
                            onChanged(v);
                            Future.delayed(const Duration(milliseconds: 400),
                                () {
                              if (ctx.mounted) Navigator.pop(ctx);
                            });
                          },
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        const SizedBox(width: 5),
                        Text(options[i].$2, style: AppTextStyles.label),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 5),
            ],
          ),
        ),
      );
    },
  );
}

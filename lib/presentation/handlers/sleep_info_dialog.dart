import 'package:flutter/material.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// 画面スリープの説明ダイアログを表示する。
/// 「画面スリープ設定」ボタンがタップされたら true を返す。
Future<bool> showSleepInfoDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
      var dontShowAgain = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: const RoundedRectangleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.sleepInfoMessage1,
                    style: AppTextStyles.body.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.sleepInfoMessage2,
                    style: AppTextStyles.body.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        if (dontShowAgain) {
                          await saveSleepInfoDismissed(true);
                        }
                        if (context.mounted) Navigator.pop(context, true);
                      },
                      child: Text(
                        l10n.sleepSettings,
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: InkWell(
                      onTap: () =>
                          setState(() => dontShowAgain = !dontShowAgain),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: dontShowAgain,
                            onChanged: (v) =>
                                setState(() => dontShowAgain = v ?? false),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          Text(
                            l10n.sleepInfoDontShowAgain,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  return result == true;
}

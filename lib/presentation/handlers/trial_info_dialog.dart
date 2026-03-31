import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// トライアル期間の説明ダイアログを表示する。
/// [remainingDays] にはトライアル期間の残り日数を渡す。
/// 「定期購入」がタップされた場合は true を返す。
Future<bool> showTrialInfoDialog(
  BuildContext context, {
  required int remainingDays,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final subscribed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) {
      return Dialog(
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.trialInfoMessage,
                style: AppTextStyles.body.copyWith(height: 1.6),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '[ ${l10n.trialInfoRemainingDays(remainingDays)} ]',
                  style: AppTextStyles.headline,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(context, true);
                      await RevenueCatUI.presentPaywall();
                    },
                    child: Text(l10n.trialInfoSubscribe,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(l10n.ok, style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return subscribed == true;
}

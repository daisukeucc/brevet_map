import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';

void handleCheckInVerifyLocationChange(WidgetRef ref, bool verifyLocation) {
  ref.read(checkInVerifyLocationProvider.notifier).state = verifyLocation;
  saveCheckInVerifyLocation(verifyLocation);
}

/// チェックイン時の位置検証オン/オフを選ぶ設定ダイアログ
void showCheckInSettingsDialog(BuildContext context, WidgetRef ref) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) {
      var selected = ref.read(checkInVerifyLocationProvider);
      final l10n = AppLocalizations.of(ctx)!;
      return StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
          titlePadding: const EdgeInsets.fromLTRB(28, 28, 28, 8),
          contentPadding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
          title: Text(l10n.checkInSettingsTitle, style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RadioGroup<bool>(
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() => selected = v);
                  handleCheckInVerifyLocationChange(ref, v);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (ctx.mounted) Navigator.pop(ctx);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final verify in [true, false]) ...[
                      if (!verify) const SizedBox(height: 4),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setDialogState(() => selected = verify);
                          handleCheckInVerifyLocationChange(ref, verify);
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (ctx.mounted) Navigator.pop(ctx);
                          });
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Radio<bool>(
                                value: verify,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  verify
                                      ? l10n.checkInVerifyLocationRadioOn
                                      : l10n.checkInVerifyLocationRadioOff,
                                  style: AppTextStyles.checkBoxLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

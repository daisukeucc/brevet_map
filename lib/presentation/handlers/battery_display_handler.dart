import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';

/// バッテリー残量表示設定を変更したときのハンドラ
void handleBatteryDisplayChange(WidgetRef ref, bool value) {
  ref.read(batteryDisplayProvider.notifier).state = value;
  saveBatteryDisplay(value);
}

/// バッテリー残量表示設定ダイアログを表示する
void showBatteryDisplayDialog(BuildContext context, WidgetRef ref) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) {
      bool selected = ref.read(batteryDisplayProvider);
      final l10n = AppLocalizations.of(ctx)!;
      return StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: Text(l10n.batteryLevelDisplay, style: AppTextStyles.title),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<bool>(
                groupValue: selected,
                onChanged: (v) {
                  if (v == null) return;
                  setDialogState(() => selected = v);
                  handleBatteryDisplayChange(ref, v);
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (ctx.mounted) Navigator.pop(ctx);
                  });
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final option in [true, false]) ...[
                      if (!option) const SizedBox(height: 5),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setDialogState(() => selected = option);
                          handleBatteryDisplayChange(ref, option);
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (ctx.mounted) Navigator.pop(ctx);
                          });
                        },
                        child: SizedBox(
                          width: double.infinity,
                          child: Row(
                            children: [
                              Radio<bool>(
                                value: option,
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                option
                                    ? l10n.batteryLevelDisplayOn
                                    : l10n.batteryLevelDisplayOff,
                                style: AppTextStyles.label,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.batteryLevelDisplayIosNote,
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}

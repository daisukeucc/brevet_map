import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../utils/snackbar_utils.dart';

/// 画面スリープ設定を変更したときのハンドラ。
/// value: true=ON（端末スリープに従う）、false=OFF（WakeLockでスリープしない）
void handleScreenSleepChange(
  BuildContext context,
  WidgetRef ref,
  bool value,
) {
  ref.read(screenSleepProvider.notifier).state = value;
  saveScreenSleep(value);
  if (value) {
    WakelockPlus.disable();
  } else {
    WakelockPlus.enable();
  }
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  showAppSnackBar(context, value ? l10n.sleepOnMessage : l10n.sleepOffMessage);
}

/// 画面スリープ設定ダイアログを表示する。
/// ラジオボタン（ON/OFF）+ 説明文 + 設定アプリを開くボタンを表示する。
void showSleepSettingsDialog(BuildContext context, WidgetRef ref) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    barrierColor: Colors.black54,
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, __) {
      bool selected = ref.read(screenSleepProvider);
      final l10n = AppLocalizations.of(ctx)!;
      return StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          shape: const RoundedRectangleBorder(),
          title: Text(l10n.sleepSettings, style: AppTextStyles.title),
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
                  handleScreenSleepChange(ctx, ref, v);
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
                          handleScreenSleepChange(ctx, ref, option);
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
                                option ? l10n.sleepOn : l10n.sleepOff,
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
              const SizedBox(height: 24),
              Text(l10n.sleepSettingsNote, style: AppTextStyles.bodySmall),
              const SizedBox(height: 6),
              Center(
                child: TextButton(
                  onPressed: _openDeviceSettings,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    tapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  child: Text(
                    l10n.openSettingsApp,
                    style: AppTextStyles.button,
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _openDeviceSettings() async {
  if (Platform.isIOS) {
    final uri = Uri.parse('app-settings:');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  } else {
    // Android: display settings
    const intent = AndroidIntent(
      action: 'android.settings.DISPLAY_SETTINGS',
    );
    await intent.launch();
  }
}

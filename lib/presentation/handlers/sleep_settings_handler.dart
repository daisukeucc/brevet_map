import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
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

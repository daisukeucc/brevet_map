import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';

/// 画面スリープ設定を変更したときのハンドラ。
void handleSleepDurationChange(
  BuildContext context,
  WidgetRef ref,
  int minutes, {
  required void Function() restoreBrightness,
  required void Function(int) restartTimer,
}) {
  ref.read(sleepDurationProvider.notifier).state = minutes;
  saveSleepDuration(minutes);
  restoreBrightness();
  restartTimer(minutes);
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final message =
      minutes == 0 ? l10n.sleepOffMessage : l10n.sleepSetMessage(minutes);
  showAppSnackBar(context, message);
}

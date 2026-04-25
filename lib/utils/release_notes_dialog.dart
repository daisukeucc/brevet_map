import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../constants/app_constants.dart';
import '../data/repositories/first_launch_repository.dart';
import '../l10n/app_localizations.dart';
import '../presentation/theme/app_text_styles.dart';

/// [kReleaseNoteDialogVersionBuildIds] と l10n のキーを対応づける。
/// 新バージョン追加時: 定数・[AppLocalizations] の getter・ここに case を追加。
String? _messageForVersionBuild(
  AppLocalizations l10n,
  String versionBuildId,
) {
  switch (versionBuildId) {
    case '1.1.0+18':
      return l10n.releaseNotesV11018Message;
    default:
      return null;
  }
}

/// 条件を満たしたらリリースノートを1回だけ表示する（表示後 [saveLastShownReleaseNoteId]）。
Future<void> maybeShowReleaseNotesDialog(BuildContext context) async {
  if (!context.mounted) return;
  PackageInfo info;
  try {
    info = await PackageInfo.fromPlatform();
  } catch (_) {
    return;
  }
  final id = '${info.version}+${info.buildNumber}';
  if (!kReleaseNoteDialogVersionBuildIds.contains(id)) return;

  final last = await loadLastShownReleaseNoteId();
  if (last == id) return;
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context);
  if (l10n == null || !context.mounted) return;

  final body = _messageForVersionBuild(l10n, id);
  if (body == null || body.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
      title: SizedBox(
        width: double.infinity,
        child: Text(
          l10n.releaseNotesDialogTitle,
          style: AppTextStyles.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      content: SingleChildScrollView(
        child: Text(
          body,
          style: AppTextStyles.body.copyWith(height: 1.7),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.ok, style: AppTextStyles.button),
        ),
      ],
    ),
  );

  if (context.mounted) {
    await saveLastShownReleaseNoteId(id);
  }
}

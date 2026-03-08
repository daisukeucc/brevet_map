import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirm_dialog.dart';

/// GPX インポートのフローを実行する。
Future<void> showGpxImportFlow(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showConfirmDialog(
    context,
    message: l10n.routeOverwrite,
    cancelText: l10n.ng,
    confirmText: l10n.ok,
  );
  if (confirmed != true || !context.mounted) return;

  final result = await FilePicker.platform.pickFiles(type: FileType.any);
  if (result == null || result.files.single.path == null || !context.mounted) {
    return;
  }
  final path = result.files.single.path!;
  if (!path.toLowerCase().endsWith('.gpx')) {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.selectGpxFile);
    return;
  }

  final content = await File(path).readAsString();
  if (!context.mounted) return;

  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) => ref
            .read(cameraControllerProvider.notifier)
            .animateToBounds(bounds),
      );

  if (!context.mounted) return;
  _showGpxApplyErrorSnackBar(context, status);
}

/// GPX コンテンツを確認ダイアログ表示後に適用する。
/// 共有・チャネルから受け取った GPX 用。
Future<void> showConfirmAndApplyGpx(
  BuildContext context,
  WidgetRef ref,
  String content,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context,
    message: l10n.routeOverwrite,
    cancelText: l10n.ng,
    confirmText: l10n.ok,
  );
  if (confirmed != true || !context.mounted) return;

  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) => ref
            .read(cameraControllerProvider.notifier)
            .animateToBounds(bounds),
      );

  if (!context.mounted) return;
  _showGpxApplyErrorSnackBar(context, status);
}

void _showGpxApplyErrorSnackBar(BuildContext context, GpxApplyStatus status) {
  if (status == GpxApplyStatus.success) return;
  final l10n = AppLocalizations.of(context)!;
  final message = status == GpxApplyStatus.parseError
      ? l10n.gpxInvalidFormat
      : l10n.gpxNoRouteOrWaypoint;
  showAppSnackBar(context, message);
}

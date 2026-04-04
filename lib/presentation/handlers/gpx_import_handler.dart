import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/string_utils.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirm_dialog.dart';

/// GPX インポートのフローを実行する。
/// インポート成功時に [onSuccess] を呼ぶ。
Future<void> showGpxImportFlow(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onSuccess,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final confirmed = await showConfirmDialog(
    context,
    message: l10n.routeOverwrite,
    cancelText: l10n.cancel,
    confirmText: l10n.ok,
  );
  if (confirmed != true || !context.mounted) return;

  // withData: iOS の「ファイル」等では path が null になり得るが bytes は取れる
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
  );
  if (result == null || result.files.isEmpty || !context.mounted) return;

  final picked = result.files.single;
  final rawFilename = picked.path != null
      ? picked.path!.split(RegExp(r'[/\\]')).last
      : picked.name;

  if (!rawFilename.toLowerCase().endsWith('.gpx')) {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.selectGpxFile);
    return;
  }

  // ファイル名の全角（ローマ字・数字・スペース）を半角に変換してから読み込む
  String content;
  if (picked.path != null) {
    final path = picked.path!;
    final sourceFile = File(path);
    final normalizedFilename = toHalfwidthAscii(rawFilename);
    if (normalizedFilename == rawFilename) {
      content = await sourceFile.readAsString();
    } else {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$normalizedFilename');
      await sourceFile.copy(tempFile.path);
      try {
        content = await tempFile.readAsString();
      } finally {
        tempFile.deleteSync();
      }
    }
  } else if (picked.bytes != null) {
    content = utf8.decode(picked.bytes!, allowMalformed: true);
  } else {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.selectGpxFile);
    return;
  }
  if (!context.mounted) return;

  final filenameWithoutExt =
      rawFilename.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) =>
            ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
        importFilename: filenameWithoutExt,
      );

  if (!context.mounted) return;
  _showGpxApplyErrorSnackBar(context, status);
  if (status == GpxApplyStatus.success) onSuccess?.call();
}

/// GPX コンテンツを確認ダイアログ表示後に適用する。
/// 共有・チャネルから受け取った GPX 用。
Future<void> showConfirmAndApplyGpx(
  BuildContext context,
  WidgetRef ref,
  String content, {
  VoidCallback? onSuccess,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context,
    message: l10n.routeOverwrite,
    cancelText: l10n.cancel,
    confirmText: l10n.ok,
  );
  if (confirmed != true || !context.mounted) return;

  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) =>
            ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
      );

  if (!context.mounted) return;
  _showGpxApplyErrorSnackBar(context, status);
  if (status == GpxApplyStatus.success) onSuccess?.call();
}

void _showGpxApplyErrorSnackBar(BuildContext context, GpxApplyStatus status) {
  if (status == GpxApplyStatus.success) return;
  final l10n = AppLocalizations.of(context)!;
  final message = status == GpxApplyStatus.parseError
      ? l10n.gpxInvalidFormat
      : l10n.gpxNoRouteOrWaypoint;
  showAppSnackBar(context, message);
}

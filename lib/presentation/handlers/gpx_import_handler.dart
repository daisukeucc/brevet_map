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

bool _looksLikeGpxFilename(String name) =>
    name.toLowerCase().endsWith('.gpx');

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

  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    withData: true,
  );
  if (result == null || !context.mounted) return;

  final file = result.files.single;
  final path = file.path;
  if (path == null && (file.bytes == null || file.bytes!.isEmpty)) {
    return;
  }

  var rawFilename = file.name.trim();
  if (rawFilename.isEmpty && path != null) {
    rawFilename = path.split(RegExp(r'[/\\]')).last;
  }
  if (!_looksLikeGpxFilename(rawFilename) &&
      (path == null || !_looksLikeGpxFilename(path))) {
    if (!context.mounted) return;
    showAppSnackBar(context, l10n.selectGpxFile);
    return;
  }

  // ファイル名の全角（ローマ字・数字・スペース）を半角に変換してから読み込む
  final normalizedFilename = toHalfwidthAscii(rawFilename);
  String content;
  if (path != null) {
    final sourceFile = File(path);
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
  } else {
    content = utf8.decode(file.bytes!);
  }
  if (!context.mounted) return;

  final filenameWithoutExt =
      rawFilename.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) =>
            ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
        importFilename: filenameWithoutExt.isEmpty ? null : filenameWithoutExt,
      );

  if (!context.mounted) return;
  _showGpxApplyErrorSnackBar(context, status);
  if (status == GpxApplyStatus.success) onSuccess?.call();
}

/// 共有・チャネル・URL スキーム等から受け取った GPX を確認後に適用する。
/// [importBasename] は拡張子 `.gpx` を除いたベース名（ネイティブが分かる場合）。
Future<void> showConfirmAndApplyGpx(
  BuildContext context,
  WidgetRef ref,
  String content, {
  String? importBasename,
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

  final withoutExt = importBasename == null || importBasename.trim().isEmpty
      ? null
      : importBasename.replaceAll(RegExp(r'\.gpx$', caseSensitive: false), '');
  final status = await ref.read(mapStateProvider.notifier).applyImportedGpx(
        content,
        animateCamera: (bounds) =>
            ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
        importFilename: withoutExt != null && withoutExt.isNotEmpty ? withoutExt : null,
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

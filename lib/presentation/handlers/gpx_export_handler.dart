import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart' as downloads;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/services/gpx_export_service.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';

/// 日付（年月日時分秒）をファイル名用にフォーマット
String _defaultGpxFilename() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}'
      '${now.day.toString().padLeft(2, '0')}'
      '${now.hour.toString().padLeft(2, '0')}'
      '${now.minute.toString().padLeft(2, '0')}'
      '${now.second.toString().padLeft(2, '0')}';
}

/// ファイル名から .gpx 拡張子を除き、不正文字を除去
String _sanitizeFilename(String input) {
  var s = input.trim();
  if (s.toLowerCase().endsWith('.gpx')) {
    s = s.substring(0, s.length - 4);
  }
  s = s.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
  return s.isEmpty ? _defaultGpxFilename() : s;
}

/// ストレージパーミッションを要求（Android）
/// downloadsfolder は Android 29+ で MediaStore を使用するため権限不要。
/// Android 28 以下では WRITE_EXTERNAL_STORAGE が必要。
Future<bool> _requestStoragePermission() async {
  if (!Platform.isAndroid) return true;

  final status = await Permission.storage.request();
  if (status.isGranted) return true;

  if (status.isPermanentlyDenied) {
    await openAppSettings();
    return false;
  }
  // Android 29+ では storage は常に denied だが、downloadsfolder の MediaStore で保存可能なため続行
  return true;
}

/// GPXエクスポートフローを実行する。
/// ルートがなければ SnackBar で通知して何もしない。
Future<void> showGpxExportFlow(
  BuildContext context,
  WidgetRef ref,
) async {
  final l10n = AppLocalizations.of(context)!;
  final mapState = ref.read(mapStateProvider);

  final routePoints = mapState.fullRoutePoints ?? mapState.savedRoutePoints;
  if (routePoints == null || routePoints.isEmpty) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.routeNotLoaded)),
    );
    return;
  }

  // パーミッション確認
  final hasPermission = await _requestStoragePermission();
  if (!hasPermission && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.gpxExportPermissionDenied)),
    );
    return;
  }

  if (!context.mounted) return;

  // ファイル名入力フォーム
  final filename = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _GpxExportFilenameDialog(
      defaultFilename: _defaultGpxFilename(),
      l10n: l10n,
    ),
  );

  if (filename == null || !context.mounted) return;

  final sanitized = _sanitizeFilename(filename);
  final displayFilename = '$sanitized.gpx';
  final gpxXml = buildGpxXml(
    trackPoints: routePoints,
    gpxPois: mapState.gpxPois,
    userPois: mapState.userPois,
    filename: sanitized, // metadata/trk/wpt の name には拡張子を含めない
  );

  try {
    if (Platform.isAndroid) {
      // Android: MediaStore で端末のダウンロードフォルダに保存（拡張子付き）
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$displayFilename');
      await tempFile.writeAsString(gpxXml);

      var success = false;
      try {
        const channel = MethodChannel('com.example.brevet_map/gpx');
        success = await channel.invokeMethod<bool?>(
              'saveFileToDownloads',
              {'filePath': tempFile.path, 'fileName': displayFilename},
            ) ==
            true;
      } on PlatformException catch (_) {
        // API 29 未満などでフォールバック
      }
      if (!success) {
        success = await downloads.copyFileIntoDownloadFolder(
                tempFile.path, displayFilename) ==
            true;
      }

      try {
        await tempFile.delete();
      } catch (_) {}

      if (!context.mounted) return;
      if (success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gpxExportComplete(displayFilename))),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.gpxExportFailed)),
        );
      }
    } else {
      // iOS: アプリのドキュメントフォルダ（UIFileSharingEnabled で「ファイル」アプリからアクセス可能）
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$displayFilename');
      await file.writeAsString(gpxXml);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.gpxExportComplete(displayFilename))),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.gpxExportFailed)),
    );
  }
}

class _GpxExportFilenameDialog extends StatefulWidget {
  const _GpxExportFilenameDialog({
    required this.defaultFilename,
    required this.l10n,
  });

  final String defaultFilename;
  final AppLocalizations l10n;

  @override
  State<_GpxExportFilenameDialog> createState() =>
      _GpxExportFilenameDialogState();
}

class _GpxExportFilenameDialogState extends State<_GpxExportFilenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.defaultFilename.replaceAll('.gpx', ''),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compactButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      title: Text(widget.l10n.gpxExportDialogTitle, style: AppTextStyles.title),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.defaultFilename,
          border: const OutlineInputBorder(),
          suffixText: '.gpx',
        ),
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.l10n.cancel, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: _submit,
          child: Text(widget.l10n.ok, style: AppTextStyles.button),
        ),
      ],
    );
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text.isEmpty ? widget.defaultFilename : text);
  }
}

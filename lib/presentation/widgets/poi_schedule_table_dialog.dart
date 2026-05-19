import 'dart:async' show unawaited;
import 'dart:convert' show utf8;
import 'dart:io';

import 'package:downloadsfolder/downloadsfolder.dart' as downloads;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart' show AppTextStyles;

/// テーブルダイアログに渡す1行分のデータ。
class PoiScheduleRow {
  const PoiScheduleRow({
    required this.distance,
    required this.name,
    required this.arrival,
    required this.checkInResultUtc,
    this.startClose,
  });

  final String? distance;
  final String? name;
  final DateTime? arrival;
  final DateTime? checkInResultUtc;

  /// Start POI は出発予定時刻、それ以外はクローズ時刻。
  final DateTime? startClose;
}

/// POI 通過記録テーブルダイアログ。
class PoiScheduleTableDialog extends StatefulWidget {
  const PoiScheduleTableDialog({
    super.key,
    required this.rows,
    this.distanceUnit = 0,
    this.highlightIndex,
    this.showDownloadButton = false,
  });

  final List<PoiScheduleRow> rows;

  /// 0=km, 1=mi（[formatDistance] と同じ）。距離列ヘッダーに反映する。
  final int distanceUnit;

  /// 背景をグレーにする行インデックス（現在表示中の POI）。
  final int? highlightIndex;

  /// true のとき CSV ダウンロードボタンを表示する（Start/Goal POI シートのみ）。
  final bool showDownloadButton;

  @override
  State<PoiScheduleTableDialog> createState() => _PoiScheduleTableDialogState();
}

class _PoiScheduleTableDialogState extends State<PoiScheduleTableDialog> {
  bool _isDownloading = false;

  static String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length <= 6 ? s : '${s.substring(0, 6)}...';
  }

  void _showFullName(BuildContext ctx, String name) {
    showDialog<void>(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          child: Text(name,
              style: TextStyle(
                  fontSize: 16, color: Colors.black87.withValues(alpha: 0.7))),
        ),
      ),
    );
  }

  static String _fmtTime(DateTime dt, String locale) {
    final local = dt.toLocal();
    final date = DateFormat.Md(locale).format(local);
    final time = DateFormat.Hm(locale).format(local);
    return '$date $time';
  }

  static String _ahead(DateTime arrival, DateTime result) {
    final d = arrival.difference(result);
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return d.isNegative ? '- $h:$m' : '+ $h:$m';
  }

  static String _csvField(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _buildCsv(String locale) {
    final distLabel = widget.distanceUnit == 1 ? 'mi' : 'km';
    final header = [
      distLabel,
      'point',
      'arrival',
      'result',
      'ahead',
      'start/close'
    ];
    final lines = <String>[header.join(',')];
    for (final r in widget.rows) {
      final arr = r.arrival;
      final res = r.checkInResultUtc;
      final sc = r.startClose;
      lines.add([
        _csvField(r.distance ?? ''),
        _csvField(r.name ?? ''),
        _csvField(arr != null ? _fmtTime(arr, locale) : ''),
        _csvField(res != null ? _fmtTime(res, locale) : ''),
        _csvField((arr != null && res != null) ? _ahead(arr, res) : ''),
        _csvField(sc != null ? _fmtTime(sc, locale) : ''),
      ].join(','));
    }
    return lines.join('\n');
  }

  static String _csvFilename(String? gpxBasename) {
    if (gpxBasename == null || gpxBasename.trim().isEmpty) {
      final now = DateTime.now();
      final ts =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      return 'schedule_$ts.csv';
    }
    var s = gpxBasename.trim();
    if (s.toLowerCase().endsWith('.gpx')) s = s.substring(0, s.length - 4);
    s = s.replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
    if (s.isEmpty) {
      final now = DateTime.now();
      s = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    }
    return '$s.csv';
  }

  Future<void> _download() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    final locale = Localizations.localeOf(context).toString();
    final csvContent = _buildCsv(locale);
    final gpxBasename = await loadGpxImportBasename();
    final filename = _csvFilename(gpxBasename);

    if (!mounted) return;

    try {
      if (Platform.isAndroid) {
        final tempDir = await getTemporaryDirectory();
        final dir = Directory(
            '${tempDir.path}/csv_${DateTime.now().microsecondsSinceEpoch}');
        await dir.create(recursive: false);
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(utf8.encode(csvContent));

        var saved = false;
        try {
          const ch = MethodChannel('com.brevetmap/gpx');
          saved = await ch.invokeMethod<bool?>(
                'saveFileToDownloads',
                {'filePath': file.path, 'fileName': filename},
              ) ==
              true;
        } on PlatformException catch (_) {}
        if (!saved) {
          saved =
              await downloads.copyFileIntoDownloadFolder(file.path, filename) ==
                  true;
        }

        if (!mounted) return;
        try {
          await Share.shareXFiles([
            XFile(file.path, mimeType: 'text/csv', name: filename),
          ]);
        } catch (_) {}

        unawaited(Future<void>.delayed(const Duration(minutes: 10), () async {
          try {
            if (await dir.exists()) await dir.delete(recursive: true);
          } catch (_) {}
        }));
      } else {
        // iOS
        final docsDir = await getApplicationDocumentsDirectory();
        final file = File('${docsDir.path}/$filename');
        await file.writeAsBytes(utf8.encode(csvContent));

        if (!mounted) return;
        try {
          final tempDir = await getTemporaryDirectory();
          final shareDir = Directory(
              '${tempDir.path}/csv_${DateTime.now().microsecondsSinceEpoch}');
          await shareDir.create(recursive: false);
          final copy = await file.copy('${shareDir.path}/$filename');
          await Share.shareXFiles(
            [XFile(copy.path, mimeType: 'text/csv', name: filename)],
            sharePositionOrigin:
                Rect.fromPoints(const Offset(0, 0), const Offset(1, 1)),
          );
          unawaited(Future<void>.delayed(const Duration(minutes: 10), () async {
            try {
              if (await shareDir.exists()) {
                await shareDir.delete(recursive: true);
              }
            } catch (_) {}
          }));
        } catch (_) {}
      }
    } catch (_) {
      // サイレントに握り潰す（エクスポート失敗は共有シートのキャンセルも含む）
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    const ts = TextStyle(fontSize: 14, color: Colors.black87);
    const th = TextStyle(fontSize: 13, color: Colors.black54);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 5, 20, 10),
              child:
                  Text(l10n.poiScheduleTableTitle, style: AppTextStyles.title),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    columnSpacing: 20,
                    horizontalMargin: 20,
                    dividerThickness: 0.5,
                    headingRowColor: WidgetStateProperty.all(
                        Colors.black.withValues(alpha: 0.04)),
                    columns: [
                      DataColumn(
                          label: Text(widget.distanceUnit == 1 ? 'mi' : 'km',
                              style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColPoint, style: th)),
                      DataColumn(label: Text(l10n.arrivalShort, style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColResult, style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColAhead, style: th)),
                      DataColumn(
                          label:
                              Text(l10n.poiScheduleColStartClose, style: th)),
                    ],
                    rows: widget.rows.indexed.map((entry) {
                      final i = entry.$1;
                      final r = entry.$2;
                      final arr = r.arrival;
                      final res = r.checkInResultUtc;
                      final sc = r.startClose;
                      final isHighlight = widget.highlightIndex == i;
                      return DataRow(
                        color: isHighlight
                            ? WidgetStateProperty.all(
                                Colors.black.withValues(alpha: 0.06))
                            : null,
                        cells: [
                          DataCell(Text(r.distance ?? '--', style: ts)),
                          DataCell(
                            Text(_short(r.name), style: ts),
                            onTap: r.name != null
                                ? () => _showFullName(context, r.name!)
                                : null,
                          ),
                          DataCell(Text(
                              arr != null ? _fmtTime(arr, locale) : '--',
                              style: ts)),
                          DataCell(Text(
                              res != null ? _fmtTime(res, locale) : '--',
                              style: ts)),
                          DataCell(Text(
                            (arr != null && res != null)
                                ? _ahead(arr, res)
                                : '--',
                            style: ts,
                          )),
                          DataCell(Text(
                              sc != null ? _fmtTime(sc, locale) : '--',
                              style: ts)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.showDownloadButton)
                    TextButton(
                      onPressed: _isDownloading ? null : _download,
                      child:
                          Text(l10n.csvDownload, style: AppTextStyles.button),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                        Text(l10n.trialInfoClose, style: AppTextStyles.button),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

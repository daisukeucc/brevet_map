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

const _kThStyle = TextStyle(fontSize: 13, color: Colors.black54);

/// テーブルダイアログに渡す1行分のデータ。
class PoiScheduleRow {
  const PoiScheduleRow({
    required this.distance,
    required this.name,
    required this.arrival,
    required this.checkInResultUtc,
    this.segmentDistanceKm,
    this.elevationGain,
    this.departure,
    this.restUtc,
    this.startClose,
  });

  final String? distance;
  final String? name;

  /// 到着予定時刻（UTC）。
  final DateTime? arrival;

  /// 到着実績時刻（UTC）（チェックイン時刻）。
  final DateTime? checkInResultUtc;

  /// 区間距離（km）。distanceUnit に関わらず km で渡す。
  final double? segmentDistanceKm;

  /// 獲得標高（整形済み文字列）。
  final String? elevationGain;

  /// 出発予定時刻（UTC）。
  final DateTime? departure;

  /// 出発実績時刻（UTC）（チェックアウト時刻 = rest）。
  final DateTime? restUtc;

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
  int? _tappedIndex;

  static String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length <= 7 ? s : '${s.substring(0, 7)}...';
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
    return (d.isNegative && abs.inMinutes > 0) ? '- $h:$m' : '+ $h:$m';
  }

  static String _fmtElapsed(Duration d) {
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 前のPOIの出発実績（なければ出発予定）と現在の到着実績の差。
  Duration? _computeElapsed(int i) {
    if (i == 0) return null;
    final current = widget.rows[i].checkInResultUtc;
    if (current == null) return null;
    final prev = widget.rows[i - 1];
    final prevRef = prev.restUtc ?? prev.departure;
    if (prevRef == null) return null;
    return current.difference(prevRef);
  }

  String _fmtSpeed(double? segKm, Duration? elapsed) {
    if (segKm == null || elapsed == null) return '--';
    final seconds = elapsed.inSeconds;
    if (seconds <= 0) return '--';
    final hours = seconds / 3600.0;
    final dist = widget.distanceUnit == 1 ? segKm / 1.60934 : segKm;
    final speed = dist / hours;
    final unit = widget.distanceUnit == 1 ? 'mph' : 'km/h';
    return '${speed.toStringAsFixed(1)} $unit';
  }

  String _fmtSegDist(double? km) {
    if (km == null) return '--';
    if (widget.distanceUnit == 1) {
      return '${(km / 1.60934).toStringAsFixed(1)} mi';
    }
    return '${km.toStringAsFixed(1)} km';
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
      'ETA',
      'ATA',
      'ETD',
      'ATD',
      'diff',
      'dist',
      'elev',
      'elapsed',
      'avg spd',
      'open/close',
    ];
    final lines = <String>[header.join(',')];
    for (var i = 0; i < widget.rows.length; i++) {
      final r = widget.rows[i];
      final arr = r.arrival;
      final res = r.checkInResultUtc;
      final dep = r.departure;
      final rest = r.restUtc;
      final sc = r.startClose;
      final elapsed = _computeElapsed(i);
      final speedStr = _fmtSpeed(r.segmentDistanceKm, elapsed);
      lines.add([
        _csvField(r.distance ?? ''),
        _csvField(r.name ?? ''),
        _csvField(arr != null ? _fmtTime(arr, locale) : ''),
        _csvField(res != null ? _fmtTime(res, locale) : ''),
        _csvField(dep != null ? _fmtTime(dep, locale) : ''),
        _csvField(rest != null ? _fmtTime(rest, locale) : ''),
        _csvField((rest != null && dep != null)
            ? _ahead(dep, rest)
            : (arr != null && res != null)
                ? _ahead(arr, res)
                : ''),
        _csvField(r.segmentDistanceKm != null
            ? _fmtSegDist(r.segmentDistanceKm)
            : ''),
        _csvField(r.elevationGain ?? ''),
        _csvField(elapsed != null ? _fmtElapsed(elapsed) : ''),
        _csvField(speedStr == '--' ? '' : speedStr),
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
    final isJa = locale.startsWith('ja');

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
                    showCheckboxColumn: false,
                    headingRowHeight: 40,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 40,
                    columnSpacing: 16,
                    horizontalMargin: 16,
                    dividerThickness: 0.5,
                    headingRowColor: WidgetStateProperty.all(
                        Colors.black.withValues(alpha: 0.04)),
                    columns: [
                      DataColumn(
                          label: Text(widget.distanceUnit == 1 ? 'mi' : 'km',
                              style: _kThStyle)),
                      DataColumn(
                          label:
                              Text(isJa ? 'ポイント' : 'point', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '到着予定' : 'ETA', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '到着実績' : 'ATA', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '出発予定' : 'ETD', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '出発実績' : 'ATD', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '貯金' : 'diff', style: _kThStyle)),
                      DataColumn(
                          label:
                              Text(isJa ? '区間距離' : 'dist', style: _kThStyle)),
                      DataColumn(
                          label:
                              Text(isJa ? '獲得標高' : 'elev', style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '経過時間' : 'elapsed',
                              style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '区間時速' : 'avg spd',
                              style: _kThStyle)),
                      const DataColumn(
                          label: Text('open/close', style: _kThStyle)),
                    ],
                    rows: widget.rows.indexed.map((entry) {
                      final i = entry.$1;
                      final r = entry.$2;
                      final arr = r.arrival;
                      final res = r.checkInResultUtc;
                      final dep = r.departure;
                      final rest = r.restUtc;
                      final sc = r.startClose;
                      final isHighlight = _tappedIndex == null
                          ? widget.highlightIndex == i
                          : _tappedIndex == i;
                      final elapsed = _computeElapsed(i);
                      return DataRow(
                        onSelectChanged: (_) =>
                            setState(() => _tappedIndex = i),
                        color: isHighlight
                            ? WidgetStateProperty.all(
                                Colors.black.withValues(alpha: 0.06))
                            : null,
                        cells: [
                          DataCell(Text(r.distance ?? '--', style: ts)),
                          DataCell(
                            Text(_short(r.name), style: ts),
                            onTap: r.name != null && r.name!.length > 7
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
                              dep != null ? _fmtTime(dep, locale) : '--',
                              style: ts)),
                          DataCell(Text(
                              rest != null ? _fmtTime(rest, locale) : '--',
                              style: ts)),
                          DataCell(Text(
                            (rest != null && dep != null)
                                ? _ahead(dep, rest)
                                : (arr != null && res != null)
                                    ? _ahead(arr, res)
                                    : '--',
                            style: ts,
                          )),
                          DataCell(Text(_fmtSegDist(r.segmentDistanceKm),
                              style: ts)),
                          DataCell(Text(r.elevationGain ?? '--', style: ts)),
                          DataCell(Text(
                              elapsed != null ? _fmtElapsed(elapsed) : '--',
                              style: ts)),
                          DataCell(Text(_fmtSpeed(r.segmentDistanceKm, elapsed),
                              style: ts)),
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

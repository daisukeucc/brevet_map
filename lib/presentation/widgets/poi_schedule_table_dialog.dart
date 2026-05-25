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
    this.cumulativeDistanceKm,
    this.elevationGain,
    this.rawElevationGainM,
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

  /// スタートからの累積距離（km）。チェックインされていない POI をスキップして遡る際に使う。
  final double? cumulativeDistanceKm;

  /// 獲得標高（整形済み文字列）。
  final String? elevationGain;

  /// 区間獲得標高（メートル値）。未チェックイン POI をスキップして合算するために使う。
  final double? rawElevationGainM;

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

  /// チェックイン済み（または Start）の直近行インデックスを i より手前で探す。
  /// 未チェックインの CP はスキップする。見つからなければ null。
  int? _findRefIndex(int i) {
    for (var j = i - 1; j >= 0; j--) {
      final r = widget.rows[j];
      // チェックイン or チェックアウト済み → 信頼できる通過時刻あり
      if (r.checkInResultUtc != null || r.restUtc != null) return j;
      // Start POI（arrival == null）→ 計画出発時刻 = ブルベ開始時刻として信頼できる
      if (r.arrival == null) return j;
    }
    return null;
  }

  /// 前の（または遡った）POI の出発実績（なければ出発予定）と現在の到着実績の差。
  /// 直前の POI が未チェックインの場合は、直近のチェックイン済み POI まで遡る。
  Duration? _computeElapsed(int i) {
    if (i == 0) return null;
    final current = widget.rows[i].checkInResultUtc;
    if (current == null) return null;
    final refIdx = _findRefIndex(i);
    if (refIdx == null) return null;
    final ref = widget.rows[refIdx];
    final refTime = ref.restUtc ?? ref.departure;
    if (refTime == null) return null;
    return current.difference(refTime);
  }

  /// 経過時間の基準行から現在行までの獲得標高合計（メートル）。
  /// 未チェックインの POI をスキップして合算する。
  double? _effectiveRawElevGainM(int i) {
    if (i == 0) return null;
    final refIdx = _findRefIndex(i);
    if (refIdx == null) return null;
    double sum = 0;
    bool hasAny = false;
    for (var j = refIdx + 1; j <= i; j++) {
      final g = widget.rows[j].rawElevationGainM;
      if (g != null) {
        sum += g;
        hasAny = true;
      }
    }
    return hasAny ? sum : null;
  }

  /// 獲得標高メートル値を表示用文字列（単位なし）に変換する。
  String _fmtElevGain(double? meters) {
    if (meters == null) return '--';
    if (widget.distanceUnit == 1) {
      return (meters / 0.3048).round().toString();
    }
    return meters.round().toString();
  }

  /// 経過時間の基準行から現在行までの累積距離差（区間距離・速度計算に使う）。
  /// 直前行が未チェックインの場合は遡った基準行から計算する。
  double? _effectiveSegKm(int i) {
    if (i == 0) return null;
    final refIdx = _findRefIndex(i);
    if (refIdx == null) return widget.rows[i].segmentDistanceKm;
    if (refIdx == i - 1) return widget.rows[i].segmentDistanceKm;
    final refCum = widget.rows[refIdx].cumulativeDistanceKm;
    final currCum = widget.rows[i].cumulativeDistanceKm;
    if (refCum == null || currCum == null || currCum < refCum) return null;
    return currCum - refCum;
  }

  String _fmtSpeed(double? segKm, Duration? elapsed) {
    if (segKm == null || elapsed == null) return '--';
    final seconds = elapsed.inSeconds;
    if (seconds <= 0) return '--';
    final hours = seconds / 3600.0;
    final dist = widget.distanceUnit == 1 ? segKm / 1.60934 : segKm;
    final speed = dist / hours;
    return speed.toStringAsFixed(1);
  }

  /// "125.3km" → "125.3"、"1250m" → "1250" のように末尾の単位文字列を除去する。
  /// スペースあり ("125.3 km") もなし ("125.3km") も対応。
  static String _numOnly(String? s) {
    if (s == null || s.isEmpty) return '--';
    return s.replaceAll(RegExp(r'\s*[a-zA-Z]+$'), '');
  }

  String _fmtSegDist(double? km) {
    if (km == null) return '--';
    if (widget.distanceUnit == 1) {
      return (km / 1.60934).toStringAsFixed(1);
    }
    return km.toStringAsFixed(1);
  }

  static String _csvField(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  String _buildCsv(String locale) {
    final distLabel = 'dist(${widget.distanceUnit == 1 ? 'mi' : 'km'})';
    final speedLabel = widget.distanceUnit == 1 ? 'mph' : 'km/h';
    final segLabel = 'seg(${widget.distanceUnit == 1 ? 'mi' : 'km'})';
    final elevLabel = 'elev(${widget.distanceUnit == 1 ? 'ft' : 'm'})';
    final header = [
      distLabel,
      'point',
      'ETA',
      'ATA',
      'ETD',
      'ATD',
      'elapsed',
      speedLabel,
      'diff',
      segLabel,
      elevLabel,
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
      final effSegKm = _effectiveSegKm(i);
      final speedStr = _fmtSpeed(effSegKm, elapsed);
      lines.add([
        _csvField(_numOnly(r.distance)),
        _csvField(r.name ?? ''),
        _csvField(arr != null ? _fmtTime(arr, locale) : ''),
        _csvField(res != null ? _fmtTime(res, locale) : ''),
        _csvField(dep != null ? _fmtTime(dep, locale) : ''),
        _csvField(rest != null ? _fmtTime(rest, locale) : ''),
        _csvField(elapsed != null ? _fmtElapsed(elapsed) : ''),
        _csvField(speedStr == '--' ? '' : speedStr),
        _csvField((rest != null && dep != null)
            ? _ahead(dep, rest)
            : (arr != null && res != null)
                ? _ahead(arr, res)
                : ''),
        _csvField(res != null && effSegKm != null ? _fmtSegDist(effSegKm) : ''),
        _csvField(res != null ? _fmtElevGain(_effectiveRawElevGainM(i)) : ''),
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
                          label: Text(
                              isJa
                                  ? '距離(${widget.distanceUnit == 1 ? 'mi' : 'km'})'
                                  : 'dist(${widget.distanceUnit == 1 ? 'mi' : 'km'})',
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
                          label: Text(isJa ? '経過時間' : 'elapsed',
                              style: _kThStyle)),
                      DataColumn(
                          label: Text(
                              widget.distanceUnit == 1 ? 'mph' : 'km/h',
                              style: _kThStyle)),
                      DataColumn(
                          label: Text(isJa ? '差分' : 'diff',
                              style: _kThStyle)),
                      DataColumn(
                          label: Text(
                              isJa
                                  ? '区間(${widget.distanceUnit == 1 ? 'mi' : 'km'})'
                                  : 'seg(${widget.distanceUnit == 1 ? 'mi' : 'km'})',
                              style: _kThStyle)),
                      DataColumn(
                          label: Text(
                              isJa
                                  ? '標高(${widget.distanceUnit == 1 ? 'ft' : 'm'})'
                                  : 'elev(${widget.distanceUnit == 1 ? 'ft' : 'm'})',
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
                      final effSegKm = _effectiveSegKm(i);
                      return DataRow(
                        onSelectChanged: (_) =>
                            setState(() => _tappedIndex = i),
                        color: isHighlight
                            ? WidgetStateProperty.all(
                                Colors.black.withValues(alpha: 0.06))
                            : null,
                        cells: [
                          DataCell(Text(_numOnly(r.distance), style: ts)),
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
                              elapsed != null ? _fmtElapsed(elapsed) : '--',
                              style: ts)),
                          DataCell(Text(_fmtSpeed(effSegKm, elapsed),
                              style: ts)),
                          DataCell(Text(
                            (rest != null && dep != null)
                                ? _ahead(dep, rest)
                                : (arr != null && res != null)
                                    ? _ahead(arr, res)
                                    : '--',
                            style: ts,
                          )),
                          DataCell(Text(
                              res != null ? _fmtSegDist(effSegKm) : '--',
                              style: ts)),
                          DataCell(Text(
                              res != null
                                  ? _fmtElevGain(_effectiveRawElevGainM(i))
                                  : '--',
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

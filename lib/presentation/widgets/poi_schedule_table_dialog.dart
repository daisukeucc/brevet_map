import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart' show AppTextStyles;

/// テーブルダイアログに渡す1行分のデータ。
class PoiScheduleRow {
  const PoiScheduleRow({
    required this.distance,
    required this.name,
    required this.arrival,
    required this.checkInResultUtc,
  });

  final String? distance;
  final String? name;
  final DateTime? arrival;
  final DateTime? checkInResultUtc;
}

/// POI 通過記録テーブルダイアログ。
class PoiScheduleTableDialog extends StatelessWidget {
  const PoiScheduleTableDialog({
    super.key,
    required this.rows,
    this.distanceUnit = 0,
  });

  final List<PoiScheduleRow> rows;

  /// 0=km, 1=mi（[formatDistance] と同じ）。距離列ヘッダーに反映する。
  final int distanceUnit;

  static String _short(String? s) {
    if (s == null || s.isEmpty) return '-';
    return s.length <= 6 ? s : '${s.substring(0, 6)}...';
  }

  static String _fmtTime(DateTime dt, String locale) =>
      DateFormat('M/d H:mm', locale).format(dt.toLocal());

  static String _ahead(DateTime arrival, DateTime result) {
    final d = arrival.difference(result);
    final abs = d.abs();
    final h = abs.inHours.toString().padLeft(2, '0');
    final m = (abs.inMinutes % 60).toString().padLeft(2, '0');
    return d.isNegative ? '- $h:$m' : '+ $h:$m';
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
                          label:
                              Text(distanceUnit == 1 ? 'mi' : 'km', style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColPoint, style: th)),
                      DataColumn(label: Text(l10n.arrivalShort, style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColResult, style: th)),
                      DataColumn(
                          label: Text(l10n.poiScheduleColAhead, style: th)),
                    ],
                    rows: rows.map((r) {
                      final arr = r.arrival;
                      final res = r.checkInResultUtc;
                      return DataRow(cells: [
                        DataCell(Text(r.distance ?? '--', style: ts)),
                        DataCell(Text(_short(r.name), style: ts)),
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
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.trialInfoClose, style: AppTextStyles.button),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

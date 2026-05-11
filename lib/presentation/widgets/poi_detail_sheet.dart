import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../theme/app_text_styles.dart';

/// POIシートタップ時に [buildElevationSegmentChartData] でグラフを構築するための入力。
class PoiElevationOnDemand {
  const PoiElevationOnDemand({
    required this.trackPoints,
    required this.elevations,
    required this.poiPositions,
    required this.poiIndex,
    required this.distanceUnit,
    this.poiHasDistanceKm,
    this.chartMetadataName,
    this.chartTimeLimitHours,
  });

  final List<LatLng> trackPoints;
  final List<double?> elevations;
  final List<LatLng> poiPositions;
  final int poiIndex;

  /// [formatDistance] と同じ。0=km/m、1=mi/ft。
  final int distanceUnit;

  /// [poiPositions] と同長のとき、距離未登録（false）POI は標高区間から除外する（User POI 用）。
  final List<bool>? poiHasDistanceKm;

  /// スタート POI の標高ダイアログ内、グラフ直上：インポート GPX のファイル名ベース（`<metadata><name>` ではない）
  final String? chartMetadataName;

  /// スタート POI の標高ダイアログ内、グラフ直上：ブルベ制限時間（時間）。`null` や `<=0` は時間行を出さない。
  final double? chartTimeLimitHours;
}

String? _formatElevationChartTimeLimitHours(double? hours) {
  if (hours == null || hours <= 0 || !hours.isFinite) return null;
  return hours == hours.roundToDouble()
      ? hours.toInt().toString()
      : hours.toStringAsFixed(1);
}

/// POI 詳細1件（ボトムシート用）
class PoiSheetEntry {
  const PoiSheetEntry({
    required this.name,
    required this.description,
    this.url,
    required this.position,
    this.distance,
    this.elevationGain,
    this.arrival,
    this.departure,
    this.close,
    this.elevationSegment,
    this.segmentDistanceLabel,
    this.elevationOnDemand,
    this.distanceUnit = 0,
    this.isRouteStartPoi = true,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final String? url;
  final LatLng position;

  /// スケジュール：到着時刻（UTC）
  final DateTime? arrival;

  /// スケジュール：出発時刻（UTC）
  final DateTime? departure;

  /// スケジュール：クローズ時刻（UTC）
  final DateTime? close;

  /// ルートが読み込まれているとき「直前地点〜このPOI」の標高グラフデータ。
  final ElevationSegmentChartData? elevationSegment;

  /// [elevationSegment] の距離を表示用に整形した文字列（単位付き）。
  final String? segmentDistanceLabel;

  /// 事前計算しない場合、標高グラフアイコンタップ時にプロファイルを構築する。
  final PoiElevationOnDemand? elevationOnDemand;

  /// [formatDistance] と同じ。0=km/m、1=mi/ft。
  final int distanceUnit;

  /// ルート上の並びで最初の POI（スタート）。スタートでは獲得 0 でも標高行を表示する。
  final bool isRouteStartPoi;
}

double? _effectiveElevationGainMeters({
  required String? elevationGainDisplay,
  required ElevationSegmentChartData? elevationSegment,
}) {
  final fromSeg = elevationSegment?.segmentElevationGainM;
  if (fromSeg != null) return fromSeg;
  if (elevationGainDisplay == null || elevationGainDisplay.isEmpty) return null;
  return parseElevationChangeDisplayToMeters(elevationGainDisplay);
}

bool _shouldShowElevationGainIcon({
  required bool isRouteStartPoi,
  required String elevationGainDisplay,
  required ElevationSegmentChartData? elevationSegment,
}) {
  if (isRouteStartPoi) return false;
  final m = _effectiveElevationGainMeters(
    elevationGainDisplay: elevationGainDisplay,
    elevationSegment: elevationSegment,
  );
  if (m == null) return true;
  return m > 0.5;
}

/// オーバーレイ無しの標高ダイアログ用。周囲に軽いシャドウのみ付与する。
Widget _elevationDialogPanel({
  required EdgeInsetsGeometry padding,
  required Widget child,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 14,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: Padding(padding: padding, child: child),
  );
}

void _openElevationFromOnDemand(
  BuildContext context,
  PoiElevationOnDemand req,
) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => _ElevationOnDemandDialog(req: req),
  );
}

/// POIシートタップ時に表示するダイアログ。
/// ダイアログ表示後 isolate でデータを構築し、ローディング → グラフへ切り替える。
class _ElevationOnDemandDialog extends StatefulWidget {
  const _ElevationOnDemandDialog({required this.req});
  final PoiElevationOnDemand req;

  @override
  State<_ElevationOnDemandDialog> createState() =>
      _ElevationOnDemandDialogState();
}

class _ElevationOnDemandDialogState extends State<_ElevationOnDemandDialog> {
  ElevationSegmentChartData? _chart;
  bool _loading = true;
  String? _previewDistLabel;
  String? _previewGainLabel;
  String? _previewLossLabel;

  @override
  void initState() {
    super.initState();
    final req = widget.req;
    final alignedElev = req.elevations.length == req.trackPoints.length
        ? req.elevations
        : List<double?>.filled(req.trackPoints.length, null);
    final m = elevationSegmentMetricsPreview(
      trackPoints: req.trackPoints,
      elevations: alignedElev,
      poiPositions: req.poiPositions,
      poiIndex: req.poiIndex,
      poiHasDistanceKm: req.poiHasDistanceKm,
    );
    if (m != null) {
      _previewDistLabel = formatDistance(m.segmentKm, req.distanceUnit);
      _previewGainLabel = formatElevationChange(m.gainM, req.distanceUnit);
      _previewLossLabel = formatElevationChange(m.lossM, req.distanceUnit);
    }
    _buildChart();
  }

  Future<void> _buildChart() async {
    try {
      final req = widget.req;
      final chart = await compute(
        computeElevationSegmentChartData,
        (
          trackPoints: req.trackPoints,
          elevations: req.elevations.length == req.trackPoints.length
              ? req.elevations
              : List<double?>.filled(req.trackPoints.length, null),
          poiPositions: req.poiPositions,
          poiIndex: req.poiIndex,
          maxSamples: 450,
          poiHasDistanceKm: req.poiHasDistanceKm,
        ),
      ).timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw TimeoutException(
          'computeElevationSegmentChartData',
          const Duration(seconds: 45),
        ),
      );
      if (!mounted) return;
      if (chart == null || !chart.hasElevation) {
        Navigator.of(context).maybePop();
        return;
      }
      try {
        setState(() {
          _chart = chart;
          _loading = false;
        });
      } catch (e, st) {
        debugPrint('Elevation chart setState failed: $e\n$st');
        if (!mounted) return;
        Navigator.of(context).maybePop();
      }
    } catch (e, st) {
      debugPrint('Elevation chart compute failed: $e\n$st');
      if (!mounted) return;
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chart = _chart;
    final req = widget.req;
    final showChart = !_loading && chart != null;

    final distText = showChart
        ? formatDistance(chart.segmentKm, req.distanceUnit)
        : (_previewDistLabel ?? '—');
    final gainText = showChart
        ? formatElevationChange(chart.segmentElevationGainM, req.distanceUnit)
        : (_previewGainLabel ?? '—');
    final lossText = showChart
        ? formatElevationChange(chart.segmentElevationLossM, req.distanceUnit)
        : (_previewLossLabel ?? '—');

    final elevHeaderName = req.chartMetadataName?.trim();
    final elevHeaderHoursStr =
        _formatElevationChartTimeLimitHours(req.chartTimeLimitHours);
    final showElevDialogHeader =
        (elevHeaderName != null && elevHeaderName.isNotEmpty) ||
            elevHeaderHoursStr != null;
    final elevTimeLabel = AppLocalizations.of(context)?.brevetTimeLimitLabel;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      content: _elevationDialogPanel(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showElevDialogHeader) ...[
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (elevHeaderName != null && elevHeaderName.isNotEmpty)
                        Text(
                          elevHeaderName,
                          style: AppTextStyles.poiMedium,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (elevHeaderHoursStr != null) const SizedBox(height: 4),
                      Text(
                        '${elevTimeLabel ?? 'Time limit'} ${elevHeaderHoursStr}h',
                        style: AppTextStyles.poiFormTitleBody
                            .copyWith(color: AppColors.muted),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            SizedBox(
              height: 180,
              width: double.maxFinite,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.white),
                  if (showChart)
                    CustomPaint(
                      painter: _SegmentElevationAreaPainter(
                        km: chart.kmFromSegmentStart,
                        elevationM: chart.elevationMeters,
                        segmentKm: chart.segmentKm,
                        kmAlongRouteStart: chart.kmAlongRouteStart,
                        kmAlongRouteEnd: chart.kmAlongRouteEnd,
                        distanceUnit: req.distanceUnit,
                        textScaler: MediaQuery.textScalerOf(context),
                        textDirection: Directionality.of(context),
                      ),
                    )
                  else
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Align(
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.swap_horiz,
                        size: 21, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(
                      distText,
                      style: AppTextStyles.poiMedium,
                      maxLines: 1,
                      softWrap: false,
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.trending_up,
                        size: 18, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(
                      gainText,
                      style: AppTextStyles.poiMedium,
                      maxLines: 1,
                      softWrap: false,
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.trending_down,
                        size: 18, color: AppColors.muted),
                    const SizedBox(width: 3),
                    Text(
                      lossText,
                      style: AppTextStyles.poiMedium,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// POI タップ時に表示するボトムシート。名前と説明を表示。
/// [entries] が2件以上のときは同一カテゴリ（GPX / ユーザー）内のシート内移動（＞）を表示する。
void showPoiDetailSheet(
  BuildContext context, {
  required List<PoiSheetEntry> entries,
  int initialIndex = 0,
  void Function(LatLng position)? onCenterOnPoi,
}) {
  assert(entries.isNotEmpty, 'entries must not be empty');
  final safeInitial = initialIndex.clamp(0, entries.length - 1);

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    ),
    builder: (context) {
      if (entries.length >= 2) {
        return _PoiDetailSheetNavigate(
          entries: entries,
          initialIndex: safeInitial,
          onCenterOnPoi: onCenterOnPoi,
        );
      }
      return _PoiDetailSheetBody(
        name: entries.first.name,
        distance: entries.first.distance,
        elevationGain: entries.first.elevationGain,
        description: entries.first.description,
        url: entries.first.url,
        arrival: entries.first.arrival,
        departure: entries.first.departure,
        close: entries.first.close,
        elevationSegment: entries.first.elevationSegment,
        segmentDistanceLabel: entries.first.segmentDistanceLabel,
        elevationOnDemand: entries.first.elevationOnDemand,
        distanceUnit: entries.first.distanceUnit,
        isRouteStartPoi: entries.first.isRouteStartPoi,
      );
    },
  );
}

class _PoiDetailSheetBody extends StatelessWidget {
  const _PoiDetailSheetBody({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.url,
    this.arrival,
    this.departure,
    this.close,
    this.elevationSegment,
    this.segmentDistanceLabel,
    this.elevationOnDemand,
    this.distanceUnit = 0,
    this.isRouteStartPoi = true,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final String? url;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final ElevationSegmentChartData? elevationSegment;
  final String? segmentDistanceLabel;
  final PoiElevationOnDemand? elevationOnDemand;
  final int distanceUnit;
  final bool isRouteStartPoi;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: _PoiContentBlock(
          name: name,
          distance: distance,
          elevationGain: elevationGain,
          description: description,
          url: url,
          arrival: arrival,
          departure: departure,
          close: close,
          elevationSegment: elevationSegment,
          segmentDistanceLabel: segmentDistanceLabel,
          elevationOnDemand: elevationOnDemand,
          distanceUnit: distanceUnit,
          isRouteStartPoi: isRouteStartPoi,
          sheetPadding: const EdgeInsets.fromLTRB(0, 20, 20, 25),
          distanceLeft: 20,
          contentLeft: 24,
        ),
      ),
    );
  }
}

class _PoiDetailSheetNavigate extends StatefulWidget {
  const _PoiDetailSheetNavigate({
    required this.entries,
    required this.initialIndex,
    this.onCenterOnPoi,
  });

  final List<PoiSheetEntry> entries;
  final int initialIndex;
  final void Function(LatLng position)? onCenterOnPoi;

  @override
  State<_PoiDetailSheetNavigate> createState() =>
      _PoiDetailSheetNavigateState();
}

class _PoiDetailSheetNavigateState extends State<_PoiDetailSheetNavigate> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.entries.length - 1);
  }

  void _goNext() {
    setState(() => _index = (_index + 1) % widget.entries.length);
    widget.onCenterOnPoi?.call(widget.entries[_index].position);
  }

  void _goPrev() {
    setState(() =>
        _index = (_index - 1 + widget.entries.length) % widget.entries.length);
    widget.onCenterOnPoi?.call(widget.entries[_index].position);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entries[_index];
    final hasDistance = e.distance != null && e.distance!.trim().isNotEmpty;
    final prevPadding = hasDistance
        ? const EdgeInsets.only(top: 20, bottom: 5)
        : const EdgeInsets.only(top: 20, bottom: 5);
    final nextPadding = hasDistance
        ? const EdgeInsets.only(top: 5, bottom: 20)
        : const EdgeInsets.only(top: 5, bottom: 20);
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _PoiContentBlock(
                  name: e.name,
                  distance: e.distance,
                  elevationGain: e.elevationGain,
                  description: e.description,
                  url: e.url,
                  arrival: e.arrival,
                  departure: e.departure,
                  close: e.close,
                  elevationSegment: e.elevationSegment,
                  segmentDistanceLabel: e.segmentDistanceLabel,
                  elevationOnDemand: e.elevationOnDemand,
                  distanceUnit: e.distanceUnit,
                  isRouteStartPoi: e.isRouteStartPoi,
                  sheetPadding: const EdgeInsets.fromLTRB(0, 20, 15, 25),
                  distanceLeft: 20,
                  contentLeft: 24,
                ),
              ),
              SizedBox(
                width: 50,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _goPrev,
                        splashColor: Colors.grey.withValues(alpha: 0.3),
                        highlightColor: Colors.grey.withValues(alpha: 0.2),
                        child: Padding(
                          padding: prevPadding,
                          child: const Align(
                            alignment: Alignment.bottomCenter,
                            child: Icon(
                              Icons.chevron_left,
                              size: 36,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _goNext,
                        splashColor: Colors.grey.withValues(alpha: 0.3),
                        highlightColor: Colors.grey.withValues(alpha: 0.2),
                        child: Padding(
                          padding: nextPadding,
                          child: const Align(
                            alignment: Alignment.topCenter,
                            child: Icon(
                              Icons.chevron_right,
                              size: 36,
                              color: Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// タイトル・距離・標高・スケジュール・本文を縦に並べるコンテンツブロック
class _PoiContentBlock extends StatelessWidget {
  const _PoiContentBlock({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.url,
    this.arrival,
    this.departure,
    this.close,
    this.elevationSegment,
    this.segmentDistanceLabel,
    this.elevationOnDemand,
    this.distanceUnit = 0,
    required this.sheetPadding,
    this.distanceLeft = 0,
    this.contentLeft = 0,
    this.isRouteStartPoi = true,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final String? url;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final ElevationSegmentChartData? elevationSegment;
  final String? segmentDistanceLabel;
  final PoiElevationOnDemand? elevationOnDemand;
  final int distanceUnit;
  final EdgeInsetsGeometry sheetPadding;
  final double distanceLeft;
  final double contentLeft;
  final bool isRouteStartPoi;

  String _formatTime(DateTime dt, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('H:mm', locale).format(dt.toLocal());
  }

  String _formatDate(DateTime dt, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.Md(locale).format(dt.toLocal());
  }

  Uri? _parseOpenableUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    var uri = Uri.tryParse(trimmed);
    if (uri == null) return null;
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
      if (uri == null) return null;
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri;
  }

  Widget _buildDateBadge(DateTime dt, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _formatDate(dt, context),
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDistance = distance != null && distance!.isNotEmpty;
    final hasElevationGainText =
        elevationGain != null && elevationGain!.isNotEmpty;
    final showSegmentChartPrecomputed =
        elevationSegment?.hasElevation == true &&
            segmentDistanceLabel != null &&
            segmentDistanceLabel!.isNotEmpty;
    final od = elevationOnDemand;
    final hasOnDemandElevationData =
        od != null && od.elevations.any((e) => e?.isFinite == true);
    final showElevationChartOnDemand = od != null &&
        hasOnDemandElevationData &&
        od.trackPoints.length >= 2 &&
        od.poiPositions.isNotEmpty &&
        od.poiIndex >= 0 &&
        od.poiIndex < od.poiPositions.length;
    final effectiveGainM = _effectiveElevationGainMeters(
      elevationGainDisplay: elevationGain,
      elevationSegment: elevationSegment,
    );
    final showElevationChartIcon =
        (showSegmentChartPrecomputed || showElevationChartOnDemand) &&
            (isRouteStartPoi || effectiveGainM == null || effectiveGainM > 0.5);
    final showElevationGainIcon = hasElevationGainText &&
        _shouldShowElevationGainIcon(
          isRouteStartPoi: isRouteStartPoi,
          elevationGainDisplay: elevationGain!,
          elevationSegment: elevationSegment,
        );
    final canTapSheetForElevationChart =
        showSegmentChartPrecomputed || showElevationChartOnDemand;
    final showStatsRow =
        hasDistance || showElevationGainIcon || showElevationChartIcon;
    final hasName = name != null && name!.isNotEmpty;
    final hasDescription = description != null && description!.isNotEmpty;
    final parsedUrl = url != null ? _parseOpenableUrl(url!) : null;
    final hasUrl = parsedUrl != null;
    final hasArrival = arrival != null;
    final hasDeparture = departure != null;
    final hasClose = close != null;
    final hasSchedule = hasArrival || hasDeparture || hasClose;

    void openElevationChart() {
      if (showSegmentChartPrecomputed) {
        _showPoiElevationSegmentDialog(
          context,
          elevationSegment: elevationSegment!,
          distanceLabel: segmentDistanceLabel!,
          distanceUnit: distanceUnit,
        );
      } else if (showElevationChartOnDemand) {
        _openElevationFromOnDemand(
          context,
          elevationOnDemand!,
        );
      }
    }

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 距離 + 獲得標高（1行）
        if (showStatsRow)
          Padding(
            padding: EdgeInsets.only(left: distanceLeft),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (hasDistance) ...[
                  const Icon(Icons.location_on,
                      size: 23, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(distance!, style: AppTextStyles.poiLarge),
                ],
                if (hasDistance && showElevationGainIcon)
                  const SizedBox(width: 12),
                if (showElevationGainIcon) ...[
                  const Icon(Icons.trending_up,
                      size: 23, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(elevationGain!, style: AppTextStyles.poiLarge),
                ],
              ],
            ),
          ),
        // スケジュール（arrival / departure）
        if (hasSchedule) ...[
          if (showStatsRow) const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Row(
              children: [
                _buildDateBadge(
                  (arrival ?? departure ?? close)!,
                  context,
                ),
                const SizedBox(width: 6),
                if (hasArrival) ...[
                  const Icon(Icons.arrow_downward,
                      size: 17, color: AppColors.muted),
                  const SizedBox(width: 1),
                  Text(
                    _formatTime(arrival!, context),
                    style: AppTextStyles.poiSchedule,
                  ),
                ],
                if (hasArrival && hasDeparture) const SizedBox(width: 8),
                if (hasDeparture) ...[
                  const Icon(Icons.arrow_upward,
                      size: 17, color: AppColors.muted),
                  const SizedBox(width: 1),
                  Text(
                    _formatTime(departure!, context),
                    style: AppTextStyles.poiSchedule,
                  ),
                ],
                if ((hasArrival || hasDeparture) && hasClose)
                  const SizedBox(width: 12),
                if (hasClose) ...[
                  const Icon(Icons.lock_outline,
                      size: 17, color: AppColors.muted),
                  const SizedBox(width: 1),
                  Text(_formatTime(close!, context),
                      style: AppTextStyles.poiSchedule),
                ],
              ],
            ),
          ),
        ],
        if (hasDistance) ...[
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.only(left: distanceLeft),
            child:
                const Divider(height: 1, thickness: 1, color: Colors.black26),
          ),
          const SizedBox(height: 12),
        ] else
          const SizedBox(height: 12),
        // タイトル
        if (hasName)
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: name!.replaceAll('　', ' ')),
                  if (hasUrl)
                    const WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: SizedBox(width: 4),
                    ),
                  if (hasUrl)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          splashColor: Colors.grey.withValues(alpha: 0.30),
                          highlightColor: Colors.grey.withValues(alpha: 0.20),
                          onTap: () async {
                            await launchUrl(
                              parsedUrl,
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(3),
                            child: Icon(
                              Icons.link,
                              size: 24,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              style: AppTextStyles.poiTitle.copyWith(height: 1.6),
            ),
          ),
        // 説明
        if (hasDescription) ...[
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text(
              description!.replaceAll('　', ' '),
              style: AppTextStyles.poiDetail.copyWith(height: 1.6),
            ),
          ),
        ],
      ],
    );

    final paddedContent = Padding(
      padding: sheetPadding,
      child: SizedBox(width: double.infinity, child: column),
    );

    if (canTapSheetForElevationChart) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openElevationChart,
          splashColor: Colors.grey.withValues(alpha: 0.25),
          highlightColor: Colors.grey.withValues(alpha: 0.12),
          child: paddedContent,
        ),
      );
    }
    return paddedContent;
  }
}

void _showPoiElevationSegmentDialog(
  BuildContext context, {
  required ElevationSegmentChartData elevationSegment,
  required String distanceLabel,
  required int distanceUnit,
}) {
  final textScaler = MediaQuery.textScalerOf(context);
  final textDirection = Directionality.of(context);
  showDialog<void>(
    context: context,
    barrierColor: Colors.transparent,
    builder: (_) => AlertDialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      content: _elevationDialogPanel(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 180,
                  width: double.maxFinite,
                  child: CustomPaint(
                    painter: _SegmentElevationAreaPainter(
                      km: elevationSegment.kmFromSegmentStart,
                      elevationM: elevationSegment.elevationMeters,
                      segmentKm: elevationSegment.segmentKm,
                      kmAlongRouteStart: elevationSegment.kmAlongRouteStart,
                      kmAlongRouteEnd: elevationSegment.kmAlongRouteEnd,
                      distanceUnit: distanceUnit,
                      textScaler: textScaler,
                      textDirection: textDirection,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz,
                            size: 22, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          distanceLabel,
                          style: AppTextStyles.poiMedium,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.trending_up,
                            size: 22, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          formatElevationChange(
                            elevationSegment.segmentElevationGainM,
                            distanceUnit,
                          ),
                          style: AppTextStyles.poiMedium,
                          maxLines: 1,
                          softWrap: false,
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.trending_down,
                            size: 22, color: AppColors.muted),
                        const SizedBox(width: 3),
                        Text(
                          formatElevationChange(
                            elevationSegment.segmentElevationLossM,
                            distanceUnit,
                          ),
                          style: AppTextStyles.poiMedium,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// [ticks] が昇順であるとき、極めて近い座標を 1 本にまとめる。
List<double> _dedupeSortedTicksNear(List<double> ticks, double span) {
  if (ticks.length <= 1) return ticks;
  final eps = math.max(span * 1e-11, 1e-10);
  final out = <double>[ticks.first];
  for (var i = 1; i < ticks.length; i++) {
    final v = ticks[i];
    if ((v - out.last).abs() > eps) out.add(v);
  }
  return out;
}

/// グラフ軸の目盛り値（データ座標）。
List<double> _niceAxisTicks(double min, double max, int divisions) {
  if (!(max >= min)) return [min];
  final span = max - min;
  if (span < 1e-15) return [min];
  final rough = span / math.max(1, divisions - 1);
  final exp = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final frac = rough / exp;
  final step = frac <= 1.5
      ? exp
      : frac <= 3
          ? 2 * exp
          : frac <= 7
              ? 5 * exp
              : 10 * exp;
  final start = (min / step).ceilToDouble() * step;
  final ticks = <double>[];
  for (var x = start; x <= max + step * 1e-9 && ticks.length < 24; x += step) {
    if (x >= min - step * 1e-9) ticks.add(x);
  }
  if (ticks.isEmpty) return [min, max];
  if (ticks.first > min + 1e-9) ticks.insert(0, min);
  if (ticks.last < max - 1e-9) ticks.add(max);
  return _dedupeSortedTicksNear(ticks, span);
}

class _SegmentElevationAreaPainter extends CustomPainter {
  _SegmentElevationAreaPainter({
    required this.km,
    required this.elevationM,
    required this.segmentKm,
    required this.kmAlongRouteStart,
    required this.kmAlongRouteEnd,
    required this.distanceUnit,
    required this.textScaler,
    required this.textDirection,
  });

  final List<double> km;
  final List<double> elevationM;

  /// ルート区間の距離（km）。[formatDistance] / シートの区間距離と一致させる。
  final double segmentKm;

  /// トラック先頭から区間始点・終点までの沿線距離（km）。横軸ラベル用。
  final double kmAlongRouteStart;
  final double kmAlongRouteEnd;

  final int distanceUnit;
  final TextScaler textScaler;
  final TextDirection textDirection;

  static const double _topGutter = 8;

  /// チャート下端〜キャンバス下端（距離目盛り・横軸単位の帯）
  static const double _bottomGutter = 38;

  TextStyle get _tickStyle => TextStyle(
        fontSize: 10,
        color: Colors.black.withValues(alpha: 0.65),
      );

  /// 横軸の目盛りラベル（終端以外）。ルート全体での累積距離（km）を表示する。
  /// [spanSegmentK] は軸に見える区間長（セグメント相対 km）。
  String _formatHorizTickKmNonTerminal(
      double cumulativeKm, double spanSegmentK) {
    if (distanceUnit == 1) {
      return (cumulativeKm / kmPerMile).round().toString();
    }
    return cumulativeKm.round().toString();
  }

  String _formatVertTickM(double mVal) {
    if (distanceUnit == 1) {
      return (mVal / 0.3048).round().toString();
    }
    return mVal.round().toString();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (km.isEmpty || km.length != elevationM.length) return;

    final xs = <double>[];
    final ys = <double>[];
    for (var i = 0; i < km.length; i++) {
      if (elevationM[i].isFinite) {
        xs.add(km[i]);
        ys.add(elevationM[i]);
      }
    }
    if (xs.isEmpty) return;

    var minK = xs.first;
    var maxK = xs.first;
    var minE = ys.first;
    var maxE = ys.first;
    for (var i = 0; i < xs.length; i++) {
      final x = xs[i];
      final y = ys[i];
      if (x < minK) minK = x;
      if (x > maxK) maxK = x;
      if (y < minE) minE = y;
      if (y > maxE) maxE = y;
    }

    final axisMin = minK;
    final axisMax = segmentKm.isFinite && segmentKm > 1e-12 ? segmentKm : maxK;
    var spanK = axisMax - axisMin;
    if (spanK < 1e-9) spanK = 1;
    var spanE = maxE - minE;
    if (spanE < 1e-6) {
      minE -= 5;
      maxE += 5;
      spanE = maxE - minE;
    }

    final distTicks = _niceAxisTicks(axisMin, axisMax, 6);
    final elevTicks = _niceAxisTicks(minE, maxE, 7);

    double maxLeftW = 0;
    for (final eTick in elevTicks) {
      final tp = TextPainter(
        text: TextSpan(text: _formatVertTickM(eTick), style: _tickStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      if (tp.width > maxLeftW) maxLeftW = tp.width;
    }
    final leftGutter = maxLeftW + 4;

    final plotLeft = leftGutter;
    final plotRight = size.width;
    final vertUnitStr = distanceUnit == 1 ? 'ft' : 'm';
    final unitVertTp = TextPainter(
      text: TextSpan(
          text: vertUnitStr,
          style: _tickStyle.copyWith(fontWeight: FontWeight.w600)),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    final chartPlotTop = _topGutter + unitVertTp.height + 6;
    final chartBottom = size.height - _bottomGutter;
    final plotW = plotRight - plotLeft;
    final plotH = chartBottom - chartPlotTop;
    if (plotW <= 0 || plotH <= 0) return;

    final distTickY = chartBottom + 4;
    final kmUnitTop = distTickY + 14;

    double txPlot(double k) {
      final kk = k.clamp(axisMin, axisMax);
      return plotLeft + (kk - axisMin) / spanK * plotW;
    }

    double tyPlot(double e) => chartBottom - (e - minE) / spanE * plotH;

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..strokeWidth = 1;

    for (final dk in distTicks) {
      if (dk < axisMin - 1e-9 || dk > axisMax + 1e-9) continue;
      final x = txPlot(dk);
      canvas.drawLine(
          Offset(x, chartPlotTop), Offset(x, chartBottom), gridPaint);
    }
    for (final el in elevTicks) {
      if (el < minE - 1e-9 || el > maxE + 1e-9) continue;
      final y = tyPlot(el);
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
    }

    final topPath = Path()..moveTo(txPlot(xs.first), tyPlot(ys.first));
    for (var i = 1; i < xs.length; i++) {
      topPath.lineTo(txPlot(xs[i]), tyPlot(ys[i]));
    }
    final fillPath = Path.from(topPath)
      ..lineTo(txPlot(xs.last), tyPlot(minE))
      ..lineTo(txPlot(xs.first), tyPlot(minE))
      ..close();

    final shaderRect = Rect.fromLTWH(plotLeft, chartPlotTop, plotW, plotH);
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.shade600.withValues(alpha: 0.7),
            Colors.blue.shade600.withValues(alpha: 0.06),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(shaderRect),
    );
    canvas.drawPath(
      topPath,
      Paint()
        ..color = Colors.blue.shade600
        ..strokeWidth = 0.6
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true,
    );

    final horizTicks = <double>[];
    for (final dk in distTicks) {
      if (dk >= axisMin - 1e-9 && dk <= axisMax + 1e-9) {
        horizTicks.add(dk);
      }
    }
    final nHoriz = horizTicks.length;
    const endLabelClearance = 8.0;

    final lastHorizLabel = formatDistanceNumeric(kmAlongRouteEnd, distanceUnit);
    final lastLabelTp = TextPainter(
      text: TextSpan(text: lastHorizLabel, style: _tickStyle),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();

    bool hideTickBeforeEnd = false;
    if (nHoriz >= 3) {
      final cxPrev = txPlot(horizTicks[nHoriz - 2]);
      final cxLast = txPlot(horizTicks[nHoriz - 1]);
      final prevLabel = _formatHorizTickKmNonTerminal(
          kmAlongRouteStart + horizTicks[nHoriz - 2], spanK);
      final prevTp = TextPainter(
        text: TextSpan(text: prevLabel, style: _tickStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final prevRight = cxPrev + prevTp.width / 2;
      final lastLeft = cxLast - lastLabelTp.width;
      if (lastLeft - prevRight < endLabelClearance) {
        hideTickBeforeEnd = true;
      }
    } else if (nHoriz == 2) {
      final cxFirst = txPlot(horizTicks[0]);
      final cxLast = txPlot(horizTicks[1]);
      final firstLabel = _formatHorizTickKmNonTerminal(
          kmAlongRouteStart + horizTicks[0], spanK);
      final firstTp = TextPainter(
        text: TextSpan(text: firstLabel, style: _tickStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final firstRight = cxFirst + firstTp.width;
      final lastLeft = cxLast - lastLabelTp.width;
      if (lastLeft - firstRight < endLabelClearance) {
        hideTickBeforeEnd = true;
      }
    }

    String? prevPaintedHorizLabel;
    for (var i = 0; i < horizTicks.length; i++) {
      final dk = horizTicks[i];
      final cx = txPlot(dk);
      final isFirst = i == 0;
      final isLast = i == horizTicks.length - 1;

      if (hideTickBeforeEnd && nHoriz >= 3 && i == nHoriz - 2) {
        continue;
      }
      if (hideTickBeforeEnd && nHoriz == 2 && i == 0) {
        continue;
      }

      final label = isLast
          ? lastHorizLabel
          : _formatHorizTickKmNonTerminal(kmAlongRouteStart + dk, spanK);

      /// グリッドは細かくても、文字が同一になる目盛りは間引く（終端以外）。
      final canCollapseInteriorDup =
          horizTicks.length > 2 && !isFirst && !isLast;
      if (canCollapseInteriorDup &&
          prevPaintedHorizLabel != null &&
          label == prevPaintedHorizLabel) {
        continue;
      }

      final tp = isLast
          ? lastLabelTp
          : TextPainter(
              text: TextSpan(text: label, style: _tickStyle),
              textDirection: textDirection,
              textScaler: textScaler,
            )
        ..layout();
      final x = horizTicks.length == 1
          ? cx - tp.width / 2
          : isFirst
              ? cx
              : isLast
                  ? cx - tp.width
                  : cx - tp.width / 2;
      final y = distTickY;
      if (x >= plotLeft - 1 && x + tp.width <= plotRight + 1) {
        tp.paint(canvas, Offset(x, y));
      }
      prevPaintedHorizLabel = label;
    }

    for (final eTick in elevTicks) {
      if (eTick < minE - 1e-9 || eTick > maxE + 1e-9) continue;
      final label = _formatVertTickM(eTick);
      final tp = TextPainter(
        text: TextSpan(text: label, style: _tickStyle),
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout();
      final x = plotLeft - tp.width - 6;
      final y = tyPlot(eTick) - tp.height / 2;
      if (y >= chartPlotTop - 2 && y + tp.height <= chartBottom + 2) {
        tp.paint(canvas, Offset(x, y));
      }
    }

    final horizUnitStr = distanceUnit == 1 ? 'mi' : 'km';

    final unitHorizTp = TextPainter(
      text: TextSpan(
          text: horizUnitStr,
          style: _tickStyle.copyWith(fontWeight: FontWeight.w600)),
      textDirection: textDirection,
      textScaler: textScaler,
    )..layout();
    unitHorizTp.paint(
      canvas,
      Offset(plotRight - unitHorizTp.width, kmUnitTop),
    );

    unitVertTp.paint(
      canvas,
      Offset(plotLeft - unitVertTp.width - 4, _topGutter),
    );
  }

  @override
  bool shouldRepaint(covariant _SegmentElevationAreaPainter oldDelegate) =>
      oldDelegate.km != km ||
      oldDelegate.elevationM != elevationM ||
      oldDelegate.segmentKm != segmentKm ||
      oldDelegate.kmAlongRouteStart != kmAlongRouteStart ||
      oldDelegate.kmAlongRouteEnd != kmAlongRouteEnd ||
      oldDelegate.distanceUnit != distanceUnit ||
      oldDelegate.textScaler != textScaler;
}

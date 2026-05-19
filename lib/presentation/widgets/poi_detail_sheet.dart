import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:url_launcher/url_launcher.dart';

import '../../domain/services/location_service.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/connectivity_check.dart';
import '../../utils/map_utils.dart';
import '../theme/app_text_styles.dart' show AppColors, AppTextStyles;
import '../utils/snackbar_utils.dart';
import 'poi_schedule_table_dialog.dart';

/// POIシートタップ時に [buildElevationSegmentChartData] でグラフを構築するための入力。
class PoiElevationOnDemand {
  const PoiElevationOnDemand({
    required this.trackPoints,
    required this.elevations,
    required this.poiPositions,
    required this.poiIndex,
    required this.distanceUnit,
    this.poiHasDistanceKm,
    this.poiKmAlongRoute,
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

  /// [poiPositions] と同長のとき、累積距離（km）でトラック上の区間端を決める（往復重複地点の誤判定防止）。
  final List<double?>? poiKmAlongRoute;

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

/// [_PoiDetailSheetNavigate] 右列（前後 POI）と同一幅。
const double _poiDetailSheetNavigateColumnWidth = 50;

/// POI チェックイン時、現在地と POI の直線距離がこの値（km）以内であることを要求する。
/// デバッグで緩めたい場合は 10.0 などに変更する。
const double kPoiCheckInProximityThresholdKm = 1.0;

String _poiCheckInProximityThresholdKmDisplay(double km) {
  if (km == km.roundToDouble()) return km.toInt().toString();
  return km.toStringAsFixed(1);
}

/// チェックイン系ダイアログ本文の行の高さ（[AppTextStyles.body] の fontSize に対する倍率）。
const double _poiCheckInDialogBodyLineHeight = 2;

const EdgeInsets _poiCheckInDialogTitlePadding =
    EdgeInsets.fromLTRB(24, 30, 24, 20);
const EdgeInsets _poiCheckInDialogContentPadding =
    EdgeInsets.fromLTRB(24, 0, 24, 0);
const EdgeInsets _poiCheckInDialogActionsPadding =
    EdgeInsets.fromLTRB(24, 0, 24, 24);

final TextStyle _poiCheckInDialogBodyStyle =
    AppTextStyles.body.copyWith(height: _poiCheckInDialogBodyLineHeight);

Widget _poiCheckInDialogTitle(String title) => Text(
      title,
      style: AppTextStyles.headlineMedium,
    );

/// ブルベスタートからの経過時間チャート（POI 本文シートより上の領域に表示。横軸目盛り間隔は [PoiSheetTimeChart.axisTickStepHours]）。
class PoiSheetTimeChart {
  const PoiSheetTimeChart({
    required this.brevetStartUtc,
    required this.timeLimitHours,
    required this.axisTickStepHours,
    this.elapsedHoursFromStart,
    required this.drawElapsedBar,
  });

  final DateTime brevetStartUtc;
  final double timeLimitHours;

  /// 横軸の目盛り間隔（時間）。公認距離テーブルに基づきコントローラ側で決定する。
  final double axisTickStepHours;

  /// [brevetStartUtc] から [arrival] までの経過（時間）。未設定時は横線なし。
  final double? elapsedHoursFromStart;

  /// スタート POI など、経過横線を描かないとき false。
  final bool drawElapsedBar;
}

/// チェックイン時刻までの経過（時間）。[PoiSheetTimeChart.brevetStartUtc] 起点。
double? poiSheetElapsedHoursFromBrevetStart(
  DateTime brevetStartUtc,
  DateTime instant,
) {
  final h = instant.difference(brevetStartUtc).inMicroseconds / 3600000000.0;
  if (!h.isFinite) return null;
  return h < 0 ? 0.0 : h;
}

class _PoiElapsedTimeChartPainter extends CustomPainter {
  _PoiElapsedTimeChartPainter({
    required this.timeLimitHours,
    required this.axisTickStepHours,
    required this.drawBar,
    this.elapsedHours,
    this.checkInElapsedHours,
  });

  final double timeLimitHours;
  final double axisTickStepHours;
  final bool drawBar;
  final double? elapsedHours;

  /// チェックイン OK 後のアニメーション用（復路ルートの緑）。未再生時は null。
  final double? checkInElapsedHours;

  static String _hoursMiddleLabel(double hours) {
    final r = hours.roundToDouble();
    if ((hours - r).abs() < 1e-6) return '${r.toInt()}';
    return hours.toStringAsFixed(1);
  }

  /// 右端（終点）ラベル。数値のみ（`h` は付けない）。
  static String _hoursEndLabel(double hours) {
    if (hours <= 0) return '0';
    final r = hours.roundToDouble();
    if ((hours - r).abs() < 1e-6) return '${r.toInt()}';
    return hours.toStringAsFixed(1);
  }

  static const _barStrokeWidth = 4.0;
  static const _tickH = 6.0;
  static const _barStackGap = 0.0;
  static const _axisPadBelowBlueBar = 0.0;

  /// 始点・終点ラベル用の左右インセット。
  static const _labelEndInset = 3.0;

  static double get _checkInBarCenterY => _barStrokeWidth / 2;

  static double get _scheduleBarCenterY =>
      _checkInBarCenterY + _barStrokeWidth + _barStackGap;

  static double get _axisY =>
      _scheduleBarCenterY + _barStrokeWidth / 2 + _axisPadBelowBlueBar;

  /// 縦目盛り下端と時間ラベル上端の間に 1px。
  static double get _labelY => _axisY + _tickH + 1;

  /// 目盛ラベル下の余白（px）。
  static const double _labelBottomPadding = 4.0;

  /// ラベル下側までの描画高（[paint] と [CustomPaint] の高さを一致させる）。
  static double get paintHeight =>
      _labelY +
      AppTextStyles.chartTick.fontSize! * AppTextStyles.chartTick.height! +
      _labelBottomPadding;

  @override
  void paint(Canvas canvas, Size size) {
    if (timeLimitHours <= 0 || !timeLimitHours.isFinite) return;
    final w = size.width;
    final h = size.height;
    final limit = timeLimitHours;

    final axisY = _axisY.clamp(0.0, h);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, axisY),
      Paint()..color = AppColors.chartPlotBackground,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, axisY, w, h - axisY),
      Paint()..color = AppColors.chartLabelStripBackground,
    );

    final axisPaint = Paint()
      ..color = AppColors.chartAxis
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, _axisY), Offset(w, _axisY), axisPaint);

    final tickPaint = Paint()
      ..color = AppColors.chartAxis
      ..strokeWidth = 0.9;

    final tickStepHours = axisTickStepHours.isFinite && axisTickStepHours > 0
        ? axisTickStepHours
        : 1.0;

    /// ループ最後の中間目盛（終点直前）。整数部が終点と同じときはラベルだけ非表示（例: 13 と 13.5 の重なり）。
    var lastMiddleHour = -1.0;
    for (var h = 0.0; h < limit - 1e-9; h += tickStepHours) {
      lastMiddleHour = h;
    }
    final hideLastMiddleLabel =
        lastMiddleHour >= 0 && lastMiddleHour.floor() == limit.floor();

    /// 左端 0h、右端は制限時間。中間は [axisTickStepHours] 間隔。
    for (var hour = 0.0; hour < limit - 1e-9; hour += tickStepHours) {
      final x = math.min(hour / limit * w, w);
      canvas.drawLine(
        Offset(x, _axisY),
        Offset(x, _axisY + _tickH),
        tickPaint,
      );

      final skipLabel =
          hideLastMiddleLabel && (hour - lastMiddleHour).abs() < 1e-9;
      if (!skipLabel) {
        final labelText = hour < 1e-9 ? '0 h' : _hoursMiddleLabel(hour);
        final tp = TextPainter(
          text: TextSpan(text: labelText, style: AppTextStyles.chartTick),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        if (hour < 1e-9) {
          tp.paint(canvas, Offset(_labelEndInset, _labelY));
        } else {
          final ox = (x - tp.width / 2)
              .clamp(0.0, math.max(0.0, w - tp.width))
              .toDouble();
          tp.paint(canvas, Offset(ox, _labelY));
        }
      }
    }

    canvas.drawLine(Offset(w, _axisY), Offset(w, _axisY + _tickH), tickPaint);
    final endTp = TextPainter(
      text:
          TextSpan(text: _hoursEndLabel(limit), style: AppTextStyles.chartTick),
      textDirection: TextDirection.ltr,
    );
    endTp.layout();
    final endOx = math.max(0.0, w - endTp.width - _labelEndInset);
    endTp.paint(
      canvas,
      Offset(endOx, _labelY),
    );

    if (drawBar) {
      final eh = elapsedHours;
      if (eh != null && eh.isFinite && eh > 0) {
        _drawProgressBar(
          canvas,
          w: w,
          limit: limit,
          elapsedHours: eh,
          centerY: _checkInBarCenterY,
          color: AppColors.chartCheckInBar,
        );
      }
    }

    final ci = checkInElapsedHours;
    if (ci != null && ci.isFinite && ci >= 0) {
      _drawProgressBar(
        canvas,
        w: w,
        limit: limit,
        elapsedHours: ci,
        centerY: _scheduleBarCenterY,
        color: AppColors.chartScheduleBar,
      );
    }
  }

  void _drawProgressBar(
    Canvas canvas, {
    required double w,
    required double limit,
    required double elapsedHours,
    required double centerY,
    required Color color,
  }) {
    final t = (elapsedHours / limit).clamp(0.0, 1.0);
    final xEnd = (t * w).clamp(0.0, w);
    final barPaint = Paint()
      ..color = color
      ..strokeWidth = _barStrokeWidth
      ..strokeCap = StrokeCap.square;
    if (xEnd < 2) {
      canvas.drawCircle(Offset(1.5, centerY), _barStrokeWidth, barPaint);
    } else {
      canvas.drawLine(Offset(0, centerY), Offset(xEnd, centerY), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PoiElapsedTimeChartPainter oldDelegate) =>
      oldDelegate.timeLimitHours != timeLimitHours ||
      oldDelegate.axisTickStepHours != axisTickStepHours ||
      oldDelegate.drawBar != drawBar ||
      oldDelegate.elapsedHours != elapsedHours ||
      oldDelegate.checkInElapsedHours != checkInElapsedHours;
}

class _PoiElapsedTimeChartStrip extends StatelessWidget {
  const _PoiElapsedTimeChartStrip({
    required this.data,
    required this.viewportWidth,
    this.checkInElapsedHours,
  });

  final PoiSheetTimeChart data;
  final double viewportWidth;
  final double? checkInElapsedHours;

  @override
  Widget build(BuildContext context) {
    final h = _PoiElapsedTimeChartPainter.paintHeight;
    if (viewportWidth <= 0 || !viewportWidth.isFinite) {
      return SizedBox(height: h);
    }
    final w = viewportWidth;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        size: Size(w, h),
        painter: _PoiElapsedTimeChartPainter(
          timeLimitHours: data.timeLimitHours,
          axisTickStepHours: data.axisTickStepHours,
          drawBar: data.drawElapsedBar,
          elapsedHours: data.elapsedHoursFromStart,
          checkInElapsedHours: checkInElapsedHours,
        ),
      ),
    );
  }
}

/// 経過時間チャートのみ（[showPoiDetailSheet] 内で POI 本文 [_PoiContentBlock] より上に配置）。
class _PoiSheetTimeChartHeader extends StatelessWidget {
  const _PoiSheetTimeChartHeader({
    required this.data,
    required this.viewportWidth,
    required this.checkInResultUtcForBar,
    this.checkInAnimatedElapsedHours,
  });

  static const double _horizontalInset = 0;

  final PoiSheetTimeChart data;

  /// 親 [LayoutBuilder] の幅（余白控除前）。
  final double viewportWidth;

  /// 下段チェックインバーを [BmSchedule.result] に合わせる。セッション上書きがあれば親の解決済み UTC。
  final DateTime? checkInResultUtcForBar;

  /// チェックイン確定後のアニメーション中の経過時間。非 null のとき [checkInResultUtcForBar] より優先。
  final double? checkInAnimatedElapsedHours;

  @override
  Widget build(BuildContext context) {
    final innerW = math.max(
      1.0,
      viewportWidth - 2 * _horizontalInset,
    );
    final animated = checkInAnimatedElapsedHours;
    final double? resolvedCheckInElapsed;
    if (animated != null) {
      resolvedCheckInElapsed = animated;
    } else {
      final r = checkInResultUtcForBar;
      resolvedCheckInElapsed = r == null
          ? null
          : poiSheetElapsedHoursFromBrevetStart(data.brevetStartUtc, r);
    }
    return _PoiElapsedTimeChartStrip(
      data: data,
      viewportWidth: innerW,
      checkInElapsedHours: resolvedCheckInElapsed,
    );
  }
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
    this.timeChart,
    this.elevationSegment,
    this.segmentDistanceLabel,
    this.elevationOnDemand,
    this.distanceUnit = 0,
    this.isRouteStartPoi = true,
    this.checkInResultUtc,
    this.onCheckIn,
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

  /// ブルベ設定が揃っているとき、スタートからの経過時間チャート。
  final PoiSheetTimeChart? timeChart;

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

  /// 対応 POI の [BmSchedule.result]。`null` ＝未設定（トグル OFF）、非 null ＝設定済み（トグル ON）。
  final DateTime? checkInResultUtc;

  /// User POI のチェックイン。[BmSchedule.result] に UTC を書き込む。未設定時のみシートから呼べる。
  final Future<void> Function(DateTime checkInUtc)? onCheckIn;
}

/// チェックイントグル：[BmSchedule.result] の有無のみで ON/OFF（保存しているかどうか）。
bool _poiCheckInToggleOnFromResultUtc(DateTime? resultUtc) => resultUtc != null;

Future<void> _runPoiCheckInToggleTap({
  required BuildContext context,
  required LatLng poiPosition,
  required bool verifyLocationOnCheckIn,
  required bool turnOn,
  required PoiSheetTimeChart? timeChart,
  required void Function(double targetElapsedHours)?
      onBeginCheckInChartAnimation,
  required Future<void> Function(DateTime utc)? onCommit,
  required Future<void> Function()? onClear,
}) async {
  if (turnOn) {
    if (onCommit == null) return;
    if (!verifyLocationOnCheckIn) {
      await _showPoiCheckInConfirmDialog(
        context,
        onCheckIn: onCommit,
        timeChart: timeChart,
        onBeginCheckInChartAnimation: onBeginCheckInChartAnimation,
      );
      return;
    }
    await _beginPoiCheckInFlowWithLocation(
      context: context,
      poiPosition: poiPosition,
      timeChart: timeChart,
      onBeginCheckInChartAnimation: onBeginCheckInChartAnimation,
      onCommit: onCommit,
    );
    return;
  }
  await onClear?.call();
}

Future<void> _beginPoiCheckInFlowWithLocation({
  required BuildContext context,
  required LatLng poiPosition,
  required PoiSheetTimeChart? timeChart,
  required void Function(double targetElapsedHours)?
      onBeginCheckInChartAnimation,
  required Future<void> Function(DateTime utc) onCommit,
}) async {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Text(
                l10n.poiCheckInFetchingLocation,
                style: AppTextStyles.body
                    .copyWith(height: _poiCheckInDialogBodyLineHeight),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  late final PoiCheckInLocationResolveResult resolveResult;
  try {
    resolveResult = await resolvePositionForPoiCheckIn();
  } finally {
    if (context.mounted) Navigator.of(context).pop();
  }

  if (!context.mounted) return;

  switch (resolveResult) {
    case PoiCheckInLocationResolved(:final position):
      final distanceM = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        poiPosition.latitude,
        poiPosition.longitude,
      );
      const thresholdM = kPoiCheckInProximityThresholdKm * 1000;
      if (distanceM > thresholdM) {
        await _showPoiCheckInBlockedTooFarDialog(context);
        return;
      }
      await _showPoiCheckInConfirmDialog(
        context,
        onCheckIn: onCommit,
        timeChart: timeChart,
        onBeginCheckInChartAnimation: onBeginCheckInChartAnimation,
      );
    case PoiCheckInLocationFailed(:final reason):
      await _showPoiCheckInLocationFailureDialog(context, reason);
  }
}

Future<void> _showPoiCheckInOkOnlyAlert(
  BuildContext context, {
  required String title,
  required String message,
  required String okLabel,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      titlePadding: _poiCheckInDialogTitlePadding,
      contentPadding: _poiCheckInDialogContentPadding,
      actionsPadding: _poiCheckInDialogActionsPadding,
      title: _poiCheckInDialogTitle(title),
      content: Text(message, style: _poiCheckInDialogBodyStyle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(okLabel, style: AppTextStyles.button),
        ),
      ],
    ),
  );
}

Future<void> _showPoiCheckInBlockedTooFarDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  await _showPoiCheckInOkOnlyAlert(
    context,
    title: l10n.poiCheckInNotAvailableTitle,
    message: l10n.poiCheckInTooFarFromPoi(
      _poiCheckInProximityThresholdKmDisplay(kPoiCheckInProximityThresholdKm),
    ),
    okLabel: l10n.ok,
  );
}

Future<void> _showPoiCheckInLocationFailureDialog(
  BuildContext context,
  PoiCheckInLocationFailReason reason,
) async {
  final l10n = AppLocalizations.of(context)!;
  final title = l10n.poiCheckInLocationAcquireFailedTitle;

  final (
    String message,
    bool offerSettings,
    Future<void> Function()? launchSettings
  ) = switch (reason) {
    PoiCheckInLocationFailReason.serviceOff => (
        l10n.locationServiceOff,
        true,
        () async {
          await Geolocator.openLocationSettings();
        },
      ),
    PoiCheckInLocationFailReason.permissionDenied => (
        l10n.locationPermissionDenied,
        false,
        null,
      ),
    PoiCheckInLocationFailReason.permissionDeniedForever => (
        l10n.locationPermissionDeniedForever,
        true,
        () async {
          await Geolocator.openAppSettings();
        },
      ),
    PoiCheckInLocationFailReason.positionUnavailable => (
        l10n.poiCheckInLocationUnavailableDetail,
        false,
        null,
      ),
  };

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      titlePadding: _poiCheckInDialogTitlePadding,
      contentPadding: _poiCheckInDialogContentPadding,
      actionsPadding: _poiCheckInDialogActionsPadding,
      title: _poiCheckInDialogTitle(title),
      content: Text(message, style: _poiCheckInDialogBodyStyle),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.ok, style: AppTextStyles.button),
        ),
        if (offerSettings && launchSettings != null)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await launchSettings();
            },
            child: Text(l10n.openSettings, style: AppTextStyles.button),
          ),
      ],
    ),
  );
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

Future<void> _showPoiCheckInConfirmDialog(
  BuildContext context, {
  required Future<void> Function(DateTime utc) onCheckIn,
  PoiSheetTimeChart? timeChart,
  void Function(double targetElapsedHours)? onBeginCheckInChartAnimation,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final compactButtonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(Size.zero),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      actionsPadding: _poiCheckInDialogActionsPadding,
      content: Text(
        l10n.poiCheckInConfirmMessage,
        style: _poiCheckInDialogBodyStyle,
      ),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.ok, style: AppTextStyles.button),
        ),
      ],
    ),
  );
  if (ok != true) return;
  if (!context.mounted) return;
  final utc = DateTime.now().toUtc();
  final tc = timeChart;
  if (tc != null && onBeginCheckInChartAnimation != null) {
    final th = poiSheetElapsedHoursFromBrevetStart(tc.brevetStartUtc, utc);
    if (th != null) onBeginCheckInChartAnimation(th);
  }
  await onCheckIn(utc);
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
      poiKmAlongRoute: req.poiKmAlongRoute,
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
          poiKmAlongRoute: req.poiKmAlongRoute,
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
  required bool verifyLocationOnCheckIn,
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
          verifyLocationOnCheckIn: verifyLocationOnCheckIn,
          onCenterOnPoi: onCenterOnPoi,
        );
      }
      return _PoiDetailSheetBody(
        name: entries.first.name,
        distance: entries.first.distance,
        elevationGain: entries.first.elevationGain,
        description: entries.first.description,
        url: entries.first.url,
        position: entries.first.position,
        arrival: entries.first.arrival,
        departure: entries.first.departure,
        close: entries.first.close,
        timeChart: entries.first.timeChart,
        elevationSegment: entries.first.elevationSegment,
        segmentDistanceLabel: entries.first.segmentDistanceLabel,
        elevationOnDemand: entries.first.elevationOnDemand,
        distanceUnit: entries.first.distanceUnit,
        isRouteStartPoi: entries.first.isRouteStartPoi,
        checkInResultUtc: entries.first.checkInResultUtc,
        onCheckIn: entries.first.onCheckIn,
        verifyLocationOnCheckIn: verifyLocationOnCheckIn,
        allEntries: entries,
      );
    },
  );
}

class _PoiDetailSheetBody extends StatefulWidget {
  const _PoiDetailSheetBody({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.url,
    required this.position,
    this.arrival,
    this.departure,
    this.close,
    this.timeChart,
    this.elevationSegment,
    this.segmentDistanceLabel,
    this.elevationOnDemand,
    this.distanceUnit = 0,
    this.isRouteStartPoi = true,
    this.checkInResultUtc,
    this.onCheckIn,
    required this.verifyLocationOnCheckIn,
    required this.allEntries,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final String? url;
  final LatLng position;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final PoiSheetTimeChart? timeChart;
  final ElevationSegmentChartData? elevationSegment;
  final String? segmentDistanceLabel;
  final PoiElevationOnDemand? elevationOnDemand;
  final int distanceUnit;
  final bool isRouteStartPoi;

  /// [BmSchedule.result] と同一。[PoiSheetEntry.checkInResultUtc] から渡す。
  final DateTime? checkInResultUtc;
  final Future<void> Function(DateTime checkInUtc)? onCheckIn;

  /// false のときチェックインONで位置を取得せず確認ダイアログのみ。
  final bool verifyLocationOnCheckIn;

  /// テーブルダイアログ用：シートに関連する全エントリ。
  final List<PoiSheetEntry> allEntries;

  @override
  State<_PoiDetailSheetBody> createState() => _PoiDetailSheetBodyState();
}

class _PoiDetailSheetBodyState extends State<_PoiDetailSheetBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkInChartAnim;
  late final CurvedAnimation _checkInChartCurve;
  bool _checkInChartAnimationActive = false;
  double _checkInTargetHours = 0;
  bool _checkInAnimating = false;

  /// シート表示中に確定したチェックイン状態（永続化後も [widget.checkInResultUtc] は古いままのため）。
  bool _sessionCheckInExplicit = false;
  DateTime? _sessionCheckInUtc;

  @override
  void initState() {
    super.initState();
    _checkInChartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkInChartCurve = CurvedAnimation(
      parent: _checkInChartAnim,
      curve: Curves.easeOutCubic,
    );
    _checkInChartAnim.addListener(() => setState(() {}));
    _checkInChartAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _checkInAnimating = false);
      }
    });
  }

  @override
  void dispose() {
    _checkInChartCurve.dispose();
    _checkInChartAnim.dispose();
    super.dispose();
  }

  void _onBeginCheckInChartAnimation(double targetHours) {
    setState(() {
      _checkInChartAnimationActive = true;
      _checkInTargetHours = targetHours;
    });
    _checkInChartAnim.forward(from: 0);
  }

  double? get _checkInDisplayElapsedHours {
    if (!_checkInChartAnimationActive) return null;
    return _checkInChartCurve.value * _checkInTargetHours;
  }

  DateTime? get _effectiveCheckInResultUtc =>
      _sessionCheckInExplicit ? _sessionCheckInUtc : widget.checkInResultUtc;

  Future<void> _wrapCommitCheckIn(DateTime utc) async {
    await widget.onCheckIn!(utc);
    if (!mounted) return;
    setState(() {
      _sessionCheckInExplicit = true;
      _sessionCheckInUtc = utc;
    });
  }

  @override
  Widget build(BuildContext context) {
    const sheetPadding = EdgeInsets.fromLTRB(0, 20, 20, 25);
    const distanceLeft = 20.0;
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final chartW = w.isFinite && w > 0 ? w : 1.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.timeChart case final tc?)
                  _PoiSheetTimeChartHeader(
                    data: tc,
                    viewportWidth: chartW,
                    checkInAnimatedElapsedHours: _checkInDisplayElapsedHours,
                    checkInResultUtcForBar: _effectiveCheckInResultUtc,
                  ),
                _PoiContentBlock(
                  name: widget.name,
                  distance: widget.distance,
                  elevationGain: widget.elevationGain,
                  description: widget.description,
                  url: widget.url,
                  poiPosition: widget.position,
                  arrival: widget.arrival,
                  departure: widget.departure,
                  close: widget.close,
                  elevationSegment: widget.elevationSegment,
                  segmentDistanceLabel: widget.segmentDistanceLabel,
                  elevationOnDemand: widget.elevationOnDemand,
                  distanceUnit: widget.distanceUnit,
                  isRouteStartPoi: widget.isRouteStartPoi,
                  timeChart: widget.timeChart,
                  onBeginCheckInChartAnimation: widget.timeChart != null
                      ? _onBeginCheckInChartAnimation
                      : null,
                  checkInTapEntryIndex: 0,
                  checkInResultUtc: _effectiveCheckInResultUtc,
                  onCommitCheckInForEntry: widget.onCheckIn == null
                      ? null
                      : (_, utc) => _wrapCommitCheckIn(utc),
                  verifyLocationOnCheckIn: widget.verifyLocationOnCheckIn,
                  checkInAnimating: _checkInAnimating,
                  onCheckInTapStart: () => setState(() => _checkInAnimating = true),
                  onCheckInTapCancel: () => setState(() => _checkInAnimating = false),
                  scheduleEntries: widget.allEntries,
                  contentLayoutMaxWidth: constraints.maxWidth,
                  sheetPadding: sheetPadding,
                  distanceLeft: distanceLeft,
                  contentLeft: 24,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PoiDetailSheetNavigate extends StatefulWidget {
  const _PoiDetailSheetNavigate({
    required this.entries,
    required this.initialIndex,
    required this.verifyLocationOnCheckIn,
    this.onCenterOnPoi,
  });

  final List<PoiSheetEntry> entries;
  final int initialIndex;
  final bool verifyLocationOnCheckIn;
  final void Function(LatLng position)? onCenterOnPoi;

  @override
  State<_PoiDetailSheetNavigate> createState() =>
      _PoiDetailSheetNavigateState();
}

class _PoiDetailSheetNavigateState extends State<_PoiDetailSheetNavigate>
    with SingleTickerProviderStateMixin {
  late int _index;
  late final AnimationController _checkInChartAnim;
  late final CurvedAnimation _checkInChartCurve;
  bool _checkInChartAnimationActive = false;
  double _checkInTargetHours = 0;
  bool _checkInAnimating = false;

  final Map<int, DateTime?> _checkInSessionByIndex = {};

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.entries.length - 1);
    _checkInChartAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _checkInChartCurve = CurvedAnimation(
      parent: _checkInChartAnim,
      curve: Curves.easeOutCubic,
    );
    _checkInChartAnim.addListener(() => setState(() {}));
    _checkInChartAnim.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _checkInAnimating = false);
      }
    });
  }

  @override
  void dispose() {
    _checkInChartCurve.dispose();
    _checkInChartAnim.dispose();
    super.dispose();
  }

  void _resetCheckInChartAnimation() {
    setState(() {
      _checkInChartAnimationActive = false;
      _checkInTargetHours = 0;
      _checkInAnimating = false;
    });
    _checkInChartAnim.reset();
  }

  void _onBeginCheckInChartAnimation(double targetHours) {
    setState(() {
      _checkInChartAnimationActive = true;
      _checkInTargetHours = targetHours;
    });
    _checkInChartAnim.forward(from: 0);
  }

  double? get _checkInDisplayElapsedHours {
    if (!_checkInChartAnimationActive) return null;
    return _checkInChartCurve.value * _checkInTargetHours;
  }

  DateTime? _effectiveCheckInUtc(int i) => _checkInSessionByIndex.containsKey(i)
      ? _checkInSessionByIndex[i]
      : widget.entries[i].checkInResultUtc;

  void _goNext() {
    _resetCheckInChartAnimation();
    setState(() => _index = (_index + 1) % widget.entries.length);
    widget.onCenterOnPoi?.call(widget.entries[_index].position);
  }

  void _goPrev() {
    _resetCheckInChartAnimation();
    setState(() =>
        _index = (_index - 1 + widget.entries.length) % widget.entries.length);
    widget.onCenterOnPoi?.call(widget.entries[_index].position);
  }

  @override
  Widget build(BuildContext context) {
    final ix = _index;
    final e = widget.entries[ix];
    final hasDistance = e.distance != null && e.distance!.trim().isNotEmpty;
    final prevPadding = hasDistance
        ? const EdgeInsets.only(top: 20, bottom: 5)
        : const EdgeInsets.only(top: 20, bottom: 5);
    final nextPadding = hasDistance
        ? const EdgeInsets.only(top: 5, bottom: 20)
        : const EdgeInsets.only(top: 5, bottom: 20);
    const sheetPadding = EdgeInsets.fromLTRB(0, 18, 15, 25);
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final expandedW = math.max(
              0.0,
              constraints.maxWidth - _poiDetailSheetNavigateColumnWidth,
            );
            const distanceLeft = 20.0;
            final w = constraints.maxWidth;
            final chartW = w.isFinite && w > 0 ? w : 1.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (e.timeChart case final tc?)
                  _PoiSheetTimeChartHeader(
                    data: tc,
                    viewportWidth: chartW,
                    checkInAnimatedElapsedHours: _checkInDisplayElapsedHours,
                    checkInResultUtcForBar: _effectiveCheckInUtc(ix),
                  ),
                IntrinsicHeight(
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
                          poiPosition: e.position,
                          arrival: e.arrival,
                          departure: e.departure,
                          close: e.close,
                          elevationSegment: e.elevationSegment,
                          segmentDistanceLabel: e.segmentDistanceLabel,
                          elevationOnDemand: e.elevationOnDemand,
                          distanceUnit: e.distanceUnit,
                          isRouteStartPoi: e.isRouteStartPoi,
                          timeChart: e.timeChart,
                          onBeginCheckInChartAnimation: e.timeChart != null
                              ? _onBeginCheckInChartAnimation
                              : null,
                          checkInTapEntryIndex: ix,
                          checkInResultUtc: _effectiveCheckInUtc(ix),
                          onCommitCheckInForEntry: e.onCheckIn == null
                              ? null
                              : (entryIndex, utc) async {
                                  await widget
                                      .entries[entryIndex].onCheckIn!(utc);
                                  if (!mounted) return;
                                  setState(
                                    () => _checkInSessionByIndex[entryIndex] =
                                        utc,
                                  );
                                },
                          verifyLocationOnCheckIn:
                              widget.verifyLocationOnCheckIn,
                          checkInAnimating: _checkInAnimating,
                          onCheckInTapStart: () =>
                              setState(() => _checkInAnimating = true),
                          onCheckInTapCancel: () =>
                              setState(() => _checkInAnimating = false),
                          scheduleEntries: widget.entries,
                          contentLayoutMaxWidth: expandedW,
                          sheetPadding: sheetPadding,
                          distanceLeft: distanceLeft,
                          contentLeft: 24,
                        ),
                      ),
                      SizedBox(
                        width: _poiDetailSheetNavigateColumnWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _goPrev,
                                splashColor: Colors.grey.withValues(alpha: 0.3),
                                highlightColor:
                                    Colors.grey.withValues(alpha: 0.2),
                                child: Padding(
                                  padding: prevPadding,
                                  child: const Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Icon(
                                      Icons.chevron_left,
                                      size: 36,
                                      color: AppColors.mutedLight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: _goNext,
                                splashColor: Colors.grey.withValues(alpha: 0.3),
                                highlightColor:
                                    Colors.grey.withValues(alpha: 0.2),
                                child: Padding(
                                  padding: nextPadding,
                                  child: const Align(
                                    alignment: Alignment.topCenter,
                                    child: Icon(
                                      Icons.chevron_right,
                                      size: 36,
                                      color: AppColors.mutedLight,
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
              ],
            );
          },
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
    required this.contentLayoutMaxWidth,
    this.url,
    required this.poiPosition,
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
    this.timeChart,
    this.onBeginCheckInChartAnimation,
    this.checkInTapEntryIndex = 0,
    this.checkInResultUtc,
    this.onCommitCheckInForEntry,
    required this.verifyLocationOnCheckIn,
    this.checkInAnimating = false,
    this.onCheckInTapStart,
    this.onCheckInTapCancel,
    this.scheduleEntries,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final String? url;
  final LatLng poiPosition;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final ElevationSegmentChartData? elevationSegment;
  final String? segmentDistanceLabel;
  final PoiElevationOnDemand? elevationOnDemand;
  final int distanceUnit;

  /// シートのパディング適用前の、このブロックに割り当てられた最大幅（[Expanded] スロット幅）。
  final double contentLayoutMaxWidth;

  final EdgeInsetsGeometry sheetPadding;
  final double distanceLeft;
  final double contentLeft;
  final bool isRouteStartPoi;
  final PoiSheetTimeChart? timeChart;
  final void Function(double targetElapsedHours)? onBeginCheckInChartAnimation;

  /// チェックイン操作中の非同期完了後に適用する対象 POI インデックス（同一シート内の一覧位置）。
  final int checkInTapEntryIndex;

  /// 表示中の [BmSchedule.result] の値（各 POI は [PoiSheetEntry.checkInResultUtc] またはシート内セッション反映後）。
  /// 非 null ＝設定済みでトグル ON。
  final DateTime? checkInResultUtc;

  /// チェックイン確定（トグル OFF→ON のみ。ON 済みは無効のまま）。
  final Future<void> Function(int entryIndex, DateTime utc)?
      onCommitCheckInForEntry;

  /// false のとき位置取得・距離判定を省略し確認ダイアログのみ。
  final bool verifyLocationOnCheckIn;

  /// チェックインバーアニメーション再生中 true（アイコンを bookmark に切り替える）。
  final bool checkInAnimating;

  /// チェックインアイコンをタップした瞬間に呼ばれるコールバック。
  final VoidCallback? onCheckInTapStart;

  /// チェックインダイアログでキャンセルされたとき（アニメーション未開始で処理が終了したとき）に呼ばれる。
  final VoidCallback? onCheckInTapCancel;

  /// view_list タップ時に表示するスケジュールテーブルの全エントリ。
  final List<PoiSheetEntry>? scheduleEntries;

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
        border: Border.all(color: AppColors.poiDateBadge, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        _formatDate(dt, context),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.poiDateBadge,
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
    final showStartPoiListIcon = isRouteStartPoi && scheduleEntries != null;
    final showStatsRow = hasDistance ||
        showElevationGainIcon ||
        showElevationChartIcon ||
        showStartPoiListIcon;
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
                  if (_poiCheckInToggleOnFromResultUtc(checkInResultUtc) ||
                      onCommitCheckInForEntry != null) ...[
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: _poiCheckInToggleOnFromResultUtc(checkInResultUtc)
                          ? (scheduleEntries != null
                              ? () => showDialog<void>(
                                    context: context,
                                    builder: (_) => PoiScheduleTableDialog(
                                      distanceUnit: distanceUnit,
                                      rows: scheduleEntries!
                                          .map((e) => PoiScheduleRow(
                                                distance: e.distance,
                                                name: e.name,
                                                arrival: e.arrival,
                                                checkInResultUtc:
                                                    e.checkInResultUtc,
                                              ))
                                          .toList(),
                                    ),
                                  )
                              : null)
                          : (onCommitCheckInForEntry != null
                              ? () async {
                                  onCheckInTapStart?.call();
                                  final ei = checkInTapEntryIndex;
                                  var animationStarted = false;
                                  await _runPoiCheckInToggleTap(
                                    context: context,
                                    poiPosition: poiPosition,
                                    verifyLocationOnCheckIn:
                                        verifyLocationOnCheckIn,
                                    turnOn: true,
                                    timeChart: timeChart,
                                    onBeginCheckInChartAnimation:
                                        onBeginCheckInChartAnimation == null
                                            ? null
                                            : (hours) {
                                                animationStarted = true;
                                                onBeginCheckInChartAnimation!(
                                                    hours);
                                              },
                                    onCommit: (utc) =>
                                        onCommitCheckInForEntry!(ei, utc),
                                    onClear: () async {},
                                  );
                                  if (!animationStarted) {
                                    onCheckInTapCancel?.call();
                                  }
                                }
                              : null),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          _poiCheckInToggleOnFromResultUtc(checkInResultUtc)
                              ? Icons.view_list
                              : checkInAnimating
                                  ? Icons.bookmark
                                  : Icons.bookmark_add_outlined,
                          size: 30,
                          color: checkInAnimating
                              ? AppColors.mutedLight
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ],
                if (showStartPoiListIcon) ...[
                  if (hasDistance || showElevationGainIcon)
                    const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => PoiScheduleTableDialog(
                        distanceUnit: distanceUnit,
                        rows: scheduleEntries!
                            .map((e) => PoiScheduleRow(
                                  distance: e.distance,
                                  name: e.name,
                                  arrival: e.arrival,
                                  checkInResultUtc: e.checkInResultUtc,
                                ))
                            .toList(),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.view_list,
                        size: 30,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
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
                            if (!await checkConnectivity()) {
                              if (!context.mounted) return;
                              showAppSnackBarOverlaid(
                                context,
                                AppLocalizations.of(context)!.offline,
                              );
                              return;
                            }
                            if (!context.mounted) return;
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

    /// プロット下端と横軸距離ラベルの間の余白（目盛り＝下端グリッド交点）。
    final distTickY = chartBottom + 5;
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

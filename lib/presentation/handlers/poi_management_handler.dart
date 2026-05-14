// TODO: Radio を RadioGroup ベースに移行後に削除（Flutter 3.32+）
// ignore_for_file: deprecated_member_use

import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/bm_extension.dart';
import '../../domain/models/brevet_distances.dart';
import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/effective_premium.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/text_menu_dialog.dart';

// ---------------------------------------------------------------------------
// POI管理のハンドラとダイアログ
// ---------------------------------------------------------------------------

/// POI「タイトル」「本文」TextField の入力域まわりの余白（主に下端）。
/// [InputDecoration.contentPadding] で調整する。
const EdgeInsets _kPoiTitleBodyFieldContentPadding =
    EdgeInsets.fromLTRB(0, 12, 0, 8);

/// POIフォームの入力データ
class AddPoiFormData {
  const AddPoiFormData({
    this.km,
    required this.type,
    required this.title,
    required this.body,
    required this.url,
    this.arrival,
    this.departure,
    this.close,
    this.isNote = false,
  });
  final double? km;
  final int type;
  final String title;
  final String body;
  final String url;
  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final bool isNote;
}

/// 地図タップでPOI追加を選択した場合のリクエスト
class MapTapAddRequest {
  const MapTapAddRequest();
}

/// POI位置編集を選択した場合のリクエスト
class PoiEditPositionRequest {
  const PoiEditPositionRequest(this.poi);
  final UserPoi poi;
}

String _elevationEditDisplay(double? metersM, int distanceUnit) =>
    formatElevationChange(metersM ?? 0, distanceUnit);

int _normalizePoiTypeForForm(int type) {
  return UserPoiType.fromValue(type).value;
}

List<DropdownMenuItem<int>> _buildPoiTypeDropdownItems(AppLocalizations l10n) {
  return UserPoiType.dropdownOrder
      .map(
        (type) => DropdownMenuItem<int>(
          value: type.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(type.localizedLabel(l10n)),
          ),
        ),
      )
      .toList(growable: false);
}

/// POI スケジュール内の全日時フィールドを [delta] だけシフトする。
UserPoi _shiftPoiSchedule(UserPoi poi, Duration delta) {
  final ext = poi.bmExt;
  if (ext == null || ext.schedule.isEmpty) return poi;
  return UserPoi(
    type: poi.type,
    km: poi.km,
    title: poi.title,
    body: poi.body,
    url: poi.url,
    lat: poi.lat,
    lng: poi.lng,
    gpxCmt: poi.gpxCmt,
    gpxType: poi.gpxType,
    isNote: poi.isNote,
    bmExt: BmPoiExtension(
      type: ext.type,
      distanceKm: ext.distanceKm,
      displayOrder: ext.displayOrder,
      schedule: BmSchedule(
        arrival: ext.schedule.arrival?.add(delta),
        departure: ext.schedule.departure?.add(delta),
        close: ext.schedule.close?.add(delta),
        result: ext.schedule.result?.add(delta),
      ),
    ),
  );
}

/// 新規 POI の BmPoiExtension を生成する（arrival/departure/close が未指定なら null）
Future<BmPoiExtension?> _buildBmPoiExtForAdd({
  required AddPoiFormData data,
  double? km,
}) async {
  if (data.arrival == null && data.departure == null && data.close == null) {
    return null;
  }
  return BmPoiExtension(
    type: data.type == UserPoiType.checkpoint.value ? 'checkpoint' : 'generic',
    distanceKm: km ?? 0,
    schedule: BmSchedule(
      arrival: data.arrival,
      departure: data.departure,
      close: data.close,
    ),
  );
}

/// 既存 POI の BmPoiExtension を更新する。arrival/departure/close を上書きし、result・type は保持する。
/// 距離は編集フォーム（[AddPoiFormData.km]）を正とする。空欄なら [BmPoiExtension.distanceKm] は 0。
/// EditPoiTextDialog は既存値で初期化されるため、data.arrival/departure/close が最終状態（null = クリア済み）。
Future<BmPoiExtension?> _buildBmPoiExtForEdit({
  required AddPoiFormData data,
  BmPoiExtension? existing,
}) async {
  if (existing == null &&
      data.arrival == null &&
      data.departure == null &&
      data.close == null) {
    return null;
  }
  return BmPoiExtension(
    type: existing?.type ??
        (data.type == UserPoiType.checkpoint.value ? 'checkpoint' : 'generic'),
    distanceKm: data.km ?? 0,
    schedule: BmSchedule(
      arrival: data.arrival,
      departure: data.departure,
      close: data.close,
      result: existing?.schedule.result,
    ),
  );
}

/// スタートの出発に対応するゴール `close`（[BmBrevetMeta.timeLimitHours]）。[gpx_import_service] の finish と同じ要領。
DateTime? _closeForFinishFromStartDeparture({
  required DateTime? startDeparture,
  BmBrevetMeta? meta,
  required double totalRouteKm,
}) {
  if (startDeparture == null) return null;
  if (totalRouteKm < kMinRouteKmForFinishClose) return null;
  final h = meta?.timeLimitHours ?? 0.0;
  if (h <= 0) return null;
  return startDeparture.add(Duration(minutes: (h * 60).round()));
}

UserPoi _userPoiWithFinishClose(UserPoi p, DateTime? close) {
  final ext = p.bmExt;
  if (ext == null) return p;
  return UserPoi(
    type: p.type,
    km: p.km,
    title: p.title,
    body: p.body,
    url: p.url,
    lat: p.lat,
    lng: p.lng,
    gpxCmt: p.gpxCmt,
    gpxType: p.gpxType,
    isNote: p.isNote,
    bmExt: BmPoiExtension(
      type: ext.type,
      distanceKm: ext.distanceKm,
      displayOrder: ext.displayOrder,
      schedule: BmSchedule(
        arrival: ext.schedule.arrival,
        departure: ext.schedule.departure,
        close: close,
        result: ext.schedule.result,
      ),
    ),
  );
}

/// スタートの基準日時（出発が設定されていれば出発、なければ到着）を起点に全POIの日時を再計算する。
/// ルール2: 各POI出発 = 到着 + 15分
/// ルール3: ゴールのクローズ = [finishClose]（スタート基準日時 + 制限時間）
/// ルール4: 各POI到着 = スタート基準日時 + estimateArrivalFromRouteStart（km・標高から算出）
/// km 未設定・isNote の POI はそのままにする。スタートPOI は変更しない。
List<UserPoi> _recalculatePoiSchedules({
  required List<UserPoi> pois,
  required DateTime? startDeparture,
  required DateTime? finishClose,
  required List<LatLng>? trackPoints,
  required List<double?>? trackElevations,
}) {
  final result = pois.map((poi) {
    final ext = poi.bmExt;
    if (ext == null) return poi;

    if (GpxPoiTag.isStartType(ext.type)) return poi;

    if (startDeparture == null || poi.km == null || poi.isNote) {
      return GpxPoiTag.isFinishType(ext.type)
          ? _userPoiWithFinishClose(poi, finishClose)
          : poi;
    }

    double elevM = 0.0;
    if (trackPoints != null &&
        trackPoints.isNotEmpty &&
        trackElevations != null &&
        trackElevations.length == trackPoints.length) {
      final trackIdx = nearestTrackIndex(trackPoints, poi.position);
      elevM = elevationGainBetweenIndices(trackElevations, 0, trackIdx);
    }

    final estimated = estimateArrivalFromRouteStart(
      brevetStartTimeUtc: startDeparture,
      distanceKm: poi.km!,
      elevationGainFromStartMeters: elevM,
    );

    if (estimated == null) {
      return GpxPoiTag.isFinishType(ext.type)
          ? _userPoiWithFinishClose(poi, finishClose)
          : poi;
    }

    return UserPoi(
      type: poi.type,
      km: poi.km,
      title: poi.title,
      body: poi.body,
      url: poi.url,
      lat: poi.lat,
      lng: poi.lng,
      gpxCmt: poi.gpxCmt,
      gpxType: poi.gpxType,
      isNote: poi.isNote,
      bmExt: BmPoiExtension(
        type: ext.type,
        distanceKm: ext.distanceKm,
        displayOrder: ext.displayOrder,
        schedule: BmSchedule(
          arrival: estimated,
          departure: GpxPoiTag.isFinishType(ext.type)
              ? null
              : estimated.add(const Duration(minutes: 15)),
          close: GpxPoiTag.isFinishType(ext.type)
              ? finishClose
              : ext.schedule.close,
          result: ext.schedule.result,
        ),
      ),
    );
  }).toList();

  // 15分丸めにより前POIの出発 >= 後POIの到着になる場合を補正する。
  // 前POIの出発以降になるまで15分ずつ繰り上げる。
  DateTime? prevDeparture;
  for (var i = 0; i < result.length; i++) {
    final poi = result[i];
    final ext = poi.bmExt;
    if (ext == null || GpxPoiTag.isStartType(ext.type)) {
      prevDeparture = ext?.schedule.departure;
      continue;
    }
    final arr = ext.schedule.arrival;
    if (arr != null && prevDeparture != null && !arr.isAfter(prevDeparture)) {
      // 前POI出発より後になるまで15分単位で繰り上げる
      var newArr = prevDeparture.add(const Duration(minutes: 15));
      result[i] = UserPoi(
        type: poi.type,
        km: poi.km,
        title: poi.title,
        body: poi.body,
        url: poi.url,
        lat: poi.lat,
        lng: poi.lng,
        gpxCmt: poi.gpxCmt,
        gpxType: poi.gpxType,
        isNote: poi.isNote,
        bmExt: BmPoiExtension(
          type: ext.type,
          distanceKm: ext.distanceKm,
          displayOrder: ext.displayOrder,
          schedule: BmSchedule(
            arrival: newArr,
            departure: ext.schedule.departure != null
                ? newArr.add(const Duration(minutes: 15))
                : null,
            close: ext.schedule.close,
            result: ext.schedule.result,
          ),
        ),
      );
      prevDeparture = result[i].bmExt?.schedule.departure;
    } else {
      prevDeparture = ext.schedule.departure;
    }
  }
  return result;
}

/// POI追加メニューがタップされたときのエントリポイント。
/// 戻り値で何が選択されたかを返す（null = キャンセル）。
Future<Object?> showPoiManagementDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  return showDialog<Object>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const PoiManagementDialog(),
  );
}

/// 距離入力でPOI追加のフロー（ダイアログ表示→登録）。「次へ」はダイアログ内でフォームリセット。
Future<void> handleDistanceInputPoiAdd(
  BuildContext context,
  WidgetRef ref, {
  bool transparentBarrier = false,
}) async {
  if (!context.mounted) return;
  final distanceUnit = ref.read(distanceUnitProvider);
  final routePoints = ref.read(mapStateProvider).savedRoutePoints;
  if (routePoints == null || routePoints.isEmpty) {
    if (!context.mounted) return;
    showAppSnackBar(context, AppLocalizations.of(context)!.routeNotLoaded);
    return;
  }
  final totalRouteKm =
      distanceAlongTrackFromStart(routePoints, routePoints.length - 1) / 1000;

  await showDialog<void>(
    context: context,
    barrierColor: transparentBarrier ? Colors.transparent : Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => DistanceInputPoiDialog(
      distanceUnit: distanceUnit,
      totalRouteKm: totalRouteKm,
      onSave: (data) async {
        final coord = coordAtKm(routePoints, data.km!);
        if (coord == null) {
          if (context.mounted) {
            showAppSnackBar(
                context, AppLocalizations.of(context)!.kmPointNotFound);
          }
          return;
        }
        final bmExt = await _buildBmPoiExtForAdd(data: data, km: data.km);
        final poi = UserPoi(
          type: data.type,
          km: data.km,
          title: data.title,
          body: data.body,
          url: data.url,
          lat: coord.latitude,
          lng: coord.longitude,
          bmExt: bmExt,
          isNote: data.isNote,
        );
        await ref.read(mapStateProvider.notifier).addUserPoi(poi);
        if (context.mounted) {
          showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
        }
      },
    ),
  );
}

/// [MapTapPoiAddDialog] の入力から [UserPoi] を生成する（共有 URL プレビューからも利用）。
Future<UserPoi> userPoiFromMapTapAddForm({
  required AddPoiFormData data,
  required LatLng position,
}) async {
  final bmExt = await _buildBmPoiExtForAdd(data: data, km: data.km);
  final url = data.url.trim();
  return UserPoi(
    type: data.type,
    km: data.km,
    title: data.title,
    body: data.body,
    url: url.isEmpty ? null : url,
    lat: position.latitude,
    lng: position.longitude,
    bmExt: bmExt,
    isNote: data.isNote,
  );
}

/// 地図ロングプレスでPOI追加（地図タップモード時）。「次へ」はダイアログ内でフォームリセット。
Future<void> handleMapLongPressPoiAdd(
  BuildContext context,
  WidgetRef ref,
  LatLng position, {
  String? initialTitle,
  required VoidCallback onComplete,
}) async {
  if (!context.mounted) return;

  final distanceUnit = ref.read(distanceUnitProvider);
  final routePoints = ref.read(mapStateProvider).savedRoutePoints;
  final totalRouteKm = routePoints != null && routePoints.isNotEmpty
      ? distanceAlongTrackFromStart(routePoints, routePoints.length - 1) / 1000
      : null;
  String? initialKmText;
  if (routePoints != null && routePoints.isNotEmpty) {
    final opts = alongTrackTapOptionsForPoint(routePoints, position);
    if (opts.length > 1) {
      if (!context.mounted) return;
      final picked = await showOverlappingRouteLegPickDialog(
        context,
        options: opts,
        distanceUnit: distanceUnit,
      );
      if (picked == null || !context.mounted) {
        onComplete();
        return;
      }
      initialKmText = formatDistanceNumeric(
        opts[picked].alongTrackM / 1000,
        distanceUnit,
      );
    } else {
      initialKmText = formatDistanceNumeric(
        opts.single.alongTrackM / 1000,
        distanceUnit,
      );
    }
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => MapTapPoiAddDialog(
      initialTitle: initialTitle,
      distanceUnit: distanceUnit,
      totalRouteKm: totalRouteKm,
      initialKmText: initialKmText,
      onSave: (data) async {
        final poi =
            await userPoiFromMapTapAddForm(data: data, position: position);
        await ref.read(mapStateProvider.notifier).addUserPoi(poi);
        if (context.mounted) {
          showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
        }
      },
    ),
  );
  onComplete();
}

/// POIテキスト編集フロー
Future<void> handleEditPoiText(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi, {
  bool transparentBarrier = false,
}) async {
  if (!context.mounted) return;
  final distanceUnit = ref.read(distanceUnitProvider);
  final mapState = ref.read(mapStateProvider);
  final brevetMeta = await loadBrevetMeta();
  if (!context.mounted) return;
  final routePoints = mapState.savedRoutePoints;
  final totalRouteKm = routePoints != null && routePoints.isNotEmpty
      ? distanceAlongTrackFromStart(routePoints, routePoints.length - 1) / 1000
      : null;

  double? elevationGainFor(UserPoi p) {
    if (p.isNote) return null;
    final ms = ref.read(mapStateProvider);
    final gains = ms.cachedPoiElevationGains;
    final orderedForGain = ms.userPois;
    if (gains == null) return null;
    final idx = UserPoi.indexInList(orderedForGain, p);
    if (idx < 0 || idx >= gains.length) return null;
    return gains[idx];
  }

  double? elevationLossFor(UserPoi p) {
    if (p.isNote) return null;
    final ms = ref.read(mapStateProvider);
    final losses = ms.cachedPoiElevationLosses;
    final ordered = ms.userPois;
    if (losses == null) return null;
    final idx = UserPoi.indexInList(ordered, p);
    if (idx < 0 || idx >= losses.length) return null;
    return losses[idx];
  }

  List<UserPoi> orderedPois() => List<UserPoi>.from(
        ref.read(mapStateProvider).userPois,
      );

  UserPoi? findNext(UserPoi current) {
    final list = orderedPois();
    final idx = UserPoi.indexInList(list, current);
    if (idx >= 0 && idx + 1 < list.length) return list[idx + 1];
    return null;
  }

  UserPoi? findPrev(UserPoi current) {
    final list = orderedPois();
    final idx = UserPoi.indexInList(list, current);
    if (idx > 0) return list[idx - 1];
    return null;
  }

  Future<UserPoi?> saveAndFind(
      UserPoi currentPoi, AddPoiFormData data, bool goNext) async {
    LatLng? coord;
    final kmChanged = data.km != currentPoi.km;
    if (kmChanged &&
        data.km != null &&
        routePoints != null &&
        routePoints.isNotEmpty) {
      coord = coordAtKm(routePoints, data.km!);
    }
    final newBmExt =
        await _buildBmPoiExtForEdit(data: data, existing: currentPoi.bmExt);
    final updatedPoi = UserPoi(
      type: data.type,
      km: data.km,
      title: data.title,
      body: data.body,
      url: data.url,
      lat: coord?.latitude ?? currentPoi.lat,
      lng: coord?.longitude ?? currentPoi.lng,
      gpxCmt: currentPoi.gpxCmt,
      gpxType: currentPoi.gpxType,
      bmExt: newBmExt,
      isNote: data.isNote,
    );
    final isStartPoi = currentPoi.bmExt?.type == 'start';
    final newArrival = updatedPoi.bmExt?.schedule.arrival;
    final oldArrival = currentPoi.bmExt?.schedule.arrival;
    final newDeparture = updatedPoi.bmExt?.schedule.departure;
    final oldDeparture = currentPoi.bmExt?.schedule.departure;
    // スタートPOI: 出発が設定されていればそれを基準、未設定なら到着を基準にする
    final newStartBase = newDeparture ?? newArrival;
    final oldStartBase = oldDeparture ?? oldArrival;
    // arrival 変化を優先し、arrival が変わらず departure だけ変わった場合は departure 差分を使う
    final scheduleDelta = !isStartPoi
        ? (newArrival != null && oldArrival != null && newArrival != oldArrival)
            ? newArrival.difference(oldArrival)
            : (newDeparture != null &&
                    oldDeparture != null &&
                    newDeparture != oldDeparture)
                ? newDeparture.difference(oldDeparture)
                : null
        : null;

    if (isStartPoi && newStartBase != oldStartBase) {
      final tr = totalRouteKm ?? 0.0;
      final meta = await loadBrevetMeta();
      final newClose = _closeForFinishFromStartDeparture(
        startDeparture: newStartBase,
        meta: meta,
        totalRouteKm: tr,
      );
      final list = List<UserPoi>.from(ref.read(mapStateProvider).userPois);
      final startIdx = UserPoi.indexInList(list, currentPoi);
      if (startIdx < 0) {
        await ref
            .read(mapStateProvider.notifier)
            .updateUserPoi(currentPoi, updatedPoi);
      } else {
        list[startIdx] = updatedPoi;
        final ms = ref.read(mapStateProvider);
        final recalculated = _recalculatePoiSchedules(
          pois: list,
          startDeparture: newStartBase,
          finishClose: newClose,
          trackPoints: ms.savedRoutePoints,
          trackElevations: ms.savedTrackElevations,
        );
        await ref
            .read(mapStateProvider.notifier)
            .replaceAllUserPois(recalculated);
      }
    } else if (scheduleDelta != null) {
      final list = List<UserPoi>.from(ref.read(mapStateProvider).userPois);
      final editIdx = UserPoi.indexInList(list, currentPoi);
      if (editIdx < 0) {
        await ref
            .read(mapStateProvider.notifier)
            .updateUserPoi(currentPoi, updatedPoi);
      } else {
        list[editIdx] = updatedPoi;
        for (var i = editIdx + 1; i < list.length; i++) {
          final p = list[i];
          final e = p.bmExt;
          if (e == null) continue;
          final s = e.schedule;
          if (s.arrival == null && s.departure == null) continue;
          list[i] = UserPoi(
            type: p.type,
            km: p.km,
            title: p.title,
            body: p.body,
            url: p.url,
            lat: p.lat,
            lng: p.lng,
            gpxCmt: p.gpxCmt,
            gpxType: p.gpxType,
            isNote: p.isNote,
            bmExt: BmPoiExtension(
              type: e.type,
              distanceKm: e.distanceKm,
              displayOrder: e.displayOrder,
              schedule: BmSchedule(
                arrival: s.arrival?.add(scheduleDelta),
                departure: s.departure?.add(scheduleDelta),
                close: s.close,
                result: s.result,
              ),
            ),
          );
        }
        await ref.read(mapStateProvider.notifier).replaceAllUserPois(list);
      }
    } else {
      await ref
          .read(mapStateProvider.notifier)
          .updateUserPoi(currentPoi, updatedPoi);
    }
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.poiUpdated);
    }
    return goNext ? findNext(updatedPoi) : findPrev(updatedPoi);
  }

  double? elevationGainFromRouteStart(UserPoi p) {
    final ms = ref.read(mapStateProvider);
    final pts = ms.savedRoutePoints;
    final elevs = ms.savedTrackElevations;
    if (pts == null ||
        pts.isEmpty ||
        elevs == null ||
        elevs.length != pts.length) {
      return null;
    }
    final i = nearestTrackIndex(pts, p.position);
    return elevationGainBetweenIndices(elevs, 0, i);
  }

  await showDialog<void>(
    context: context,
    barrierColor: transparentBarrier ? Colors.transparent : Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => EditPoiTextDialog(
      ref: ref,
      poi: poi,
      distanceUnit: distanceUnit,
      totalRouteKm: totalRouteKm,
      brevetStartTimeUtc: brevetMeta?.startTime,
      elevationGainFromRouteStart: elevationGainFromRouteStart,
      elevationGainFor: elevationGainFor,
      elevationLossFor: elevationLossFor,
      findPreviousPoi: findPrev,
      onNext: findNext,
      onPrev: findPrev,
      onSave: (poi, data) => saveAndFind(poi, data, true),
      onSavePrev: (poi, data) => saveAndFind(poi, data, false),
    ),
  );
}

/// POI位置編集（ドラッグ）の開始
Future<void> handleStartEditPoiPosition(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi, {
  required VoidCallback onStartDragMode,
  required void Function(UserPoi poi, LatLng newLatLng) onDragEnd,
}) async {
  if (!context.mounted) return;
  onStartDragMode();
  await ref.read(cameraControllerProvider.notifier).animateTo(
        poi.position,
        zoom: 16.0,
      );
  if (!context.mounted) return;
  await ref.read(mapStateProvider.notifier).startPoiDrag(poi, (newLatLng) {
    onDragEnd(poi, newLatLng);
  });
}

/// POIドラッグ終了時の処理
Future<void> handlePoiDragEnd(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi,
  LatLng newLatLng, {
  required VoidCallback onStopDragMode,
}) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context,
    message: l10n.changePoiPosition,
    cancelText: l10n.cancel,
    confirmText: l10n.change,
  );

  await ref.read(mapStateProvider.notifier).stopPoiDrag();
  if (!context.mounted) return;
  onStopDragMode();
  if (confirmed != true) return;

  final updatedPoi = UserPoi(
    type: poi.type,
    km: poi.km,
    title: poi.title,
    body: poi.body,
    url: poi.url,
    lat: newLatLng.latitude,
    lng: newLatLng.longitude,
    gpxCmt: poi.gpxCmt,
    gpxType: poi.gpxType,
    bmExt: poi.bmExt,
    isNote: poi.isNote,
  );
  await ref.read(mapStateProvider.notifier).updateUserPoi(poi, updatedPoi);
  if (!context.mounted) return;
  showAppSnackBar(context, AppLocalizations.of(context)!.poiPositionChanged);
}

// ---------------------------------------------------------------------------
// 距離入力でPOI登録ダイアログ
// ---------------------------------------------------------------------------

class DistanceInputPoiDialog extends StatefulWidget {
  const DistanceInputPoiDialog({
    super.key,
    required this.distanceUnit,
    required this.totalRouteKm,
    required this.onSave,
  });
  final int distanceUnit;
  final double totalRouteKm;
  final Future<void> Function(AddPoiFormData data) onSave;

  @override
  State<DistanceInputPoiDialog> createState() => _DistanceInputPoiDialogState();
}

class _DistanceInputPoiDialogState extends State<DistanceInputPoiDialog> {
  int _poiType = 0;
  final _kmController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _urlController = TextEditingController();
  String? _kmError;
  late final FocusNode _kmFocusNode;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kmFocusNode = FocusNode();
    _kmFocusNode.addListener(_onKmFocusChange);
  }

  void _onKmFocusChange() {
    if (_kmFocusNode.hasFocus && _kmError != null && mounted) {
      setState(() => _kmError = null);
    }
  }

  @override
  void dispose() {
    _kmFocusNode.removeListener(_onKmFocusChange);
    _kmFocusNode.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  AddPoiFormData? _validate() {
    final value = double.tryParse(_kmController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmRequired);
      return null;
    }
    final km = widget.distanceUnit == 1 ? value * kmPerMile : value;
    if (km > widget.totalRouteKm + 5) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmExceedsRoute);
      return null;
    }
    setState(() => _kmError = null);
    return AddPoiFormData(
      km: km,
      type: _poiType,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      url: _urlController.text.trim(),
      isNote: false,
    );
  }

  Future<void> _handleAdd() async {
    FocusScope.of(context).unfocus();
    final data = _validate();
    if (data == null) return;
    setState(() => _saving = true);
    await widget.onSave(data);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _kmController,
                      focusNode: _kmFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        if (_kmError != null) setState(() => _kmError = null);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        errorText: _kmError != null ? ' ' : null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _kmError != null
                          ? Text(
                              _kmError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            )
                          : Text(
                              widget.distanceUnit == 1 ? 'mi' : 'km',
                              style: AppTextStyles.title,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(l10n.poiType, style: AppTextStyles.body),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: DropdownButtonFormField<int>(
                    value: _normalizePoiTypeForForm(_poiType),
                    menuMaxHeight: 360,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    items: _buildPoiTypeDropdownItems(l10n),
                    onChanged: (value) {
                      if (value == null) return;
                      FocusScope.of(context).unfocus();
                      setState(() => _poiType = value);
                    },
                    style: AppTextStyles.body.copyWith(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: l10n.body,
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel, style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _handleAdd,
                    child: Text(l10n.add, style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POI管理ダイアログ（タブ：追加 / 編集）
// ---------------------------------------------------------------------------

class PoiManagementDialog extends ConsumerStatefulWidget {
  const PoiManagementDialog({super.key});

  @override
  ConsumerState<PoiManagementDialog> createState() =>
      _PoiManagementDialogState();
}

class _PoiManagementDialogState extends ConsumerState<PoiManagementDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final premium = await isEffectivePremium();
      if (!mounted) return;
      setState(() => _isPremium = premium);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showPoiPremiumDialog() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final viewPlans = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.poiPremiumMessage, style: AppTextStyles.body),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child:
                        Text(l10n.trialInfoClose, style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.poiPremiumViewPlans,
                        style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (viewPlans == true && mounted) {
      await RevenueCatUI.presentPaywall();
      await _loadPremiumStatus();
    }
  }

  Widget _buildAddTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.poiAddByDistance,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () async {
              await handleDistanceInputPoiAdd(
                context,
                ref,
                transparentBarrier: true,
              );
            },
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.poiAddByMapTap,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(context, const MapTapAddRequest()),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.changeRideDate,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: _handleChangeRideDate,
          ),
        ],
      ),
    );
  }

  Future<void> _handleChangeRideDate() async {
    final l10n = AppLocalizations.of(context)!;
    final meta = await loadBrevetMeta();
    if (!mounted) return;
    final initialDate = meta?.startTime?.toLocal() ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: l10n.setStartDate,
    );
    if (selectedDate == null || !mounted) return;
    final newStartTime =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6)
            .toUtc();
    await saveBrevetMeta(BmBrevetMeta(
      distanceKm: meta?.distanceKm ?? 0,
      startTime: newStartTime,
      timeLimitHours: meta?.timeLimitHours ?? 0,
    ));
    if (!mounted) return;
    final oldStartTime = meta?.startTime;
    if (oldStartTime != null) {
      final oldDate = DateTime(oldStartTime.toLocal().year,
          oldStartTime.toLocal().month, oldStartTime.toLocal().day);
      final newDate =
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final delta = newDate.difference(oldDate);
      if (delta != Duration.zero) {
        final pois = ref.read(mapStateProvider).userPois;
        final shifted = pois.map((p) => _shiftPoiSchedule(p, delta)).toList();
        await ref.read(mapStateProvider.notifier).replaceAllUserPois(shifted);
      }
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _onEditTap(UserPoi poi) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showTextMenuDialog(
      context,
      items: [
        l10n.changePoiTextTitle,
        l10n.changePoiPositionTitle,
      ],
    );
    if (action == null || !mounted) return;
    if (action == 0) {
      if (!_isPremium) {
        await _showPoiPremiumDialog();
        if (!_isPremium || !mounted) return;
      }
      // タブ式ダイアログは閉じず、その上に編集ダイアログを重ねる
      await handleEditPoiText(
        context,
        ref,
        poi,
        transparentBarrier: true,
      );
    } else {
      Navigator.pop(context, PoiEditPositionRequest(poi));
    }
  }

  Future<void> _onDeleteTap(UserPoi poi) async {
    if (!_isPremium) {
      await _showPoiPremiumDialog();
      if (!_isPremium || !mounted) return;
    }
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.deletePoiConfirm,
      cancelText: l10n.cancel,
      confirmText: l10n.delete,
    );
    if (confirmed != true || !mounted) return;

    await ref.read(mapStateProvider.notifier).deleteUserPoi(poi);
    if (!mounted) return;

    showAppSnackBar(context, AppLocalizations.of(context)!.poiDeleted);

    if (ref.read(mapStateProvider).userPois.isEmpty) {
      Navigator.pop(context);
    }
  }

  Widget _buildEditTab() {
    final userPois = ref.watch(mapStateProvider).userPois;
    final distanceUnit = ref.watch(distanceUnitProvider);
    if (userPois.isEmpty) {
      return Align(
        alignment: const Alignment(0, -0.2),
        child: Text(
          AppLocalizations.of(context)!.noPoiRegistered,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: true,
      itemCount: userPois.length,
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final reordered =
            List<UserPoi>.from(ref.read(mapStateProvider).userPois);
        final item = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, item);
        unawaited(
          ref.read(mapStateProvider.notifier).replaceAllUserPois(reordered),
        );
      },
      itemBuilder: (context, i) {
        final poi = userPois[i];
        final distStr =
            poi.km != null ? formatDistance(poi.km!, distanceUnit) : null;
        return Material(
          key: ObjectKey(poi),
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
              ),
            ),
            child: InkWell(
              onTap: () => _onEditTap(poi),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        distStr != null
                            ? '$distStr : ${poi.title.isEmpty ? AppLocalizations.of(context)!.titleNone : poi.title}'
                            : (poi.title.isEmpty
                                ? AppLocalizations.of(context)!.titleNone
                                : poi.title),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _onDeleteTap(poi),
                      icon: const Icon(Icons.cancel,
                          size: 20, color: Colors.black45),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTextStyles.bodySmall,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.poiTabAdd),
                Tab(text: AppLocalizations.of(context)!.poiTabEdit),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAddTab(),
                  _buildEditTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 往復重複地点: POI登録の前に往路/復路の距離基準を選ぶ
// ---------------------------------------------------------------------------

Future<int?> showOverlappingRouteLegPickDialog(
  BuildContext context, {
  required List<AlongTrackTapOption> options,
  required int distanceUnit,
}) {
  assert(options.length > 1);
  return showDialog<int>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (ctx) => _OverlappingRouteLegPickDialog(
      options: options,
      distanceUnit: distanceUnit,
    ),
  );
}

class _OverlappingRouteLegPickDialog extends StatefulWidget {
  const _OverlappingRouteLegPickDialog({
    required this.options,
    required this.distanceUnit,
  });

  final List<AlongTrackTapOption> options;
  final int distanceUnit;

  @override
  State<_OverlappingRouteLegPickDialog> createState() =>
      _OverlappingRouteLegPickDialogState();
}

class _OverlappingRouteLegPickDialogState
    extends State<_OverlappingRouteLegPickDialog> {
  /// デフォルトは index 0（往路側の候補が先に並ぶ想定）
  int _selectedIndex = 0;

  static String _legLabel(AppLocalizations l10n, RouteLeg leg) {
    switch (leg) {
      case RouteLeg.outbound:
        return l10n.routeLegOutboundShort;
      case RouteLeg.returnRoute:
        return l10n.routeLegReturnShort;
      case RouteLeg.ambiguous:
        return l10n.routeLegAmbiguousShort;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compactButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<int>(
            groupValue: _selectedIndex,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedIndex = v);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.options.length; i++) ...[
                  if (i > 0) const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = i),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Radio<int>(
                          value: i,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        Expanded(
                          child: Text(
                            '${formatDistanceNumeric(widget.options[i].alongTrackM / 1000, widget.distanceUnit)} ${widget.distanceUnit == 1 ? 'mi' : 'km'} : ${_legLabel(l10n, widget.options[i].leg)}',
                            style: AppTextStyles.title,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.pop(context, _selectedIndex),
          child: Text(l10n.ok, style: AppTextStyles.button),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 地図タップでPOI登録ダイアログ（距離・メモフラグ）
// ---------------------------------------------------------------------------

class MapTapPoiAddDialog extends StatefulWidget {
  const MapTapPoiAddDialog({
    super.key,
    this.initialTitle,
    required this.distanceUnit,
    this.totalRouteKm,
    this.initialKmText,
    required this.onSave,
  });

  final String? initialTitle;
  final int distanceUnit;

  /// ルート沿い長さ（km）。null のときは距離上限チェックを省略。
  final double? totalRouteKm;

  /// 距離フィールドの初期表示（ユーザー設定単位の数値文字列）。
  final String? initialKmText;

  final Future<void> Function(AddPoiFormData data) onSave;

  @override
  State<MapTapPoiAddDialog> createState() => _MapTapPoiAddDialogState();
}

class _MapTapPoiAddDialogState extends State<MapTapPoiAddDialog> {
  int _poiType = 0;
  final _kmController = TextEditingController();
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  final _urlController = TextEditingController();
  String? _kmError;
  late final FocusNode _kmFocusNode;
  bool _saveAsNote = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _kmFocusNode = FocusNode();
    _kmFocusNode.addListener(_onKmFocusChange);
    if (widget.initialKmText != null && widget.initialKmText!.isNotEmpty) {
      _kmController.text = widget.initialKmText!;
    }
    _titleController =
        TextEditingController(text: widget.initialTitle?.trim() ?? '');
  }

  void _onKmFocusChange() {
    if (_kmFocusNode.hasFocus && _kmError != null && mounted) {
      setState(() => _kmError = null);
    }
  }

  @override
  void dispose() {
    _kmFocusNode.removeListener(_onKmFocusChange);
    _kmFocusNode.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  AddPoiFormData? _validate() {
    final value = double.tryParse(_kmController.text.trim());
    if (value == null || value <= 0) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmRequired);
      return null;
    }
    final km = widget.distanceUnit == 1 ? value * kmPerMile : value;
    final cap = widget.totalRouteKm;
    if (cap != null && km > cap + 5) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmExceedsRoute);
      return null;
    }
    setState(() => _kmError = null);
    return AddPoiFormData(
      km: km,
      type: _poiType,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      url: _urlController.text.trim(),
      isNote: _saveAsNote,
    );
  }

  Future<void> _handleAdd() async {
    FocusScope.of(context).unfocus();
    final data = _validate();
    if (data == null) return;
    setState(() => _saving = true);
    await widget.onSave(data);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _kmController,
                      focusNode: _kmFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) {
                        if (_kmError != null) setState(() => _kmError = null);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.distance,
                        isDense: true,
                        errorText: _kmError != null ? ' ' : null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _kmError != null
                          ? Text(
                              _kmError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            )
                          : Text(
                              widget.distanceUnit == 1 ? 'mi' : 'km',
                              style: AppTextStyles.title,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.poiType, style: AppTextStyles.body),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: DropdownButtonFormField<int>(
                    value: _normalizePoiTypeForForm(_poiType),
                    menuMaxHeight: 360,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    items: _buildPoiTypeDropdownItems(l10n),
                    onChanged: (value) {
                      if (value == null) return;
                      FocusScope.of(context).unfocus();
                      setState(() => _poiType = value);
                    },
                    style: AppTextStyles.body.copyWith(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.title,
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: l10n.body,
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  isDense: true,
                  contentPadding: _kPoiTitleBodyFieldContentPadding,
                ),
                style: AppTextStyles.poiFormTitleBody,
              ),
              const SizedBox(height: 15),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _saving
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          setState(() => _saveAsNote = !_saveAsNote);
                        },
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _saveAsNote,
                        onChanged: _saving
                            ? null
                            : (v) {
                                FocusScope.of(context).unfocus();
                                setState(() => _saveAsNote = v ?? true);
                              },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: Text(
                          l10n.poiSaveAsNote,
                          style: AppTextStyles.checkBoxLabel,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: Text(l10n.cancel, style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _handleAdd,
                    child: Text(l10n.add, style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POIテキスト編集ダイアログ
// ---------------------------------------------------------------------------

class EditPoiTextDialog extends StatefulWidget {
  const EditPoiTextDialog({
    super.key,
    required this.ref,
    required this.poi,
    required this.distanceUnit,
    this.totalRouteKm,
    this.brevetStartTimeUtc,
    this.elevationGainFromRouteStart,
    this.elevationGainFor,
    this.elevationLossFor,
    this.findPreviousPoi,
    required this.onNext,
    required this.onPrev,
    required this.onSave,
    required this.onSavePrev,
  });

  final WidgetRef ref;

  final UserPoi poi;
  final int distanceUnit;
  final double? totalRouteKm;

  /// [loadBrevetMeta] のスタート時刻（UTC）。到着の自動推定に使う。
  final DateTime? brevetStartTimeUtc;

  /// ルート始点から当該 POI までの累積獲得標高（m）。トラック標高が無ければ null を返す。
  final double? Function(UserPoi)? elevationGainFromRouteStart;

  /// 指定 POI の獲得標高（m）を返す。null なら非表示。
  final double? Function(UserPoi)? elevationGainFor;

  /// 指定 POI の獲得下降（m）を返す。null なら非表示。
  final double? Function(UserPoi)? elevationLossFor;

  /// 一覧順で直前の POI（同一ルート上の前チェックポイント）。区間距離計算用。
  final UserPoi? Function(UserPoi currentPoi)? findPreviousPoi;

  /// 保存せずに次のPOIを返す。なければ null。
  final UserPoi? Function(UserPoi currentPoi) onNext;

  /// 保存せずに前のPOIを返す。なければ null。
  final UserPoi? Function(UserPoi currentPoi) onPrev;

  /// 保存して次のPOIを返す。なければ null。
  final Future<UserPoi?> Function(UserPoi currentPoi, AddPoiFormData data)
      onSave;

  /// 保存して前のPOIを返す。なければ null。
  final Future<UserPoi?> Function(UserPoi currentPoi, AddPoiFormData data)
      onSavePrev;

  @override
  State<EditPoiTextDialog> createState() => _EditPoiTextDialogState();
}

class _EditPoiTextDialogState extends State<EditPoiTextDialog> {
  late UserPoi _currentPoi;
  late int _poiType;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _urlController;
  late final TextEditingController _kmController;
  late final FocusNode _kmFocusNode;
  late final FocusNode _dummyFocusNode;
  String? _kmError;
  DateTime? _arrival;
  DateTime? _departure;
  DateTime? _close;
  bool _saving = false;
  bool _isNote = false;

  @override
  void initState() {
    super.initState();
    _currentPoi = widget.poi;
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _urlController = TextEditingController();
    _kmController = TextEditingController();
    _kmFocusNode = FocusNode();
    _dummyFocusNode = FocusNode();
    _kmFocusNode.addListener(_onKmFocusChange);
    _kmController.addListener(_onKmChanged);
    _loadPoiToForm(widget.poi);
  }

  /// 距離ありのとき、到着・出発を推定してフォームへ入れる。
  ///
  /// - 一覧順の**直前POI**に到着・出発があれば、その時刻から区間（距離・獲得標高差）分を足して推定する。
  /// - それ以外でブルベスタートがあれば、従来どおりスタートから全行程で推定する。
  /// 出発は到着の 15 分後（GPX インポートのチェックポイント既定と同じ）。
  /// 既に到着だけ保存されている POI では、出発が空なら到着+15分で補う。
  void _maybeAutofillScheduleFromDistance(UserPoi poi) {
    if (poi.isNote) return;
    if (poi.km == null) return;
    if (GpxPoiTag.isStartType(poi.bmExt?.type)) return;
    final start = widget.brevetStartTimeUtc;

    final isFinish = GpxPoiTag.isFinishType(poi.bmExt?.type);

    if (_arrival == null) {
      final prev = widget.findPreviousPoi?.call(poi);
      final prevSched = prev?.bmExt?.schedule;
      final anchor = prevSched?.departure ?? prevSched?.arrival;
      final canChainFromPrev = prev != null &&
          !prev.isNote &&
          prev.km != null &&
          prev.km! < poi.km! &&
          anchor != null;

      if (canChainFromPrev) {
        final segKm = poi.km! - prev.km!;
        var segElevM = 0.0;
        final gNew = widget.elevationGainFromRouteStart?.call(poi);
        final gPrev = widget.elevationGainFromRouteStart?.call(prev);
        if (gNew != null && gPrev != null) {
          segElevM = math.max(0.0, gNew - gPrev);
        }
        final minutes = brevetEstimatedTravelMinutes(
          distanceKm: segKm,
          elevationGainMeters: segElevM,
        );
        final est = anchor.add(Duration(minutes: minutes));
        _arrival = est;
        if (!isFinish) _departure ??= est.add(const Duration(minutes: 15));
        return;
      }

      if (start == null) return;

      final elevM = widget.elevationGainFromRouteStart?.call(poi) ?? 0.0;
      final est = estimateArrivalFromRouteStart(
        brevetStartTimeUtc: start,
        distanceKm: poi.km!,
        elevationGainFromStartMeters: elevM,
      );
      if (est == null) return;
      _arrival = est;
      if (!isFinish) _departure ??= est.add(const Duration(minutes: 15));
      return;
    }

    if (!isFinish && _departure == null) {
      final arrDt = poi.bmExt?.schedule.arrival;
      if (arrDt != null) {
        _departure = arrDt.add(const Duration(minutes: 15));
      }
    }
  }

  void _onKmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onKmFocusChange() {
    if (_kmFocusNode.hasFocus && _kmError != null && mounted) {
      setState(() => _kmError = null);
    }
  }

  /// メモとして保存をオンにしたとき、到着・出発予定時刻をクリアする。
  void _setIsNoteAndClearScheduleIfMemo(bool value) {
    setState(() {
      _isNote = value;
      if (value) {
        _arrival = null;
        _departure = null;
      }
    });
  }

  @override
  void dispose() {
    _kmController.removeListener(_onKmChanged);
    _kmFocusNode.removeListener(_onKmFocusChange);
    _kmFocusNode.dispose();
    _dummyFocusNode.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _kmToDisplayText(double? km) {
    if (km == null) return '';
    final displayValue = widget.distanceUnit == 1 ? (km / kmPerMile) : km;
    return displayValue % 1 == 0
        ? displayValue.toInt().toString()
        : displayValue.toStringAsFixed(1);
  }

  void _loadPoiToForm(UserPoi poi) {
    _currentPoi = poi;
    _poiType = _normalizePoiTypeForForm(poi.type);
    _titleController.text = poi.title;
    _bodyController.text = poi.body;
    _urlController.text = poi.url ?? '';
    _kmController.text = _kmToDisplayText(poi.km);
    _arrival = poi.bmExt?.schedule.arrival;
    _departure = poi.bmExt?.schedule.departure;
    _maybeAutofillScheduleFromDistance(poi);
    _close = poi.bmExt?.schedule.close;
    _kmError = null;
    _isNote = poi.isNote;
  }

  double? _parsedKmFromField() {
    final text = _kmController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value < 0) return null;
    return widget.distanceUnit == 1 ? value * kmPerMile : value;
  }

  String _segmentDistanceDisplay() {
    final ms = widget.ref.read(mapStateProvider);
    final track = ms.savedRoutePoints;
    if (track != null && track.isNotEmpty) {
      final ordered = List<UserPoi>.from(ms.userPois);
      final idx = UserPoi.indexInList(ordered, _currentPoi);
      if (idx < 0) return '--';

      final positions = ordered.map((p) => LatLng(p.lat, p.lng)).toList();
      final poiHasKm = ordered.map((p) => p.km != null && !p.isNote).toList();
      if (idx < poiHasKm.length) {
        poiHasKm[idx] = _parsedKmFromField() != null && !_isNote;
      }

      final bounds = segmentIndicesForElevationChart(
        track,
        positions,
        idx,
        poiHasDistanceKm: poiHasKm,
      );
      if (bounds == null) return '--';
      final segmentM =
          distanceAlongTrackBetweenIndices(track, bounds.lo, bounds.hi);
      return formatDistance(segmentM / 1000.0, widget.distanceUnit);
    }

    // トラックが無いときは従来どおり（累積 km の差）
    final cumulative = _parsedKmFromField();
    if (cumulative == null) return '--';
    final prev = widget.findPreviousPoi?.call(_currentPoi);
    final prevKm = prev?.km;
    final segmentKm = prevKm != null ? cumulative - prevKm : cumulative;
    final clamped = segmentKm < 0 ? 0.0 : segmentKm;
    return formatDistance(clamped, widget.distanceUnit);
  }

  String _elevationGainDisplay() {
    final raw = widget.elevationGainFor?.call(_currentPoi);
    return _elevationEditDisplay(raw, widget.distanceUnit);
  }

  String _elevationLossDisplay() {
    final raw = widget.elevationLossFor?.call(_currentPoi);
    return _elevationEditDisplay(raw, widget.distanceUnit);
  }

  Widget _segmentElevationSummaryBar() {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Colors.white,
      height: 1.25,
    );
    const iconSize = 14.0;
    const iconColor = Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
      ),
      child: Row(
        children: [
          const Icon(Icons.route, size: iconSize, color: iconColor),
          const SizedBox(width: 8),
          const Icon(Icons.swap_horiz, size: iconSize, color: iconColor),
          const SizedBox(width: 2),
          Text(
            _segmentDistanceDisplay(),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 10),
          const Icon(Icons.trending_up, size: iconSize, color: iconColor),
          const SizedBox(width: 3),
          Text(
            _elevationGainDisplay(),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 10),
          const Icon(Icons.trending_down, size: iconSize, color: iconColor),
          const SizedBox(width: 3),
          Text(
            _elevationLossDisplay(),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// 2つの DateTime が年月日時分まで一致するか（秒以下は無視）。両方 null なら true。
  bool _sameDtMinute(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year &&
        la.month == lb.month &&
        la.day == lb.day &&
        la.hour == lb.hour &&
        la.minute == lb.minute;
  }

  /// フォームの内容が元の POI から変更されているか判定する
  bool _hasChanged() {
    if (_poiType != _currentPoi.type) {
      return true;
    }
    if (_titleController.text.trim() != _currentPoi.title) {
      return true;
    }
    if (_bodyController.text.trim() != _currentPoi.body) {
      return true;
    }
    if (_urlController.text.trim() != (_currentPoi.url ?? '')) {
      return true;
    }

    if (_kmController.text.trim() != _kmToDisplayText(_currentPoi.km)) {
      return true;
    }

    if (_isNote != _currentPoi.isNote) {
      return true;
    }

    if (!_sameDtMinute(_arrival, _currentPoi.bmExt?.schedule.arrival)) {
      return true;
    }
    if (!_sameDtMinute(_departure, _currentPoi.bmExt?.schedule.departure)) {
      return true;
    }
    if (!_sameDtMinute(_close, _currentPoi.bmExt?.schedule.close)) {
      return true;
    }

    return false;
  }

  AddPoiFormData? _validate() {
    final text = _kmController.text.trim();
    final double? km;
    if (text.isEmpty) {
      km = null;
    } else {
      final value = double.tryParse(text);
      if (value == null || value < 0) {
        setState(() => _kmError = AppLocalizations.of(context)!.kmRequired);
        return null;
      }
      km = widget.distanceUnit == 1 ? value * kmPerMile : value;
      if (widget.totalRouteKm != null && km > widget.totalRouteKm! + 5) {
        setState(() => _kmError = AppLocalizations.of(context)!.kmExceedsRoute);
        return null;
      }
    }
    setState(() => _kmError = null);
    return AddPoiFormData(
      km: km,
      type: _poiType,
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      url: _urlController.text.trim(),
      arrival: _arrival,
      departure: _departure,
      close: _close,
      isNote: _isNote,
    );
  }

  Future<void> _handleChange() async {
    final data = _validate();
    if (data == null) return;
    setState(() => _saving = true);
    await widget.onSave(_currentPoi, data);
    if (!mounted) return;
    Navigator.pop(context);
  }

  /// 前のPOIへ：変更なしならそのまま移動、変更ありなら確認後に保存してから移動
  Future<void> _handlePrev() async {
    FocusScope.of(context).requestFocus(_dummyFocusNode);
    if (_hasChanged()) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showConfirmDialog(
        context,
        message: l10n.saveChangesConfirm,
        cancelText: l10n.cancel,
        confirmText: l10n.save,
      );
      if (!mounted) return;
      if (confirmed != true) return;
      final data = _validate();
      if (data == null) return;
      setState(() => _saving = true);
      final prevPoi = await widget.onSavePrev(_currentPoi, data);
      if (!mounted) return;
      if (prevPoi != null) {
        setState(() {
          _saving = false;
          _loadPoiToForm(prevPoi);
        });
      } else {
        Navigator.pop(context);
      }
      return;
    }
    final prevPoi = widget.onPrev(_currentPoi);
    if (prevPoi != null) {
      setState(() => _loadPoiToForm(prevPoi));
    } else {
      Navigator.pop(context);
    }
  }

  /// 次のPOIへ：変更なしならそのまま移動、変更ありなら確認後に保存してから移動
  Future<void> _handleNext() async {
    // ダミーノードにフォーカスを移すことで、ダイアログを閉じた際の
    // TextField へのフォーカス自動復元を防ぐ
    FocusScope.of(context).requestFocus(_dummyFocusNode);
    if (_hasChanged()) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showConfirmDialog(
        context,
        message: l10n.saveChangesConfirm,
        cancelText: l10n.cancel,
        confirmText: l10n.save,
      );
      if (!mounted) return;
      if (confirmed != true) return;
      final data = _validate();
      if (data == null) return;
      setState(() => _saving = true);
      final nextPoi = await widget.onSave(_currentPoi, data);
      if (!mounted) return;
      if (nextPoi != null) {
        setState(() {
          _saving = false;
          _loadPoiToForm(nextPoi);
        });
      } else {
        Navigator.pop(context);
      }
      return;
    }
    final nextPoi = widget.onNext(_currentPoi);
    if (nextPoi != null) {
      setState(() => _loadPoiToForm(nextPoi));
    } else {
      Navigator.pop(context);
    }
  }

  /// 日付ピッカー → 時刻ピッカーの順に表示し、両方確定したら [onPicked] を呼ぶ。
  /// 日付ピッカーでキャンセルした場合はそこで終了する。
  Future<void> _pickDateTime({
    required DateTime? current,
    required void Function(DateTime) onPicked,
  }) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final ref = (current ?? widget.brevetStartTimeUtc ?? DateTime.now().toUtc())
        .toLocal();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: ref,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: ref.hour, minute: ref.minute),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (pickedTime != null && mounted) {
      final newDt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ).toUtc();
      setState(() => onPicked(newDt));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: KeyedSubtree(
            key: ObjectKey(_currentPoi),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _kmController,
                        focusNode: _kmFocusNode,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.distance,
                          isDense: true,
                          errorText: _kmError != null ? ' ' : null,
                          errorStyle: const TextStyle(height: 0, fontSize: 0),
                        ),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontSize: 17),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _kmError != null
                            ? Text(
                                _kmError!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              )
                            : Text(
                                widget.distanceUnit == 1 ? 'mi' : 'km',
                                style: AppTextStyles.title,
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(l10n.poiType, style: AppTextStyles.body),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: DropdownButtonFormField<int>(
                      value: _normalizePoiTypeForForm(_poiType),
                      menuMaxHeight: 360,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      items: _buildPoiTypeDropdownItems(l10n),
                      onChanged: (value) {
                        if (value == null) return;
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = value);
                      },
                      style: AppTextStyles.body.copyWith(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: l10n.title,
                    isDense: true,
                    contentPadding: _kPoiTitleBodyFieldContentPadding,
                  ),
                  style: AppTextStyles.poiFormTitleBody,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    labelText: l10n.body,
                    isDense: true,
                    contentPadding: _kPoiTitleBodyFieldContentPadding,
                  ),
                  style: AppTextStyles.poiFormTitleBody,
                  maxLines: 3,
                  minLines: 3,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    isDense: true,
                    contentPadding: _kPoiTitleBodyFieldContentPadding,
                  ),
                  style: AppTextStyles.poiFormTitleBody,
                ),
                const SizedBox(height: 15),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _saving
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            _setIsNoteAndClearScheduleIfMemo(!_isNote);
                          },
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _isNote,
                          onChanged: _saving
                              ? null
                              : (v) {
                                  FocusScope.of(context).unfocus();
                                  _setIsNoteAndClearScheduleIfMemo(v ?? false);
                                },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        Expanded(
                          child: Text(
                            l10n.poiSaveAsNote,
                            style: AppTextStyles.checkBoxLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                _segmentElevationSummaryBar(),
                const SizedBox(height: 15),
                _TimePickerRow(
                  label: l10n.plannedArrival,
                  dateTime: _arrival,
                  onTap: () => _pickDateTime(
                    current: _arrival,
                    onPicked: (dt) {
                      _arrival = dt;
                      _departure = dt.add(const Duration(minutes: 15));
                    },
                  ),
                  onClear: () => setState(() => _arrival = null),
                ),
                const SizedBox(height: 8),
                _TimePickerRow(
                  label: l10n.plannedDeparture,
                  dateTime: _departure,
                  onTap: () => _pickDateTime(
                    current: _departure ?? _arrival,
                    onPicked: (dt) => _departure = dt,
                  ),
                  onClear: () => setState(() => _departure = null),
                ),
                const SizedBox(height: 8),
                _TimePickerRow(
                  label: l10n.plannedClose,
                  dateTime: _close,
                  onTap: () => _pickDateTime(
                    current: _close,
                    onPicked: (dt) => _close = dt,
                  ),
                  onClear: () => setState(() => _close = null),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          (!_saving && widget.onPrev(_currentPoi) != null)
                              ? _handlePrev
                              : null,
                      icon: const Icon(Icons.arrow_back_ios),
                      color: Colors.black38,
                      disabledColor: Colors.black12,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: Text(l10n.cancel, style: AppTextStyles.button),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _saving ? null : _handleChange,
                      child: Text(l10n.change, style: AppTextStyles.button),
                    ),
                    IconButton(
                      onPressed:
                          (!_saving && widget.onNext(_currentPoi) != null)
                              ? _handleNext
                              : null,
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: Colors.black38,
                      disabledColor: Colors.black12,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 時刻ピッカー行ウィジェット
// ---------------------------------------------------------------------------

class _TimePickerRow extends StatelessWidget {
  const _TimePickerRow({
    required this.label,
    required this.dateTime,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? dateTime;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final local = dateTime?.toLocal();
    final dateText = local != null ? '${local.month}/${local.day}' : null;
    final timeText = local != null
        ? '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.body),
        ),
        GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dateText != null) ...[
                Text(dateText, style: AppTextStyles.title),
                const SizedBox(width: 6),
              ],
              Text(timeText, style: AppTextStyles.title),
            ],
          ),
        ),
        if (dateTime != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 18, color: Colors.black38),
          ),
        ] else
          const SizedBox(width: 22),
      ],
    );
  }
}

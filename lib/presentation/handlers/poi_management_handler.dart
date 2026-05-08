// TODO: Radio を RadioGroup ベースに移行後に削除（Flutter 3.32+）
// ignore_for_file: deprecated_member_use

import 'dart:async' show unawaited;

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
    this.arrival,
    this.departure,
    this.close,
  });
  final double? km;
  final int type;
  final String title;
  final String body;
  final TimeOfDay? arrival;
  final TimeOfDay? departure;
  final TimeOfDay? close;
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

TimeOfDay? _timeOfDayFromDt(DateTime? dt) {
  if (dt == null) return null;
  final local = dt.toLocal();
  return TimeOfDay(hour: local.hour, minute: local.minute);
}

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
    lat: poi.lat,
    lng: poi.lng,
    gpxCmt: poi.gpxCmt,
    gpxType: poi.gpxType,
    bmExt: BmPoiExtension(
      type: ext.type,
      distanceKm: ext.distanceKm,
      schedule: BmSchedule(
        arrival: ext.schedule.arrival?.add(delta),
        departure: ext.schedule.departure?.add(delta),
        close: ext.schedule.close?.add(delta),
        result: ext.schedule.result?.add(delta),
      ),
    ),
  );
}

DateTime _applyTimeOfDay(TimeOfDay tod, DateTime refDate) {
  final localRef = refDate.toLocal();
  return DateTime(
          localRef.year, localRef.month, localRef.day, tod.hour, tod.minute)
      .toUtc();
}

/// 新規 POI の BmPoiExtension を生成する（arrival/departure/close が未指定なら null）
Future<BmPoiExtension?> _buildBmPoiExtForAdd({
  required AddPoiFormData data,
  double? km,
}) async {
  if (data.arrival == null && data.departure == null && data.close == null) {
    return null;
  }
  final meta = await loadBrevetMeta();
  final refDate = meta?.startTime ?? DateTime.now().toUtc();
  return BmPoiExtension(
    type: data.type == UserPoiType.checkpoint.value ? 'checkpoint' : 'generic',
    distanceKm: km ?? 0,
    schedule: BmSchedule(
      arrival:
          data.arrival != null ? _applyTimeOfDay(data.arrival!, refDate) : null,
      departure: data.departure != null
          ? _applyTimeOfDay(data.departure!, refDate)
          : null,
      close: data.close != null ? _applyTimeOfDay(data.close!, refDate) : null,
    ),
  );
}

/// 既存 POI の BmPoiExtension を更新する。arrival/departure/close を上書きし、result・type・distanceKm は保持する。
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
  DateTime? refDate;
  if (data.arrival != null || data.departure != null || data.close != null) {
    final existingArrival = existing?.schedule.arrival;
    final existingDeparture = existing?.schedule.departure;
    if (existingArrival != null) {
      refDate = existingArrival;
    } else if (existingDeparture != null) {
      refDate = existingDeparture;
    } else {
      final meta = await loadBrevetMeta();
      refDate = meta?.startTime ?? DateTime.now().toUtc();
    }
  }
  return BmPoiExtension(
    type: existing?.type ??
        (data.type == UserPoiType.checkpoint.value ? 'checkpoint' : 'generic'),
    distanceKm: existing?.distanceKm ?? data.km ?? 0,
    schedule: BmSchedule(
      arrival: data.arrival != null
          ? _applyTimeOfDay(data.arrival!, refDate!)
          : null,
      departure: data.departure != null
          ? _applyTimeOfDay(data.departure!, refDate!)
          : null,
      close: data.close != null ? _applyTimeOfDay(data.close!, refDate!) : null,
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
    lat: p.lat,
    lng: p.lng,
    gpxCmt: p.gpxCmt,
    gpxType: p.gpxType,
    bmExt: BmPoiExtension(
      type: ext.type,
      distanceKm: ext.distanceKm,
      schedule: BmSchedule(
        arrival: ext.schedule.arrival,
        departure: ext.schedule.departure,
        close: close,
        result: ext.schedule.result,
      ),
    ),
  );
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
          lat: coord.latitude,
          lng: coord.longitude,
          bmExt: bmExt,
        );
        await ref.read(mapStateProvider.notifier).addUserPoi(poi);
        if (context.mounted) {
          showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
        }
      },
    ),
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

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => MapTapPoiAddDialog(
      initialTitle: initialTitle,
      onSave: (data) async {
        final bmExt = await _buildBmPoiExtForAdd(data: data, km: null);
        final poi = UserPoi(
          type: data.type,
          km: null,
          title: data.title,
          body: data.body,
          lat: position.latitude,
          lng: position.longitude,
          bmExt: bmExt,
        );
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
  final routePoints = mapState.savedRoutePoints;
  final totalRouteKm = routePoints != null && routePoints.isNotEmpty
      ? distanceAlongTrackFromStart(routePoints, routePoints.length - 1) / 1000
      : null;

  double? elevationGainFor(UserPoi p) {
    final ms = ref.read(mapStateProvider);
    final gains = ms.cachedPoiElevationGains;
    final orderedForGain = ms.userPois;
    if (gains == null) return null;
    final idx = UserPoi.indexInList(orderedForGain, p);
    if (idx < 0 || idx >= gains.length) return null;
    return gains[idx];
  }

  double? elevationLossFor(UserPoi p) {
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
      lat: coord?.latitude ?? currentPoi.lat,
      lng: coord?.longitude ?? currentPoi.lng,
      gpxCmt: currentPoi.gpxCmt,
      gpxType: currentPoi.gpxType,
      bmExt: newBmExt,
    );
    final isStartPoi = currentPoi.bmExt?.type == 'start';
    final newStartDep = updatedPoi.bmExt?.schedule.departure;
    final oldStartDep = currentPoi.bmExt?.schedule.departure;
    final newArrival = updatedPoi.bmExt?.schedule.arrival;
    final oldArrival = currentPoi.bmExt?.schedule.arrival;
    final newDeparture = updatedPoi.bmExt?.schedule.departure;
    final oldDeparture = currentPoi.bmExt?.schedule.departure;
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

    if (isStartPoi && newStartDep != oldStartDep) {
      final tr = totalRouteKm ?? 0.0;
      final meta = await loadBrevetMeta();
      final newClose = _closeForFinishFromStartDeparture(
        startDeparture: newStartDep,
        meta: meta,
        totalRouteKm: tr,
      );
      final Duration? startCascadeDelta =
          newStartDep != null && oldStartDep != null
              ? newStartDep.difference(oldStartDep)
              : null;
      final list = List<UserPoi>.from(ref.read(mapStateProvider).userPois);
      final startIdx = UserPoi.indexInList(list, currentPoi);
      if (startIdx < 0) {
        await ref
            .read(mapStateProvider.notifier)
            .updateUserPoi(currentPoi, updatedPoi);
      } else {
        list[startIdx] = updatedPoi;
        for (var i = 0; i < list.length; i++) {
          if (i == startIdx) continue;
          final p = list[i];
          final e = p.bmExt;
          if (e == null) continue;
          final s = e.schedule;
          final afterStart = i > startIdx;

          DateTime? arr = s.arrival;
          DateTime? dep = s.departure;

          if (afterStart &&
              startCascadeDelta != null &&
              (arr != null || dep != null)) {
            arr = arr?.add(startCascadeDelta);
            dep = dep?.add(startCascadeDelta);
          }

          final shifted = UserPoi(
            type: p.type,
            km: p.km,
            title: p.title,
            body: p.body,
            lat: p.lat,
            lng: p.lng,
            gpxCmt: p.gpxCmt,
            gpxType: p.gpxType,
            bmExt: BmPoiExtension(
              type: e.type,
              distanceKm: e.distanceKm,
              schedule: BmSchedule(
                arrival: arr,
                departure: dep,
                close: s.close,
                result: s.result,
              ),
            ),
          );

          if (e.type == 'finish') {
            list[i] = _userPoiWithFinishClose(shifted, newClose);
          } else if (afterStart &&
              startCascadeDelta != null &&
              (s.arrival != null || s.departure != null)) {
            list[i] = shifted;
          }
        }
        await ref.read(mapStateProvider.notifier).replaceAllUserPois(list);
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
            lat: p.lat,
            lng: p.lng,
            gpxCmt: p.gpxCmt,
            gpxType: p.gpxType,
            bmExt: BmPoiExtension(
              type: e.type,
              distanceKm: e.distanceKm,
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

  await showDialog<void>(
    context: context,
    barrierColor: transparentBarrier ? Colors.transparent : Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => EditPoiTextDialog(
      poi: poi,
      distanceUnit: distanceUnit,
      totalRouteKm: totalRouteKm,
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
    lat: newLatLng.latitude,
    lng: newLatLng.longitude,
    gpxCmt: poi.gpxCmt,
    gpxType: poi.gpxType,
    bmExt: poi.bmExt,
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
  String? _kmError;
  late final FocusNode _kmFocusNode;
  TimeOfDay? _arrival;
  TimeOfDay? _departure;
  TimeOfDay? _close;
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
      arrival: _arrival,
      departure: _departure,
      close: _close,
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

  Future<void> _pickTime({required bool isArrival}) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final current = isArrival ? _arrival : _departure;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() {
        if (isArrival) {
          _arrival = picked;
          final totalMin = picked.hour * 60 + picked.minute + 15;
          _departure =
              TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
        } else {
          _departure = picked;
        }
      });
    }
  }

  Future<void> _pickClose() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _close ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() => _close = picked);
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
              const SizedBox(height: 20),
              _TimePickerRow(
                label: l10n.plannedArrival,
                time: _arrival,
                onTap: () => _pickTime(isArrival: true),
                onClear: () => setState(() => _arrival = null),
              ),
              const SizedBox(height: 8),
              _TimePickerRow(
                label: l10n.plannedDeparture,
                time: _departure,
                onTap: () => _pickTime(isArrival: false),
                onClear: () => setState(() => _departure = null),
              ),
              const SizedBox(height: 8),
              _TimePickerRow(
                label: l10n.plannedClose,
                time: _close,
                onTap: _pickClose,
                onClear: () => setState(() => _close = null),
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
                            ? '$distStr：${poi.title.isEmpty ? AppLocalizations.of(context)!.titleNone : poi.title}'
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
// 地図タップでPOI登録ダイアログ（km入力なし）
// ---------------------------------------------------------------------------

class MapTapPoiAddDialog extends StatefulWidget {
  const MapTapPoiAddDialog({
    super.key,
    this.initialTitle,
    required this.onSave,
  });

  final String? initialTitle;
  final Future<void> Function(AddPoiFormData data) onSave;

  @override
  State<MapTapPoiAddDialog> createState() => _MapTapPoiAddDialogState();
}

class _MapTapPoiAddDialogState extends State<MapTapPoiAddDialog> {
  int _poiType = 0;
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();
  TimeOfDay? _arrival;
  TimeOfDay? _departure;
  TimeOfDay? _close;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isArrival}) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final current = isArrival ? _arrival : _departure;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() {
        if (isArrival) {
          _arrival = picked;
          final totalMin = picked.hour * 60 + picked.minute + 15;
          _departure =
              TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
        } else {
          _departure = picked;
        }
      });
    }
  }

  Future<void> _pickClose() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _close ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() => _close = picked);
    }
  }

  AddPoiFormData _buildFormData() => AddPoiFormData(
        km: null,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        arrival: _arrival,
        departure: _departure,
        close: _close,
      );

  Future<void> _handleAdd() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await widget.onSave(_buildFormData());
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
              const SizedBox(height: 20),
              _TimePickerRow(
                label: l10n.plannedArrival,
                time: _arrival,
                onTap: () => _pickTime(isArrival: true),
                onClear: () => setState(() => _arrival = null),
              ),
              const SizedBox(height: 8),
              _TimePickerRow(
                label: l10n.plannedDeparture,
                time: _departure,
                onTap: () => _pickTime(isArrival: false),
                onClear: () => setState(() => _departure = null),
              ),
              const SizedBox(height: 8),
              _TimePickerRow(
                label: l10n.plannedClose,
                time: _close,
                onTap: _pickClose,
                onClear: () => setState(() => _close = null),
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
// POIテキスト編集ダイアログ
// ---------------------------------------------------------------------------

class EditPoiTextDialog extends StatefulWidget {
  const EditPoiTextDialog({
    super.key,
    required this.poi,
    required this.distanceUnit,
    this.totalRouteKm,
    this.elevationGainFor,
    this.elevationLossFor,
    this.findPreviousPoi,
    required this.onNext,
    required this.onPrev,
    required this.onSave,
    required this.onSavePrev,
  });

  final UserPoi poi;
  final int distanceUnit;
  final double? totalRouteKm;

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
  late final TextEditingController _kmController;
  late final FocusNode _kmFocusNode;
  late final FocusNode _dummyFocusNode;
  String? _kmError;
  TimeOfDay? _arrival;
  TimeOfDay? _departure;
  TimeOfDay? _close;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _currentPoi = widget.poi;
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _kmController = TextEditingController();
    _kmFocusNode = FocusNode();
    _dummyFocusNode = FocusNode();
    _kmFocusNode.addListener(_onKmFocusChange);
    _kmController.addListener(_onKmChanged);
    _loadPoiToForm(widget.poi);
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

  @override
  void dispose() {
    _kmController.removeListener(_onKmChanged);
    _kmFocusNode.removeListener(_onKmFocusChange);
    _kmFocusNode.dispose();
    _dummyFocusNode.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
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
    _kmController.text = _kmToDisplayText(poi.km);
    _arrival = _timeOfDayFromDt(poi.bmExt?.schedule.arrival);
    _departure = _timeOfDayFromDt(poi.bmExt?.schedule.departure);
    _close = _timeOfDayFromDt(poi.bmExt?.schedule.close);
    _kmError = null;
  }

  double? _parsedKmFromField() {
    final text = _kmController.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || value < 0) return null;
    return widget.distanceUnit == 1 ? value * kmPerMile : value;
  }

  String _segmentDistanceDisplay() {
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
          const Icon(Icons.add, size: iconSize, color: iconColor),
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

    if (_kmController.text.trim() != _kmToDisplayText(_currentPoi.km)) {
      return true;
    }

    final origArrival = _timeOfDayFromDt(_currentPoi.bmExt?.schedule.arrival);
    final origDeparture =
        _timeOfDayFromDt(_currentPoi.bmExt?.schedule.departure);
    final origClose = _timeOfDayFromDt(_currentPoi.bmExt?.schedule.close);
    if (_arrival?.hour != origArrival?.hour ||
        _arrival?.minute != origArrival?.minute) {
      return true;
    }
    if (_departure?.hour != origDeparture?.hour ||
        _departure?.minute != origDeparture?.minute) {
      return true;
    }
    if (_close?.hour != origClose?.hour ||
        _close?.minute != origClose?.minute) {
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
      arrival: _arrival,
      departure: _departure,
      close: _close,
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

  Future<void> _pickTime({required bool isArrival}) async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final current = isArrival ? _arrival : _departure;
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() {
        if (isArrival) {
          _arrival = picked;
          final totalMin = picked.hour * 60 + picked.minute + 15;
          _departure =
              TimeOfDay(hour: (totalMin ~/ 60) % 24, minute: totalMin % 60);
        } else {
          _departure = picked;
        }
      });
    }
  }

  Future<void> _pickClose() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(Duration.zero);
    if (!mounted) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: _close ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    if (picked != null && mounted) {
      setState(() => _close = picked);
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
                const SizedBox(height: 18),
                _segmentElevationSummaryBar(),
                const SizedBox(height: 14),
                _TimePickerRow(
                  label: l10n.plannedArrival,
                  time: _arrival,
                  onTap: () => _pickTime(isArrival: true),
                  onClear: () => setState(() => _arrival = null),
                ),
                const SizedBox(height: 8),
                _TimePickerRow(
                  label: l10n.plannedDeparture,
                  time: _departure,
                  onTap: () => _pickTime(isArrival: false),
                  onClear: () => setState(() => _departure = null),
                ),
                const SizedBox(height: 8),
                _TimePickerRow(
                  label: l10n.plannedClose,
                  time: _close,
                  onTap: _pickClose,
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
    required this.time,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final TimeOfDay? time;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final timeText = time != null
        ? '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}'
        : '--:--';
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.body),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(timeText, style: AppTextStyles.title),
        ),
        if (time != null) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close, size: 18, color: Colors.black38),
          ),
        ] else
          const SizedBox(width: 20),
      ],
    );
  }
}

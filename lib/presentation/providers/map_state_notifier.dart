import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../data/repositories/user_poi_repository.dart';
import '../../domain/models/user_poi.dart';
import '../../domain/services/gpx_import_service.dart';
import '../../domain/services/route_animation_runner.dart';
import '../../domain/services/route_fetch_service.dart';
import '../../domain/services/route_marker_service.dart';
import '../../utils/map_utils.dart';
import 'app_settings_providers.dart';

/// GPXインポートの処理結果
enum GpxApplyStatus { success, empty, parseError }

@immutable
class MapState {
  const MapState({
    this.routePolylines = const [],
    this.routeMarkers = const [],
    this.mapStyleMode = 0,
    this.savedRoutePoints,
    this.gpxPois = const [],
    this.userPois = const [],
    this.fullRoutePoints,
    this.savedZoomLevel,
    this.hasStartedInitialRouteFetch = false,
    this.lastRoutePointsForMarkers,
    this.lastShowDistanceMarkers,
  });

  final List<Polyline> routePolylines;
  final List<Marker> routeMarkers;

  /// 0=通常カラー, 2=ダーク。デフォルトは 0
  final int mapStyleMode;

  final List<LatLng>? savedRoutePoints;
  final List<GpxPoi> gpxPois;

  /// ユーザーが手動で登録した POI
  final List<UserPoi> userPois;

  /// アニメーション用フルルート（animateToRouteBounds にも使う）
  final List<LatLng>? fullRoutePoints;

  /// ユーザーが変更したズームレベル。null = デフォルト使用
  final double? savedZoomLevel;

  /// 初回ルート取得フラグ（2重取得防止）
  final bool hasStartedInitialRouteFetch;

  // マーカー再構築の要不要判定用
  final List<LatLng>? lastRoutePointsForMarkers;
  final bool? lastShowDistanceMarkers;

  MapState copyWith({
    List<Polyline>? routePolylines,
    List<Marker>? routeMarkers,
    int? mapStyleMode,
    List<LatLng>? savedRoutePoints,
    List<GpxPoi>? gpxPois,
    List<UserPoi>? userPois,
    List<LatLng>? fullRoutePoints,
    double? savedZoomLevel,
    bool? hasStartedInitialRouteFetch,
    List<LatLng>? lastRoutePointsForMarkers,
    bool? lastShowDistanceMarkers,
    bool clearSavedRoutePoints = false,
    bool clearFullRoutePoints = false,
    bool clearSavedZoomLevel = false,
  }) {
    return MapState(
      routePolylines: routePolylines ?? this.routePolylines,
      routeMarkers: routeMarkers ?? this.routeMarkers,
      mapStyleMode: mapStyleMode ?? this.mapStyleMode,
      savedRoutePoints: clearSavedRoutePoints
          ? null
          : (savedRoutePoints ?? this.savedRoutePoints),
      gpxPois: gpxPois ?? this.gpxPois,
      userPois: userPois ?? this.userPois,
      fullRoutePoints: clearFullRoutePoints
          ? null
          : (fullRoutePoints ?? this.fullRoutePoints),
      savedZoomLevel:
          clearSavedZoomLevel ? null : (savedZoomLevel ?? this.savedZoomLevel),
      hasStartedInitialRouteFetch:
          hasStartedInitialRouteFetch ?? this.hasStartedInitialRouteFetch,
      lastRoutePointsForMarkers:
          lastRoutePointsForMarkers ?? this.lastRoutePointsForMarkers,
      lastShowDistanceMarkers:
          lastShowDistanceMarkers ?? this.lastShowDistanceMarkers,
    );
  }
}

/// ルート・マーカー・マップスタイルの状態を管理する Notifier。
/// [RouteAnimationRunner] を内部に保持し、アニメーション制御も担う。
class MapStateNotifier extends Notifier<MapState> {
  final RouteAnimationRunner _routeAnimationRunner = RouteAnimationRunner();
  static final List<LatLng> _emptyRoute = [];

  // POIタップ時のコールバック。onMapCreated 後に Widget から設定される
  void Function(GpxPoi)? _onPoiTap;
  void Function(UserPoi)? _onUserPoiTap;

  // ドラッグ編集中のユーザー POI
  UserPoi? _draggingPoi;
  void Function(LatLng)? _onPoiDragEnd;

  @override
  MapState build() => const MapState();

  /// Widget 側の GPX POI タップハンドラを登録する
  void setPoiTapHandler(void Function(GpxPoi) handler) {
    _onPoiTap = handler;
  }

  /// Widget 側のユーザー POI タップハンドラを登録する
  void setUserPoiTapHandler(void Function(UserPoi) handler) {
    _onUserPoiTap = handler;
  }

  /// 起動時: 保存済みルートと POI を読み込む（初回起動時はスキップ）
  Future<void> loadSavedRouteIfNeeded() async {
    final savedUserPois = await loadUserPois();
    final isFirst = await isFirstLaunch();
    if (isFirst) {
      if (savedUserPois.isNotEmpty) {
        state = state.copyWith(userPois: savedUserPois);
      }
      return;
    }
    final result = await loadSavedRouteWithPois();
    state = state.copyWith(
      savedRoutePoints: (result.points != null && result.points!.isNotEmpty)
          ? result.points
          : null,
      gpxPois: result.pois,
      userPois: savedUserPois,
    );
  }

  /// ユーザー POI を登録して保存し、マーカーを再構築する
  Future<void> addUserPoi(UserPoi poi) async {
    final updated = [...state.userPois, poi];
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// SharedPreferences から保存済みマップスタイルを読み込み、state に反映する
  /// （OpenStreetMap では ColorFilter でダークモードを適用するため controller は不要）
  Future<void> loadAndApplyMapStyle(MapController? controller) async {
    final mode = await loadMapStyleMode();
    state = state.copyWith(mapStyleMode: mode);
  }

  /// カメラアイドル時: ズームを保存し、必要な場合のみマーカーを再構築する
  Future<void> onCameraIdle(MapController controller) async {
    final z = controller.camera.zoom;
    state = state.copyWith(savedZoomLevel: z);

    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    final showDistance = z >= distanceMarkerZoomThreshold;
    final routeChanged = state.lastRoutePointsForMarkers != routePoints;
    final zoomThresholdCrossed =
        (state.lastShowDistanceMarkers ?? false) != showDistance;

    if (state.lastRoutePointsForMarkers == null ||
        routeChanged ||
        zoomThresholdCrossed) {
      await _refreshRouteMarkers(routePoints);
    }
  }

  /// マップ作成時: スタイル適用・マーカー初期構築・保存済みルート描画
  Future<void> onMapCreated(
    MapController controller, {
    required Future<void> Function(LatLngBounds) animateCamera,
  }) async {
    await loadAndApplyMapStyle(controller);

    final initialRoute = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(initialRoute);

    if (state.savedRoutePoints != null && state.savedRoutePoints!.isNotEmpty) {
      final bounds = boundsFromPoints(state.savedRoutePoints!);
      if (bounds != null) {
        await animateCamera(bounds);
        await _startRouteAnimation(state.savedRoutePoints!);
      }
    }
  }

  /// GPXインポート結果を状態に反映する。
  /// SnackBar 表示は呼び出し側（Widget）が [GpxApplyStatus] を見て行う。
  /// [importFilename] ファイルピッカーから取得したファイル名（.gpx 除く）。metadata が空のときプリファレンスに保存
  Future<GpxApplyStatus> applyImportedGpx(
    String gpxContent, {
    required Future<void> Function(LatLngBounds) animateCamera,
    String? importFilename,
  }) async {
    final result = await parseAndSaveGpx(gpxContent, importFilename: importFilename);
    if (result == null) {
      if (gpxContent.trim().isNotEmpty) return GpxApplyStatus.parseError;
      return GpxApplyStatus.success;
    }
    if (result.isEmpty) return GpxApplyStatus.empty;

    state = state.copyWith(
      savedRoutePoints:
          result.trackPoints.isNotEmpty ? result.trackPoints : null,
      clearSavedRoutePoints: result.trackPoints.isEmpty,
      gpxPois: const [],
      userPois: result.userPois,
      hasStartedInitialRouteFetch: true,
    );

    await stopPoiDrag();

    if (result.trackPoints.isNotEmpty) {
      _routeAnimationRunner.cancel();
      await _startRouteAnimation(result.trackPoints, animate: false);
      final bounds = boundsFromPointsWithPois(
        result.trackPoints,
        result.userPois.map((p) => p.position).toList(),
      );
      if (bounds != null) await animateCamera(bounds);
    } else if (result.userPois.isNotEmpty) {
      await _refreshRouteMarkers(_emptyRoute);
      final bounds =
          boundsFromPoints(result.userPois.map((p) => p.position).toList());
      if (bounds != null) await animateCamera(bounds);
    }

    return GpxApplyStatus.success;
  }

  /// マップスタイルを 0⇔2 でトグルし、SharedPreferences に保存する
  /// （OpenStreetMap では ColorFilter でダークモードを適用）
  Future<void> toggleMapStyle(MapController? controller) async {
    final newMode = state.mapStyleMode == 0 ? 2 : 0;
    state = state.copyWith(mapStyleMode: newMode);
    await saveMapStyleMode(newMode);
  }

  /// オフライン復帰時など、初回ルート取得の再試行を許可する
  void resetInitialRouteFetchForRetry() {
    state = state.copyWith(hasStartedInitialRouteFetch: false);
  }

  /// 初回 API 取得 or 保存済みルート読み込み（1回のみ実行）
  Future<void> fetchOrLoadRouteIfNeeded(
    Position position, {
    required Future<void> Function(LatLngBounds?) animateCamera,
  }) async {
    if (state.hasStartedInitialRouteFetch) return;
    state = state.copyWith(hasStartedInitialRouteFetch: true);

    await Future.delayed(const Duration(milliseconds: 300));

    final points = await fetchOrLoadRoute(
      position,
      savedRoutePoints: state.savedRoutePoints,
    );
    if (points == null || points.isEmpty) return;

    state = state.copyWith(savedRoutePoints: points);
    if (state.routePolylines.isEmpty) {
      await _startRouteAnimation(points);
    }
    final bounds = boundsFromPoints(points);
    await animateCamera(bounds);
  }

  /// ルート全体のバウンドを返す（animateToRouteBounds 用）
  LatLngBounds? getRouteBounds() {
    final points = state.fullRoutePoints ?? state.savedRoutePoints;
    if (points == null || points.isEmpty) return null;
    return boundsFromPoints(points);
  }

  /// 位置ストリーム初回 ON 時にズームを 15 に上書きする
  void overrideSavedZoom(double zoom) {
    state = state.copyWith(savedZoomLevel: zoom);
  }

  /// dispose 時にアニメーションをキャンセルする
  void cancelAnimation() {
    _routeAnimationRunner.cancel();
  }

  /// 指定した POI をドラッグ可能にする（位置編集モード開始）
  Future<void> startPoiDrag(
      UserPoi poi, void Function(LatLng) onDragEnd) async {
    _draggingPoi = poi;
    _onPoiDragEnd = onDragEnd;
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// 地図中心座標で POI ドラッグ位置を確定する
  void confirmPoiDrag(LatLng newLatLng) {
    _onPoiDragEnd?.call(newLatLng);
  }

  /// ドラッグ編集モードを終了し、マーカーを通常に戻す
  Future<void> stopPoiDrag() async {
    _draggingPoi = null;
    _onPoiDragEnd = null;
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// ユーザー POI を削除して保存し、マーカーを再構築する
  Future<void> deleteUserPoi(UserPoi poi) async {
    final index = state.userPois.indexWhere(
      (p) => p.lat == poi.lat && p.lng == poi.lng && p.km == poi.km,
    );
    if (index < 0) return;
    final updated = List<UserPoi>.from(state.userPois)..removeAt(index);
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// 距離単位変更時にマーカーを再構築する
  Future<void> refreshMarkersForUnitChange() async {
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// 既存のユーザー POI を新しい内容で上書きして保存する
  Future<void> updateUserPoi(UserPoi oldPoi, UserPoi newPoi) async {
    final index = state.userPois.indexWhere(
      (p) => p.lat == oldPoi.lat && p.lng == oldPoi.lng && p.km == oldPoi.km,
    );
    if (index < 0) return;
    final updated = List<UserPoi>.from(state.userPois)..[index] = newPoi;
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  // --- 内部メソッド ---

  /// スタート・ゴール・POI マーカーを再構築して state を更新する
  Future<void> _refreshRouteMarkers(List<LatLng> routePoints) async {
    final onPoiTap = _onPoiTap ?? (_) {};
    final onUserPoiTap = _onUserPoiTap;
    final distanceUnit = ref.read(distanceUnitProvider);
    final markers = await buildRouteMarkers(
      routePoints: routePoints,
      pois: state.gpxPois,
      onPoiTap: onPoiTap,
      userPois: state.userPois,
      onUserPoiTap: onUserPoiTap,
      zoomLevel: state.savedZoomLevel,
      draggingPoi: _draggingPoi,
      distanceUnit: distanceUnit,
    );
    state = state.copyWith(
      routeMarkers: markers,
      lastRoutePointsForMarkers: routePoints,
      lastShowDistanceMarkers: state.savedZoomLevel != null &&
          state.savedZoomLevel! >= distanceMarkerZoomThreshold,
    );
  }

  /// ルートをアニメーション描画する（GPXインポート時は animate: false で一括表示）
  Future<void> _startRouteAnimation(
    List<LatLng> fullPoints, {
    bool animate = true,
  }) async {
    state = state.copyWith(fullRoutePoints: fullPoints);
    await _refreshRouteMarkers(fullPoints);
    await _routeAnimationRunner.start(
      fullPoints,
      buildMarkers: false,
      animate: animate,
      onPolyline: (p) {
        state = state.copyWith(routePolylines: p);
      },
      onMarkers: (_) {},
      mounted: () => true,
    );
  }
}

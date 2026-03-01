import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants/map_styles.dart';
import '../../data/parsers/gpx_parser.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/gpx_import_service.dart';
import '../../domain/services/route_animation_runner.dart';
import '../../domain/services/route_fetch_service.dart';
import '../../domain/services/route_marker_service.dart';
import '../../utils/map_utils.dart';

/// GPXインポートの処理結果
enum GpxApplyStatus { success, empty, parseError }

@immutable
class MapState {
  const MapState({
    this.routePolylines = const {},
    this.routeMarkers = const {},
    this.mapStyleMode = 0,
    this.savedRoutePoints,
    this.gpxPois = const [],
    this.fullRoutePoints,
    this.savedZoomLevel,
    this.hasStartedInitialRouteFetch = false,
    this.lastRoutePointsForMarkers,
    this.lastShowDistanceMarkers,
  });

  final Set<Polyline> routePolylines;
  final Set<Marker> routeMarkers;

  /// 0=通常カラー, 2=ダーク。デフォルトは 0
  final int mapStyleMode;

  final List<LatLng>? savedRoutePoints;
  final List<GpxPoi> gpxPois;

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
    Set<Polyline>? routePolylines,
    Set<Marker>? routeMarkers,
    int? mapStyleMode,
    List<LatLng>? savedRoutePoints,
    List<GpxPoi>? gpxPois,
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

  @override
  MapState build() => const MapState();

  /// Widget 側の POI タップハンドラを登録する（showPoiDetailSheet を呼ぶ）
  void setPoiTapHandler(void Function(GpxPoi) handler) {
    _onPoiTap = handler;
  }

  /// 起動時: 保存済みルートと POI を読み込む（初回起動時はスキップ）
  Future<void> loadSavedRouteIfNeeded() async {
    final isFirst = await isFirstLaunch();
    if (isFirst) return;
    final result = await loadSavedRouteWithPois();
    state = state.copyWith(
      savedRoutePoints:
          (result.points != null && result.points!.isNotEmpty) ? result.points : null,
      gpxPois: result.pois,
    );
  }

  /// SharedPreferences から保存済みマップスタイルを読み込み、state と controller に適用する
  Future<void> loadAndApplyMapStyle(GoogleMapController? controller) async {
    final mode = await loadMapStyleMode();
    state = state.copyWith(mapStyleMode: mode);
    // ignore: deprecated_member_use
    await controller?.setMapStyle(mapStyleForMode(mode));
  }

  /// カメラアイドル時: ズームを保存し、必要な場合のみマーカーを再構築する
  Future<void> onCameraIdle(GoogleMapController controller) async {
    final z = await controller.getZoomLevel();
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
    GoogleMapController controller, {
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
  Future<GpxApplyStatus> applyImportedGpx(
    String gpxContent, {
    required Future<void> Function(LatLngBounds) animateCamera,
  }) async {
    final result = await parseAndSaveGpx(gpxContent);
    if (result == null) {
      if (gpxContent.trim().isNotEmpty) return GpxApplyStatus.parseError;
      return GpxApplyStatus.success;
    }
    if (result.isEmpty) return GpxApplyStatus.empty;

    state = state.copyWith(
      savedRoutePoints:
          result.trackPoints.isNotEmpty ? result.trackPoints : null,
      clearSavedRoutePoints: result.trackPoints.isEmpty,
      gpxPois: result.waypoints,
      hasStartedInitialRouteFetch: true,
    );

    if (result.trackPoints.isNotEmpty) {
      _routeAnimationRunner.cancel();
      await _startRouteAnimation(result.trackPoints, animate: false);
      final bounds = boundsFromPointsWithPois(
        result.trackPoints,
        result.waypoints.map((p) => p.position).toList(),
      );
      if (bounds != null) await animateCamera(bounds);
    } else if (result.waypoints.isNotEmpty) {
      await _refreshRouteMarkers(_emptyRoute);
      final bounds =
          boundsFromPoints(result.waypoints.map((p) => p.position).toList());
      if (bounds != null) await animateCamera(bounds);
    }

    return GpxApplyStatus.success;
  }

  /// マップスタイルを 0⇔2 でトグルし、SharedPreferences に保存する
  Future<void> toggleMapStyle(GoogleMapController? controller) async {
    final newMode = state.mapStyleMode == 0 ? 2 : 0;
    state = state.copyWith(mapStyleMode: newMode);
    // ignore: deprecated_member_use
    await controller?.setMapStyle(mapStyleForMode(newMode));
    await saveMapStyleMode(newMode);
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

  // --- 内部メソッド ---

  /// スタート・ゴール・POI マーカーを再構築して state を更新する
  Future<void> _refreshRouteMarkers(List<LatLng> routePoints) async {
    final onPoiTap = _onPoiTap ?? (_) {};
    final markers = await buildRouteMarkers(
      routePoints: routePoints,
      pois: state.gpxPois,
      onPoiTap: onPoiTap,
      zoomLevel: state.savedZoomLevel,
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

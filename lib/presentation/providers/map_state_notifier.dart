import 'dart:async';
import 'dart:convert';

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
    this.savedTrackElevations,
    this.gpxPois = const [],
    this.gpxDotWaypoints = const [],
    this.userPois = const [],
    this.cachedPoiElevationGains,
    this.cachedPoiElevationLosses,
    this.fullRoutePoints,
    this.savedZoomLevel,
    this.hasStartedInitialRouteFetch = false,
    this.lastRoutePointsForMarkers,
    this.lastShowDistanceMarkers,
    this.isFetchingRoute = false,
  });

  final List<Polyline> routePolylines;
  final List<Marker> routeMarkers;

  /// 0=通常カラー, 2=ダーク。デフォルトは 0
  final int mapStyleMode;

  final List<LatLng>? savedRoutePoints;

  /// GPX インポート時の各 trkpt の標高。[savedRoutePoints] と同じ長さ。アプリ表示には使わない
  final List<double?>? savedTrackElevations;

  final List<GpxPoi> gpxPois;

  /// `<type>Dot</type>` の wpt（エクスポート復元用。マーカー・POI一覧には出さない）
  final List<GpxPoi> gpxDotWaypoints;

  /// ユーザーが手動で登録した POI
  final List<UserPoi> userPois;

  /// [userPois] リスト順の獲得標高キャッシュ（メートル値）。インポート・起動・POI変更後に更新
  final List<double?>? cachedPoiElevationGains;

  /// [userPois] リスト順の獲得下降キャッシュ（メートル値）。[cachedPoiElevationGains] と同タイミングで更新
  final List<double?>? cachedPoiElevationLosses;

  /// アニメーション用フルルート（animateToRouteBounds にも使う）
  final List<LatLng>? fullRoutePoints;

  /// ユーザーが変更したズームレベル。null = デフォルト使用
  final double? savedZoomLevel;

  /// 初回ルート取得フラグ（2重取得防止）
  final bool hasStartedInitialRouteFetch;

  // マーカー再構築の要不要判定用
  final List<LatLng>? lastRoutePointsForMarkers;
  final bool? lastShowDistanceMarkers;

  /// 初回ルート取得中かどうか（ローディング表示用）
  final bool isFetchingRoute;

  MapState copyWith({
    List<Polyline>? routePolylines,
    List<Marker>? routeMarkers,
    int? mapStyleMode,
    List<LatLng>? savedRoutePoints,
    List<double?>? savedTrackElevations,
    List<GpxPoi>? gpxPois,
    List<GpxPoi>? gpxDotWaypoints,
    List<UserPoi>? userPois,
    List<double?>? cachedPoiElevationGains,
    List<double?>? cachedPoiElevationLosses,
    List<LatLng>? fullRoutePoints,
    double? savedZoomLevel,
    bool? hasStartedInitialRouteFetch,
    List<LatLng>? lastRoutePointsForMarkers,
    bool? lastShowDistanceMarkers,
    bool? isFetchingRoute,
    bool clearSavedRoutePoints = false,
    bool clearSavedTrackElevations = false,
    bool clearFullRoutePoints = false,
    bool clearSavedZoomLevel = false,
    bool clearPoiElevationGains = false,
  }) {
    return MapState(
      routePolylines: routePolylines ?? this.routePolylines,
      routeMarkers: routeMarkers ?? this.routeMarkers,
      mapStyleMode: mapStyleMode ?? this.mapStyleMode,
      savedRoutePoints: clearSavedRoutePoints
          ? null
          : (savedRoutePoints ?? this.savedRoutePoints),
      savedTrackElevations: clearSavedRoutePoints || clearSavedTrackElevations
          ? null
          : (savedTrackElevations ?? this.savedTrackElevations),
      gpxPois: gpxPois ?? this.gpxPois,
      gpxDotWaypoints: gpxDotWaypoints ?? this.gpxDotWaypoints,
      userPois: userPois ?? this.userPois,
      cachedPoiElevationGains: clearPoiElevationGains
          ? null
          : (cachedPoiElevationGains ?? this.cachedPoiElevationGains),
      cachedPoiElevationLosses: clearPoiElevationGains
          ? null
          : (cachedPoiElevationLosses ?? this.cachedPoiElevationLosses),
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
      isFetchingRoute: isFetchingRoute ?? this.isFetchingRoute,
    );
  }
}

/// ルート・マーカー・マップスタイルの状態を管理する Notifier。
/// [RouteAnimationRunner] を内部に保持し、アニメーション制御も担う。
class MapStateNotifier extends Notifier<MapState> {
  final RouteAnimationRunner _routeAnimationRunner = RouteAnimationRunner();
  static final List<LatLng> _emptyRoute = [];

  /// [_refreshRouteMarkers] と [_cachePoiElevationGains] を直列で非同期キュー処理する。
  /// POI 保存処理がこれらの完了を await しないようにし（ダイアログ応答など）、体感フリーズを防ぐ。
  Future<void> _markerRebuildChain = Future<void>.value();

  // POIタップ時のコールバック。onMapCreated 後に Widget から設定される
  void Function(GpxPoi)? _onPoiTap;
  void Function(UserPoi)? _onUserPoiTap;

  // ドラッグ編集中のユーザー POI
  UserPoi? _draggingPoi;
  void Function(LatLng)? _onPoiDragEnd;

  // 前半・後半ポリライン（ルート読み込み後に設定）
  Polyline? _firstHalfPolyline;
  Polyline? _secondHalfPolyline;
  // 折り返し距離（m）。前半・後半の境界
  double _halfRouteDistanceM = 0;
  // 前半/後半判定用ダウンサンプル済みルート（最大500点）と累積距離キャッシュ
  List<LatLng> _sampledRoutePoints = [];
  List<double> _sampledCumulativeDistances = [];
  // 直前の表示状態。新ルート読み込み時は null にリセットして強制更新を保証する
  bool? _currentDisplayIsSecondHalf;

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
    final pts = result.points;
    final elev = await loadTrackElevations();
    final alignedElev = (elev != null &&
            pts != null &&
            pts.isNotEmpty &&
            elev.length == pts.length)
        ? elev
        : null;
    List<GpxPoi> dotWaypoints = const [];
    final dotsJson = await loadGpxDotWaypointsJson();
    if (dotsJson != null && dotsJson.isNotEmpty) {
      try {
        final list = jsonDecode(dotsJson) as List<dynamic>;
        dotWaypoints = list
            .map((e) => GpxPoi.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }
    state = state.copyWith(
      savedRoutePoints:
          (pts != null && pts.isNotEmpty) ? pts : null,
      savedTrackElevations: alignedElev,
      gpxPois: result.pois,
      gpxDotWaypoints: dotWaypoints,
      userPois: savedUserPois,
    );
    unawaited(_cachePoiElevationGains());
  }

  /// ユーザー POI を登録して保存し、マーカーを再構築する
  Future<void> addUserPoi(UserPoi poi) async {
    var updated = <UserPoi>[...state.userPois, poi];
    if (poi.km != null) {
      updated = UserPoi.orderedForDetailSheet(updated);
    }
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    _enqueueMarkerRebuildAndElevationCache();
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

    // 初期ズームを保存しておく（savedZoomLevel が null だと距離マーカーの閾値判定が機能しないため）
    state = state.copyWith(savedZoomLevel: controller.camera.zoom);

    final initialRoute = state.savedRoutePoints ?? _emptyRoute;
    final hasRoute =
        state.savedRoutePoints != null && state.savedRoutePoints!.isNotEmpty;
    // ルートがある場合は直後にアニメーション開始するため、userPois を除いてマーカーを構築する
    await _refreshRouteMarkers(initialRoute, includeUserPois: !hasRoute);

    if (hasRoute) {
      final bounds = boundsFromPoints(state.savedRoutePoints!);
      if (bounds != null) {
        await animateCamera(bounds);
        // アニメーション後の実際のズームレベルで savedZoomLevel を更新する
        state = state.copyWith(savedZoomLevel: controller.camera.zoom);
        await _startRouteAnimation(state.savedRoutePoints!);
      }
    }
  }

  /// GPXインポート結果を状態に反映する。
  /// SnackBar 表示は呼び出し側（Widget）が [GpxApplyStatus] を見て行う。
  /// [importFilename] ファイルピッカーから取得したファイル名（.gpx 除く）。永続化されエクスポート既定名などに使用
  Future<GpxApplyStatus> applyImportedGpx(
    String gpxContent, {
    required Future<void> Function(LatLngBounds) animateCamera,
    String? importFilename,
  }) async {
    final result =
        await parseAndSaveGpx(gpxContent, importFilename: importFilename);
    if (result == null) {
      if (gpxContent.trim().isNotEmpty) return GpxApplyStatus.parseError;
      return GpxApplyStatus.success;
    }
    if (result.isEmpty) return GpxApplyStatus.empty;

    state = state.copyWith(
      savedRoutePoints:
          result.trackPoints.isNotEmpty ? result.trackPoints : null,
      savedTrackElevations: result.trackPoints.isNotEmpty
          ? result.trackElevations
          : null,
      clearSavedRoutePoints: result.trackPoints.isEmpty,
      gpxPois: const [],
      gpxDotWaypoints: result.gpxDotWaypoints,
      userPois: result.userPois,
      hasStartedInitialRouteFetch: true,
    );

    await stopPoiDrag();

    if (result.trackPoints.isNotEmpty) {
      await saveDefaultMapCoordinates(
        result.trackPoints.first.latitude,
        result.trackPoints.first.longitude,
      );
      _routeAnimationRunner.cancel();
      // GPX は点数が多いと線アニメの再生時間が長くなりがちなため、一括表示にする
      await _startRouteAnimation(result.trackPoints, animate: false);
      final bounds = boundsFromPointsWithPois(
        result.trackPoints,
        result.userPois.map((p) => p.position).toList(),
      );
      if (bounds != null) await animateCamera(bounds);
    } else {
      // トラックなし: 古いポリラインとフルルートを消去してからマーカーを再構築する
      _routeAnimationRunner.cancel();
      state = state.copyWith(
        routePolylines: const [],
        clearFullRoutePoints: true,
      );
      if (result.userPois.isNotEmpty) {
        await _refreshRouteMarkers(_emptyRoute);
        final bounds =
            boundsFromPoints(result.userPois.map((p) => p.position).toList());
        if (bounds != null) await animateCamera(bounds);
      }
    }

    await _cachePoiElevationGains();
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
  ///
  /// [onReturningUserMapReady] は保存済みルートがあるときカメラ移動直後。初回インストールの
  /// サンプル＋ボリューム＋リリースノートとは別（後者は [onFirstRouteShown] 経路）。
  Future<void> fetchOrLoadRouteIfNeeded(
    Position position, {
    required Future<void> Function(LatLngBounds?) animateCamera,
    VoidCallback? onFirstRouteShown,
    VoidCallback? onReturningUserMapReady,
  }) async {
    if (state.hasStartedInitialRouteFetch) return;
    // 保存済みルートがない場合（初回インストール相当）のみローディングを表示する
    final hasSavedRoute =
        state.savedRoutePoints != null && state.savedRoutePoints!.isNotEmpty;
    state = state.copyWith(
      hasStartedInitialRouteFetch: true,
      isFetchingRoute: !hasSavedRoute,
    );

    await Future.delayed(const Duration(milliseconds: 300));

    final points = await fetchOrLoadRoute(
      position,
      savedRoutePoints: state.savedRoutePoints,
    );
    state = state.copyWith(isFetchingRoute: false);
    if (points == null || points.isEmpty) return;

    await saveDefaultMapCoordinates(
      points.first.latitude,
      points.first.longitude,
    );

    // 初回インストール時のみサンプル POI を生成して保存する
    if (!hasSavedRoute) {
      final samplePois = buildSamplePois(points);
      if (samplePois.isNotEmpty) {
        await saveUserPois(samplePois);
        state = state.copyWith(userPois: samplePois);
      }
    }

    state = state.copyWith(
      savedRoutePoints: points,
      // 初回 Directions のルート差し替え時は標高キャッシュを捨てる（GPX 由来の ele は保持しない）
      clearSavedTrackElevations: !hasSavedRoute,
    );
    if (state.routePolylines.isEmpty) {
      // 初回インストール時のみアニメーション完了後にコールバックを呼ぶ
      await _startRouteAnimation(
        points,
        onAnimationComplete: !hasSavedRoute ? onFirstRouteShown : null,
      );
    }
    final bounds = boundsFromPoints(points);
    await animateCamera(bounds);
    if (hasSavedRoute) {
      onReturningUserMapReady?.call();
    }
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
    final index = UserPoi.indexInList(state.userPois, poi);
    if (index < 0) return;
    final updated = List<UserPoi>.from(state.userPois)..removeAt(index);
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    _enqueueMarkerRebuildAndElevationCache();
  }

  /// 距離単位変更時にマーカーを再構築する
  Future<void> refreshMarkersForUnitChange() async {
    final routePoints = state.savedRoutePoints ?? _emptyRoute;
    await _refreshRouteMarkers(routePoints);
  }

  /// 既存のユーザー POI を新しい内容で上書きして保存する
  Future<void> updateUserPoi(UserPoi oldPoi, UserPoi newPoi) async {
    final index = UserPoi.indexInList(state.userPois, oldPoi);
    if (index < 0) return;
    final updated = List<UserPoi>.from(state.userPois)..[index] = newPoi;
    await saveUserPois(updated);
    state = state.copyWith(userPois: updated);
    _enqueueMarkerRebuildAndElevationCache();
  }

  /// 全ユーザー POI をまとめて置き換えて保存する（出走日変更などの一括更新用）
  Future<void> replaceAllUserPois(List<UserPoi> pois) async {
    await saveUserPois(pois);
    state = state.copyWith(userPois: pois);
    _enqueueMarkerRebuildAndElevationCache();
  }

  // --- 内部メソッド ---

  /// マーカーを再構築し獲得標高キャッシュを更新する処理をキューへ積む（完了を POI API の await に含めない）。
  void _enqueueMarkerRebuildAndElevationCache() {
    _markerRebuildChain = _markerRebuildChain
        .then((_) async {
          final routePoints = state.savedRoutePoints ?? _emptyRoute;
          await _refreshRouteMarkers(routePoints);
          await _cachePoiElevationGains();
        })
        .catchError((_) {});
  }

  /// [state.userPois] の順で全 POI の獲得標高を isolate で計算してキャッシュする。
  /// トラックまたは標高データがない場合はキャッシュをクリアする。
  Future<void> _cachePoiElevationGains() async {
    final trackPoints = state.savedRoutePoints ?? const [];
    final elevations = state.savedTrackElevations ?? const [];
    if (trackPoints.isEmpty || elevations.isEmpty) {
      state = state.copyWith(clearPoiElevationGains: true);
      return;
    }
    final pois = state.userPois;
    if (pois.isEmpty) {
      state = state.copyWith(clearPoiElevationGains: true);
      return;
    }
    final metrics = await compute(
      computePoiElevationGainAndLoss,
      (
        trackPoints: trackPoints,
        elevations: elevations,
        poiPositions: pois.map((p) => p.position).toList(),
        poiHasDistanceKm: pois.map((p) => p.km != null && !p.isNote).toList(),
        poiKmAlongRoute: pois.map((p) => p.km).toList(),
      ),
    );
    state = state.copyWith(
      cachedPoiElevationGains: metrics.gains,
      cachedPoiElevationLosses: metrics.losses,
    );
  }

  /// スタート・ゴール・POI マーカーを再構築して state を更新する
  /// [includeUserPois] が false の場合、userPois マーカーを含めない（アニメーション中の表示制御用）
  Future<void> _refreshRouteMarkers(
    List<LatLng> routePoints, {
    bool includeUserPois = true,
  }) async {
    final onPoiTap = _onPoiTap ?? (_) {};
    final onUserPoiTap = _onUserPoiTap;
    final distanceUnit = ref.read(distanceUnitProvider);
    final markers = await buildRouteMarkers(
      routePoints: routePoints,
      pois: state.gpxPois,
      onPoiTap: onPoiTap,
      userPois: includeUserPois ? state.userPois : const [],
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

  /// ルートをアニメーション描画する（[animate] が false のときは一括表示。GPX は呼び出し側で false）
  Future<void> _startRouteAnimation(
    List<LatLng> fullPoints, {
    bool animate = true,
    VoidCallback? onAnimationComplete,
  }) async {
    _firstHalfPolyline = null;
    _secondHalfPolyline = null;
    _currentDisplayIsSecondHalf = null;
    // 前半/後半判定用に最大500点にダウンサンプリングし、累積距離をキャッシュする。
    // 1000点超のルートでも位置更新ごとの最近傍検索を O(500) に抑える。
    const maxSamples = 500;
    final step = fullPoints.length <= maxSamples
        ? 1
        : (fullPoints.length / maxSamples).ceil();
    final sampled = <LatLng>[];
    for (var i = 0; i < fullPoints.length; i += step) {
      sampled.add(fullPoints[i]);
    }
    if (sampled.last != fullPoints.last) sampled.add(fullPoints.last);
    final cumDist = List<double>.filled(sampled.length, 0);
    for (var i = 1; i < sampled.length; i++) {
      cumDist[i] =
          cumDist[i - 1] + distanceBetweenLatLng(sampled[i - 1], sampled[i]);
    }
    _sampledRoutePoints = sampled;
    _sampledCumulativeDistances = cumDist;
    _halfRouteDistanceM = cumDist.isNotEmpty ? cumDist.last / 2 : 0;
    state = state.copyWith(fullRoutePoints: fullPoints);
    // アニメーション中は userPois を非表示にし、完了後に表示する
    await _refreshRouteMarkers(fullPoints, includeUserPois: !animate);
    await _routeAnimationRunner.start(
      fullPoints,
      buildMarkers: false,
      animate: animate,
      onPolyline: (p) {
        state = state.copyWith(routePolylines: p);
        if (p.length == 2) {
          _firstHalfPolyline = p[0];
          _secondHalfPolyline = p[1];
        }
      },
      onMarkers: (_) {},
      mounted: () => true,
      onComplete: animate
          ? () async {
              await _refreshRouteMarkers(fullPoints);
              await Future.delayed(const Duration(milliseconds: 400));
              onAnimationComplete?.call();
            }
          : null,
    );
  }

  /// 現在地がルートの前半・後半どちらにいるかに応じてポリラインの描画順を切り替える。
  /// flutter_map はリストの後方が前面に描画される。
  /// 前半中：緑を前面 → [赤, 緑]　後半中：赤を前面 → [緑, 赤]
  void updateHalfDisplay(bool isSecondHalf) {
    if (isSecondHalf == _currentDisplayIsSecondHalf) return;
    final first = _firstHalfPolyline;
    final second = _secondHalfPolyline;
    if (first == null || second == null) return;
    _currentDisplayIsSecondHalf = isSecondHalf;
    final polylines = isSecondHalf ? [first, second] : [second, first];
    state = state.copyWith(routePolylines: polylines);
  }

  /// ダウンサンプル済みルート（最大500点）を使って現在地のalong-track距離を返す。
  /// ベアリングが分かる場合は進行方向が一致する候補を優先し、
  /// 往復ルートで往路・復路が近接していても正しく判定できる。
  /// 常に O(500) で動作し、元のルート点数に依存しない。
  /// [alongTrackM]: ルート先頭からの距離、[toRouteM]: ルートへの最近傍距離
  ({double alongTrackM, double toRouteM}) computeAlongTrackM(LatLng current,
      {LatLng? previous}) {
    final sampled = _sampledRoutePoints;
    final cumDist = _sampledCumulativeDistances;
    if (sampled.isEmpty) return (alongTrackM: 0, toRouteM: double.infinity);

    // 最近傍点と同距離 +50m 以内の候補を収集する
    const candidateEpsilonM = 50.0;
    var minDist = double.infinity;
    for (var i = 0; i < sampled.length; i++) {
      final d = distanceBetweenLatLng(sampled[i], current);
      if (d < minDist) minDist = d;
    }
    final candidates = <({int index, double cumM})>[];
    for (var i = 0; i < sampled.length; i++) {
      if (distanceBetweenLatLng(sampled[i], current) <=
          minDist + candidateEpsilonM) {
        candidates.add((index: i, cumM: cumDist[i]));
      }
    }
    if (candidates.length == 1 || previous == null) {
      return (alongTrackM: candidates.first.cumM, toRouteM: minDist);
    }

    // ベアリングで候補を絞る：進行方向とルートの向きが最も近い候補を選ぶ
    final userBearing = bearingBetweenLatLng(previous, current);
    if (userBearing == null) {
      return (alongTrackM: candidates.first.cumM, toRouteM: minDist);
    }

    var bestCumM = candidates.first.cumM;
    var bestDiff = 180.0;
    for (final c in candidates) {
      final idx = c.index;
      final LatLng from;
      final LatLng to;
      if (idx == 0 && sampled.length > 1) {
        from = sampled[0];
        to = sampled[1];
      } else if (idx == sampled.length - 1 && sampled.length > 1) {
        from = sampled[idx - 1];
        to = sampled[idx];
      } else {
        from = sampled[idx - 1];
        to = sampled[idx];
      }
      final routeBearing = bearingBetweenLatLng(from, to);
      if (routeBearing == null) continue;
      var diff = (userBearing - routeBearing).abs();
      if (diff > 180) diff = 360 - diff;
      if (diff < bestDiff) {
        bestDiff = diff;
        bestCumM = c.cumM;
      }
    }
    return (alongTrackM: bestCumM, toRouteM: minDist);
  }

  double get halfRouteDistanceM => _halfRouteDistanceM;
}

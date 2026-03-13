import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/gpx_channel_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/marker_icon_service.dart';
import '../../domain/services/share_channel_service.dart';
import '../../domain/services/volume_zoom_handler.dart';
import '../../utils/map_utils.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../handlers/gpx_import_handler.dart';
import '../handlers/poi_management_handler.dart';
import '../handlers/settings_menu_handler.dart';
import '../handlers/share_handler.dart';
import '../handlers/share_url_handler.dart';
import '../handlers/sleep_timer_handler.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/connectivity_gate.dart'
    show
        ConnectivityGate,
        ConnectivityGateState,
        ConnectivityCheckingView,
        OfflinePlaceholderView;
import '../widgets/map_screen_content.dart';
import '../widgets/pulsing_location_marker.dart';
import '../widgets/poi_detail_sheet.dart';

/// 位置情報が取得できない場合のフォールバック位置（東京駅）
Position _defaultPosition() {
  return Position(
    latitude: 35.6812,
    longitude: 139.7671,
    timestamp: DateTime(2000),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with WidgetsBindingObserver {
  /// 初期表示位置。null の間はローディング、非 null で地図表示
  Position? _initialPosition;
  bool _expectingReturnFromSettings = false;
  double _lastBearing = 0.0;
  bool _isDragMode = false;
  bool _isMapTapAddMode = false;

  /// 共有リンクから取得した座標。非 null のときプレビューマーカー表示・登録確認UI表示
  LatLng? _pendingSharedPosition;

  /// 共有リンクから取得した施設名。POI登録時のタイトル初期値に使用
  String? _pendingSharedPlaceName;

  /// 共有プレビュー用の現在地風アイコン
  Widget? _sharePreviewIcon;

  /// 位置ストリームON時の最新位置（現在地マーカー表示用）
  Position? _latestStreamPosition;

  /// 直前の位置（bearing による往路/復路判定用）
  Position? _previousStreamPosition;

  /// 共有モード中（吹き出し表示中）は true
  bool _isShareMode = false;

  /// 共有モード時のHP値（0.0〜1.0）。ダイアログで設定
  double? _shareHp;

  /// 位置ストリームON直後の初回位置更新か（初回はデフォルトズーム、以降は現在表示ズームを維持）
  bool _isFirstPositionAfterStreamOn = false;

  late final SleepTimerController _sleepTimerController;

  late final VolumeZoomHandler _volumeZoomHandler;

  /// 起動時に位置取得に失敗した場合、案内 SnackBar を一度だけ表示したか
  bool _hasShownLocationUnavailableHint = false;

  /// 初回ルート取得を実行したか（addPostFrameCallback の多重登録防止）
  bool _hasTriggeredInitialRouteFetch = false;

  /// 位置取得の試行が完了したか（成功・失敗・タイムアウト問わず）
  bool _positionFetchCompleted = false;

  /// 初回インストールか（null=未取得、true=初回、false=2回目以降）
  bool? _isFirstLaunch;

  /// 初回起動時に ConnectivtyGate がオフラインと判定したか
  bool _isConnectivityOffline = false;

  static const double _trackingZoom = 16.0;
  static const double _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sleepTimerController = SleepTimerController(
      overlayState: Overlay.of(context),
      ref: ref,
      getMounted: () => mounted,
      onPositionUpdate: _onPositionUpdate,
    );

    _volumeZoomHandler = VolumeZoomHandler(
      getController: () => ref.read(cameraControllerProvider),
    );
    _volumeZoomHandler.start();

    // 地図を即座に表示するため、まずデフォルト位置で初期化
    _initialPosition = _defaultPosition();
    // 初回フレーム後に位置取得開始（権限ダイアログが正しく表示されるように）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchPositionInBackground();
    });

    WakelockPlus.enable();

    loadSleepDuration().then((minutes) {
      if (!mounted) return;
      ref.read(sleepDurationProvider.notifier).state = minutes;
      _sleepTimerController.restart(minutes);
    });

    loadDistanceUnit().then((unit) {
      if (!mounted) return;
      ref.read(distanceUnitProvider.notifier).state = unit;
    });

    ref.read(mapStateProvider.notifier).loadSavedRouteIfNeeded();

    isFirstLaunch().then((first) {
      if (mounted) setState(() => _isFirstLaunch = first);
    });

    createSharePreviewMarkerIcon().then((icon) {
      if (mounted) setState(() => _sharePreviewIcon = icon);
    });

    GpxChannelService.setMethodCallHandler((content) {
      if (mounted) showConfirmAndApplyGpx(context, ref, content);
    });
    GpxChannelService.getInitialGpxContent().then((content) {
      if (content != null && content.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showConfirmAndApplyGpx(context, ref, content);
        });
      }
    });

    ShareChannelService.setMethodCallHandler(_onSharedUrlReceived);
    ShareChannelService.getInitialSharedUrl().then((url) {
      if (url != null && url.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onSharedUrlReceived(url);
        });
      }
    });
  }

  Future<void> _onSharedUrlReceived(String url) async {
    if (!mounted) return;
    await handleSharedUrlReceived(context, ref, url,
        onParsed: (position, placeName) {
      if (!mounted) return;
      setState(() {
        _pendingSharedPosition = position;
        _pendingSharedPlaceName = placeName;
      });
    });
  }

  void _onCancelSharePreview() {
    setState(() {
      _pendingSharedPosition = null;
      _pendingSharedPlaceName = null;
    });
  }

  Future<void> _onConfirmSharePreview() async {
    final position = _pendingSharedPosition;
    if (position == null || !mounted) return;
    final placeName = _pendingSharedPlaceName;
    await handleConfirmSharePreview(
      context,
      ref,
      position,
      placeName,
      onClear: () {
        if (!mounted) return;
        setState(() {
          _pendingSharedPosition = null;
          _pendingSharedPlaceName = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _sleepTimerController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _volumeZoomHandler.dispose();
    ref.read(locationStreamProvider.notifier).stop();
    ref.read(mapStateProvider.notifier).cancelAnimation();
    super.dispose();
  }

  /// ユーザーがマップ等をタップしたとき（スリープタイマー再開）
  void _onUserInteraction() {
    _sleepTimerController.restoreBrightness();
    _sleepTimerController.restart(ref.read(sleepDurationProvider));
  }

  void _fetchPositionInBackground() {
    getPositionWithPermission(
      context,
      onOpenSettings: () => _expectingReturnFromSettings = true,
    ).timeout(const Duration(seconds: 20), onTimeout: () => null).then((pos) {
      if (!mounted) return;
      final position = pos ?? _defaultPosition();
      setState(() {
        if (pos != null) _initialPosition = pos;
        _positionFetchCompleted = true;
      });
      if (pos == null &&
          !_hasShownLocationUnavailableHint &&
          !_isConnectivityOffline) {
        _hasShownLocationUnavailableHint = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.locationUnavailableWithRetry,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.openSettings,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          );
        });
      }
      _hasTriggeredInitialRouteFetch = true;
      ref.read(mapStateProvider.notifier).fetchOrLoadRouteIfNeeded(
        position,
        animateCamera: (bounds) async {
          if (bounds != null) {
            await ref
                .read(cameraControllerProvider.notifier)
                .animateToBounds(bounds);
          }
        },
      );
    });
  }

  Widget _buildOfflineLayout(BuildContext context, VoidCallback onRetry) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final tileProviderKey = ref.watch(mapTileProviderKeyProvider);
    final position = _initialPosition ?? _defaultPosition();

    return MapScreenContent(
      key: ValueKey(tileProviderKey),
      initialPosition: LatLng(position.latitude, position.longitude),
      initialZoom: mapState.savedZoomLevel ?? _defaultZoom,
      polylines: mapState.routePolylines,
      markers: mapState.routeMarkers,
      mapStyleMode: mapState.mapStyleMode,
      onCameraIdle: _onCameraIdle,
      onMapCreated: _onMapCreated,
      onMapStyleTap: _onMapStyleTap,
      onRouteBoundsTap: _onRouteBoundsTap,
      onMyLocationTap: _moveCameraToCurrentPosition,
      showMyLocationButton: !locationState.isActive,
      isStreamActive: locationState.isActive,
      onToggleLocationStream: _toggleLocationStream,
      progressBarValue: locationState.progressBarValue,
      isLowMode: locationState.isInLowMode,
      isStreamAccuracyLow: locationState.isAccuracyLow,
      onGpsLevelTap: () =>
          ref.read(locationStreamProvider.notifier).switchGpsLevel(
                onPosition: _onPositionUpdate,
              ),
      onSleepSettingsTap: () => showSleepSettingsFlow(
        context,
        ref,
        restoreBrightness: _sleepTimerController.restoreBrightness,
        restartTimer: _sleepTimerController.restart,
      ),
      onDistanceUnitTap: () => showDistanceUnitFlow(context, ref),
      onGpxImportTap: () => handleGpxImportTap(context, ref),
      onGpxExportTap: () => handleGpxExportTap(context, ref),
      onOfflineMapTap: () => handleOfflineMapTap(context, ref),
      onAddPoiTap: () => handleAddPoiTap(
        context,
        ref,
        getMounted: () => mounted,
        onStartMapTapAddMode: () => setState(() => _isMapTapAddMode = true),
        onStartDragMode: () => setState(() => _isDragMode = true),
        onDragEnd: (p, latLng) => handlePoiDragEnd(
          context,
          ref,
          p,
          latLng,
          onStopDragMode: () => setState(() => _isDragMode = false),
        ),
      ),
      hasUserPois: mapState.userPois.isNotEmpty,
      onUserInteraction: _onUserInteraction,
      isDragMode: _isDragMode,
      isMapTapAddMode: _isMapTapAddMode || _pendingSharedPosition != null,
      onMapLongPress: null,
      offlineCenter: OfflinePlaceholderView(onRetry: onRetry),
      isShareMode: _isShareMode,
      onShareTap: (key) {
        handleShareButtonTap(
          context: context,
          ref: ref,
          screenshotKey: key,
          currentPosition: _latestStreamPosition != null
              ? LatLng(
                  _latestStreamPosition!.latitude,
                  _latestStreamPosition!.longitude,
                )
              : null,
          previousPosition: _previousStreamPosition != null
              ? LatLng(
                  _previousStreamPosition!.latitude,
                  _previousStreamPosition!.longitude,
                )
              : null,
          onShareModeChanged: (isShareMode, {shareHp}) => setState(() {
            _isShareMode = isShareMode;
            _shareHp = shareHp;
          }),
          getMounted: () => mounted,
        );
      },
    );
  }

  Widget _buildMapLayout(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);
    final tileProviderKey = ref.watch(mapTileProviderKeyProvider);
    final position = _initialPosition ?? _defaultPosition();

    // 位置取得が完了してからルート作成（ネットワークチェックでオンライン表示が先になる場合の対策）
    if (_positionFetchCompleted && !_hasTriggeredInitialRouteFetch) {
      _hasTriggeredInitialRouteFetch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapStateProvider.notifier).fetchOrLoadRouteIfNeeded(
          position,
          animateCamera: (bounds) async {
            if (bounds != null) {
              await ref
                  .read(cameraControllerProvider.notifier)
                  .animateToBounds(bounds);
            }
          },
        );
      });
    }

    var markers = mapState.routeMarkers;
    if (_pendingSharedPosition != null) {
      markers = [
        ...markers,
        Marker(
          point: _pendingSharedPosition!,
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: _sharePreviewIcon ??
              Icon(Icons.place, color: Colors.orange, size: 48),
        ),
      ];
    }
    if (locationState.isActive) {
      final pos =
          _latestStreamPosition ?? _initialPosition ?? _defaultPosition();
      final posLatLng = LatLng(pos.latitude, pos.longitude);
      markers = [
        ...markers,
        Marker(
          point: posLatLng,
          width: 72,
          height: 72,
          alignment: Alignment.center,
          child: PulsingLocationMarker(
            size: 72,
            isDarkMode: mapState.mapStyleMode == 2,
          ),
        ),
      ];
    }

    final calloutData = computeCalloutData(
      isShareMode: _isShareMode,
      hasPosition: locationState.isActive ||
          _latestStreamPosition != null ||
          _initialPosition != null,
      currentPosition: () {
        final pos =
            _latestStreamPosition ?? _initialPosition ?? _defaultPosition();
        return LatLng(pos.latitude, pos.longitude);
      }(),
      previousPosition: _previousStreamPosition != null
          ? LatLng(
              _previousStreamPosition!.latitude,
              _previousStreamPosition!.longitude,
            )
          : null,
      routePoints: mapState.fullRoutePoints ?? mapState.savedRoutePoints,
      distanceUnit: distanceUnit,
    );

    return Stack(
      children: [
        MapScreenContent(
          key: ValueKey(tileProviderKey),
          initialPosition: LatLng(position.latitude, position.longitude),
          initialZoom: mapState.savedZoomLevel ?? _defaultZoom,
          polylines: mapState.routePolylines,
          markers: markers,
          calloutPosition: calloutData.position,
          calloutText: calloutData.text,
          calloutHp: _shareHp,
          mapStyleMode: mapState.mapStyleMode,
          onCameraIdle: _onCameraIdle,
          onMapCreated: _onMapCreated,
          onMapStyleTap: _onMapStyleTap,
          onRouteBoundsTap: _onRouteBoundsTap,
          onMyLocationTap: _moveCameraToCurrentPosition,
          showMyLocationButton: !locationState.isActive,
          isStreamActive: locationState.isActive,
          onToggleLocationStream: _toggleLocationStream,
          progressBarValue: locationState.progressBarValue,
          isLowMode: locationState.isInLowMode,
          isStreamAccuracyLow: locationState.isAccuracyLow,
          onGpsLevelTap: () =>
              ref.read(locationStreamProvider.notifier).switchGpsLevel(
                    onPosition: _onPositionUpdate,
                  ),
          onSleepSettingsTap: () => showSleepSettingsFlow(
            context,
            ref,
            restoreBrightness: _sleepTimerController.restoreBrightness,
            restartTimer: _sleepTimerController.restart,
          ),
          onDistanceUnitTap: () => showDistanceUnitFlow(context, ref),
          onGpxImportTap: () => handleGpxImportTap(context, ref),
          onGpxExportTap: () => handleGpxExportTap(context, ref),
          onOfflineMapTap: () => handleOfflineMapTap(context, ref),
          onAddPoiTap: () => handleAddPoiTap(
            context,
            ref,
            getMounted: () => mounted,
            onStartMapTapAddMode: () => setState(() => _isMapTapAddMode = true),
            onStartDragMode: () => setState(() => _isDragMode = true),
            onDragEnd: (p, latLng) => handlePoiDragEnd(
              context,
              ref,
              p,
              latLng,
              onStopDragMode: () => setState(() => _isDragMode = false),
            ),
          ),
          hasUserPois: mapState.userPois.isNotEmpty,
          onUserInteraction: _onUserInteraction,
          isDragMode: _isDragMode,
          isMapTapAddMode: _isMapTapAddMode || _pendingSharedPosition != null,
          onMapLongPress: _isMapTapAddMode && _pendingSharedPosition == null
              ? _onMapLongPress
              : null,
          isShareMode: _isShareMode,
          onShareTap: (key) {
            handleShareButtonTap(
              context: context,
              ref: ref,
              screenshotKey: key,
              currentPosition: _latestStreamPosition != null
                  ? LatLng(
                      _latestStreamPosition!.latitude,
                      _latestStreamPosition!.longitude,
                    )
                  : null,
              previousPosition: _previousStreamPosition != null
                  ? LatLng(
                      _previousStreamPosition!.latitude,
                      _previousStreamPosition!.longitude,
                    )
                  : null,
              onShareModeChanged: (isShareMode, {shareHp}) => setState(() {
                _isShareMode = isShareMode;
                _shareHp = shareHp;
              }),
              getMounted: () => mounted,
            );
          },
        ),
      ],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveMapStyleMode(ref.read(mapStateProvider).mapStyleMode);
      WakelockPlus.disable();
      ref.read(locationStreamProvider.notifier).stop();
      _sleepTimerController.cancel();
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

    WakelockPlus.enable();
    _sleepTimerController.restart(ref.read(sleepDurationProvider));

    // 共有シートから本アプリを選択してフォアグラウンドに戻った場合、
    // 共有モードをリセットして吹き出しが残らないようにする
    if (_isShareMode) {
      setState(() {
        _isShareMode = false;
        _shareHp = null;
      });
    }

    if (_expectingReturnFromSettings) {
      _expectingReturnFromSettings = false;
      if (!mounted) return;
      _fetchPositionInBackground();
      return;
    }

    ref.read(locationStreamProvider.notifier).restoreFromSaved(
          onPosition: _onPositionUpdate,
        );
  }

  void _onPositionUpdate(Position position, Position? previous) {
    if (!mounted) return;
    _previousStreamPosition = previous;
    _latestStreamPosition = position;
    if (previous != null) {
      final b = bearingFromPositions(previous, position);
      if (b != null) _lastBearing = b;
    }
    final zoomToUse = _isFirstPositionAfterStreamOn
        ? _trackingZoom
        : (ref.read(cameraControllerProvider)?.camera.zoom ??
            ref.read(mapStateProvider).savedZoomLevel ??
            _trackingZoom);
    if (_isFirstPositionAfterStreamOn) {
      _isFirstPositionAfterStreamOn = false;
    }
    ref.read(cameraControllerProvider.notifier).animateTo(
          LatLng(position.latitude, position.longitude),
          zoom: zoomToUse,
          bearing: _lastBearing,
        );
    setState(() {});
  }

  Future<void> _onCameraIdle() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null) return;
    await ref.read(mapStateProvider.notifier).onCameraIdle(controller);
  }

  Future<void> _onMapCreated(MapController controller) async {
    ref.read(cameraControllerProvider.notifier).setController(controller);
    ref.read(mapStateProvider.notifier).setPoiTapHandler((poi) {
      showPoiDetailSheet(context, name: poi.name, description: poi.description);
    });
    ref.read(mapStateProvider.notifier).setUserPoiTapHandler((poi) {
      final l10n = AppLocalizations.of(context)!;
      final unit = ref.read(distanceUnitProvider);
      final prefix = poi.km != null ? '${formatDistance(poi.km!, unit)}：' : '';
      final title = poi.title.isEmpty ? l10n.titleNone : poi.title;
      showPoiDetailSheet(
        context,
        name: '$prefix$title',
        description: poi.body,
      );
    });
    await ref.read(mapStateProvider.notifier).onMapCreated(
          controller,
          animateCamera: (bounds) => ref
              .read(cameraControllerProvider.notifier)
              .animateToBounds(bounds),
        );
    // 共有URLから起動した場合、地図作成後に該当座標へズーム（起動直後はcontroller未設定のためここで実行）
    if (_pendingSharedPosition != null && mounted) {
      await ref.read(cameraControllerProvider.notifier).animateTo(
            _pendingSharedPosition!,
            zoom: 18.0,
          );
    }
  }

  Future<void> _onMapStyleTap() async {
    final controller = ref.read(cameraControllerProvider);
    await ref.read(mapStateProvider.notifier).toggleMapStyle(controller);
  }

  Future<void> _onRouteBoundsTap() async {
    final bounds = ref.read(mapStateProvider.notifier).getRouteBounds();
    if (bounds != null) {
      await ref.read(cameraControllerProvider.notifier).animateToBounds(bounds);
    }
  }

  Future<void> _moveCameraToCurrentPosition() async {
    final position = await getCurrentPositionSilent();
    if (!mounted || position == null) return;
    await ref.read(cameraControllerProvider.notifier).animateTo(
          LatLng(position.latitude, position.longitude),
        );
  }

  Future<void> _toggleLocationStream() async {
    final wasActive = ref.read(locationStreamProvider).isActive;
    await ref.read(locationStreamProvider.notifier).toggle(
          onPosition: _onPositionUpdate,
        );
    if (wasActive) {
      setState(() {
        _latestStreamPosition = null;
        _previousStreamPosition = null;
      });
    } else {
      ref.read(mapStateProvider.notifier).overrideSavedZoom(_trackingZoom);
      _isFirstPositionAfterStreamOn = true;
    }
  }

  Future<void> _onCancelDragMode() async {
    await ref.read(mapStateProvider.notifier).stopPoiDrag();
    if (!mounted) return;
    setState(() => _isDragMode = false);
  }

  Future<void> _onCancelMapTapAddMode() async {
    if (!mounted) return;
    setState(() => _isMapTapAddMode = false);
  }

  Future<void> _onMapLongPress(LatLng position) async {
    if (!_isMapTapAddMode || !mounted) return;
    await handleMapLongPressPoiAdd(
      context,
      ref,
      position,
      initialTitle: _pendingSharedPlaceName,
      onComplete: () => setState(() => _isMapTapAddMode = false),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (!_positionFetchCompleted) {
      return ConnectivityCheckingView(
        message: AppLocalizations.of(context)!.fetchingLocation,
      );
    }
    return _buildMapLayout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _isFirstLaunch == null
              ? ConnectivityCheckingView(
                  message: AppLocalizations.of(context)!.fetchingLocation,
                )
              : _isFirstLaunch!
                  ? ConnectivityGate(
                      onOnline: () {
                        ref
                            .read(cameraControllerProvider.notifier)
                            .clearController();
                        setState(() => _hasTriggeredInitialRouteFetch = false);
                        ref
                            .read(mapStateProvider.notifier)
                            .resetInitialRouteFetchForRetry();
                      },
                      onOffline: () {
                        _isConnectivityOffline = true;
                      },
                      builder: (context, gateState, onRetry) {
                        if (gateState == ConnectivityGateState.checking) {
                          return const ConnectivityCheckingView();
                        }
                        if (gateState == ConnectivityGateState.offline) {
                          return _buildOfflineLayout(context, onRetry);
                        }
                        return _buildBody(context);
                      },
                    )
                  : _buildBody(context),
        ),
        if (_isDragMode) ...[
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x66000000)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.6),
              child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox(
                  height: 96,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.dragMarkerHint,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white60,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _onCancelDragMode,
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (_isMapTapAddMode || _pendingSharedPosition != null) ...[
          const Positioned.fill(
            child: IgnorePointer(
              child: ColoredBox(color: Color(0x66000000)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: Colors.grey.shade800,
              child: SafeArea(
                top: false,
                bottom: false,
                child: SizedBox(
                  // height: 96,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _pendingSharedPosition != null
                                ? AppLocalizations.of(context)!
                                    .registerThisPlaceAsPoi
                                : AppLocalizations.of(context)!
                                    .longPressPoiHint,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_pendingSharedPosition != null) ...[
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: _onCancelSharePreview,
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _onConfirmSharePreview,
                            child: Text(
                              AppLocalizations.of(context)!.ok,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ] else
                          TextButton(
                            onPressed: _onCancelMapTapAddMode,
                            child: Text(
                              AppLocalizations.of(context)!.cancel,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

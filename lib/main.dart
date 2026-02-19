import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'constants/map_styles.dart';
import 'repositories/first_launch_repository.dart';
import 'utils/map_utils.dart';
import 'parsers/gpx_parser.dart';
import 'services/volume_zoom_handler.dart';
import 'services/gpx_import_service.dart';
import 'services/route_marker_service.dart';
import 'services/location_service.dart';
import 'services/brightness_service.dart';
import 'services/route_fetch_service.dart';
import 'services/route_animation_runner.dart';
import 'services/gpx_channel_service.dart';
import 'services/location_tracking_service.dart';
import 'widgets/location_error_view.dart';
import 'widgets/map_screen_content.dart';
import 'widgets/poi_detail_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brevet Map',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Brevet Map'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  GoogleMapController? mapController;
  Future<Position?>? _positionFuture;
  Set<Polyline> _routePolylines = {};
  Set<Marker> _routeMarkers = {};

  /// 0=通常カラー, 1=モノクロ, 2=反転（ダーク）
  int _mapStyleMode = 0;
  bool _hasStartedInitialRouteFetch = false;

  List<LatLng>? _savedRoutePoints;
  List<GpxPoi> _gpxPois = [];
  List<LatLng>? _fullRoutePoints;

  /// 「設定を開く」で設定アプリへ送った場合に true。フォア復帰時に位置情報を再取得するため
  bool _expectingReturnFromSettings = false;

  late final VolumeZoomHandler _volumeZoomHandler;
  late final RouteAnimationRunner _routeAnimationRunner;

  /// 前回適用した bearing（移動が少ないときは再利用）
  double _lastBearing = 0.0;

  /// ストリーム中の地図ズームレベル（保存値が無いときのデフォルト）
  static const double _trackingZoom = 15.0;

  /// 起動時・ズーム未保存時の初期ズーム
  static const double _defaultZoom = 14.0;

  /// ユーザーが変更したズームレベル（null＝未保存＝デフォルト使用）。アプリ終了時にクリア
  double? _savedZoomLevel;

  /// このセッションで位置情報ストリームを一度でも開始したか（初回ON時のみ15にするため）
  bool _hasStartedLocationStreamThisSession = false;

  /// カメラ移動終了時に現在のズームを保存する（ピンチ・ボリュームボタン等）
  Future<void> _onCameraIdle() async {
    final z = await mapController?.getZoomLevel();
    if (z != null && mounted) setState(() => _savedZoomLevel = z);
  }

  late final LocationTrackingService _locationTrackingService;

  /// スライダー表示値（0.0〜1.0）。0.5＝現在の輝度（初期値）。
  double _brightnessSliderValue = 0.5;

  /// 起動時の輝度。スライダー中央（0.5）がこの値になる。
  double _initialBrightness = 0.5;
  bool _brightnessSupported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _volumeZoomHandler = VolumeZoomHandler(getController: () => mapController);
    _volumeZoomHandler.start();
    _routeAnimationRunner = RouteAnimationRunner();
    _locationTrackingService = LocationTrackingService();
    _positionFuture = getPositionWithPermission(
      context,
      onOpenSettings: () {
        _expectingReturnFromSettings = true;
      },
    );
    _preloadSavedRoute();
    GpxChannelService.setMethodCallHandler((content) {
      if (mounted) _applyImportedGpx(content);
    });
    GpxChannelService.getInitialGpxContent().then((content) {
      if (content != null && content.isNotEmpty && mounted) {
        _applyImportedGpx(content);
      }
    });
    loadInitialBrightness().then((r) {
      if (mounted) {
        setState(() {
          _initialBrightness = r.initialBrightness;
          _brightnessSupported = r.supported;
          _brightnessSliderValue = 0.5;
        });
      }
    });
    WakelockPlus.enable();
    _loadSavedMapStyleMode();
  }

  /// GPXインポート時: パース・保存はサービスに委譲し、UI 更新とカメラのみ行う
  Future<void> _applyImportedGpx(String gpxContent) async {
    final result = await parseAndSaveGpx(gpxContent);
    if (result == null) {
      if (gpxContent.trim().isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このファイルはGPX形式ではありません')),
        );
      }
      return;
    }
    if (result.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPXにルートまたはウェイポイントが含まれていません')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _savedRoutePoints =
          result.trackPoints.isNotEmpty ? result.trackPoints : null;
      _gpxPois = result.waypoints;
      _hasStartedInitialRouteFetch = true;
    });

    if (result.trackPoints.isNotEmpty) {
      _routeAnimationRunner.cancel();
      _startRouteAnimation(result.trackPoints, animate: false);
      final bounds = boundsFromPointsWithPois(
        result.trackPoints,
        result.waypoints.map((p) => p.position).toList(),
      );
      if (bounds != null && mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 30),
        );
      }
    } else if (result.waypoints.isNotEmpty) {
      await _refreshRouteMarkers([]);
      if (mapController != null) {
        final bounds =
            boundsFromPoints(result.waypoints.map((p) => p.position).toList());
        if (bounds != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 30),
          );
        }
      }
    }
  }

  /// スタート・ゴール・POI マーカーを再構築して [ _routeMarkers ] を更新する
  Future<void> _refreshRouteMarkers(List<LatLng> routePoints) async {
    final markers = await buildRouteMarkers(
      routePoints: routePoints,
      pois: _gpxPois,
      onPoiTap: (poi) => showPoiDetailSheet(
        context,
        name: poi.name,
        description: poi.description,
      ),
    );
    if (!mounted) return;
    setState(() => _routeMarkers = markers);
  }

  /// 保存済みの地図表示モードを読み込み、適用する（未保存なら 0=カラー）
  Future<void> _loadSavedMapStyleMode() async {
    final mode = await loadMapStyleMode();
    if (!mounted) return;
    setState(() => _mapStyleMode = mode);
    await mapController?.setMapStyle(mapStyleForMode(mode));
  }

  /// 保存済みルートとPOIを事前に読み込む（地図の初期カメラ位置を設定するため）
  Future<void> _preloadSavedRoute() async {
    final isFirst = await isFirstLaunch();
    if (isFirst) return;
    final result = await loadSavedRouteWithPois();
    if (!mounted) return;
    setState(() {
      if (result.points != null && result.points!.isNotEmpty) {
        _savedRoutePoints = result.points;
      }
      _gpxPois = result.pois;
    });
  }

  @override
  void dispose() {
    _savedZoomLevel = null;
    WakelockPlus.disable();
    _locationTrackingService.stop();
    _volumeZoomHandler.dispose();
    _routeAnimationRunner.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ストリームで位置情報取得を開始または停止する
  void _toggleLocationStream() {
    if (_locationTrackingService.isActive) {
      _locationTrackingService.stop();
      saveLocationStreamActive(false);
      setState(() {});
      return;
    }
    _lastBearing = 0.0;
    if (!_hasStartedLocationStreamThisSession) {
      setState(() {
        _savedZoomLevel = 15;
        _hasStartedLocationStreamThisSession = true;
      });
    }
    _locationTrackingService.start(
      onPosition: (position, previous) {
        if (!mounted || mapController == null) return;
        if (previous != null) {
          final b = bearingFromPositions(previous, position);
          if (b != null) _lastBearing = b;
        }
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              bearing: _lastBearing,
              zoom: _savedZoomLevel ?? _trackingZoom,
              tilt: 0,
            ),
          ),
        );
      },
      onError: () {
        if (mounted) setState(() {});
      },
      isActive: () => mounted,
    );
    saveLocationStreamActive(true);
    setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveMapStyleMode(_mapStyleMode);
      WakelockPlus.disable();
      _locationTrackingService.stop();
      if (mounted) setState(() {});
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

    WakelockPlus.enable();
    // 設定アプリから戻ってきた場合のみ: 位置情報を再取得してウィジェットを再描画
    if (_expectingReturnFromSettings) {
      _expectingReturnFromSettings = false;
      if (!mounted) return;
      setState(() {
        _positionFuture = getPositionWithPermission(
          context,
          onOpenSettings: () {
            _expectingReturnFromSettings = true;
          },
        );
      });
      return;
    }

    // 通常のフォアグラウンド復帰: 保存した設定で位置情報ストリームを復元（trueならON、falseならOFFのまま現在地へカメラ移動）
    loadLocationStreamActive().then((wasActive) {
      if (!mounted) return;
      if (wasActive) {
        _toggleLocationStream();
      } else {
        _moveCameraToCurrentPosition();
      }
    });
  }

  /// 現在地を取得し、カメラをその位置に移動する。ダイアログは出さない。地図の再描画は行わない
  Future<void> _moveCameraToCurrentPosition() async {
    final position = await getCurrentPositionSilent();
    if (!mounted || position == null || mapController == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  /// 初回起動: Directions API でルート取得→保存→描画。2回目以降: 保存済みルートを読み出して描画（API は呼ばない）
  /// 地図表示後にバックグラウンドで実行され、ルート取得後にアニメーションで表示する
  Future<void> _fetchOrLoadRouteIfNeeded(Position position) async {
    if (_hasStartedInitialRouteFetch) return;
    _hasStartedInitialRouteFetch = true;

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    final points = await fetchOrLoadRoute(
      position,
      savedRoutePoints: _savedRoutePoints,
    );
    if (!mounted || points == null || points.isEmpty) return;

    final pts = points;
    if (_routePolylines.isEmpty) {
      _startRouteAnimation(pts);
    }
    if (mapController != null) {
      final bounds = boundsFromPoints(pts);
      if (bounds != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 30),
        );
      }
    }
  }

  /// ルートを徐々に描画するアニメーションを開始
  /// [animate] が false の場合はアニメーションせずに一括表示（GPXインポート用）
  void _startRouteAnimation(List<LatLng> fullPoints, {bool animate = true}) {
    _fullRoutePoints = fullPoints;
    _refreshRouteMarkers(fullPoints);
    _routeAnimationRunner.start(
      fullPoints,
      buildMarkers: false,
      animate: animate,
      onPolyline: (p) {
        if (mounted) setState(() => _routePolylines = p);
      },
      onMarkers: (_) {},
      mounted: () => mounted,
    );
  }

  /// ルート全体表示
  Future<void> _animateToRouteBounds() async {
    final points = _fullRoutePoints ?? _savedRoutePoints;
    if (points == null || points.isEmpty || mapController == null) return;
    final bounds = boundsFromPoints(points);
    if (bounds == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 30),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Position?>(
        future: _positionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('位置情報の取得に失敗しました'),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Scaffold(
              body: LocationErrorView(),
            );
          }

          final position = snapshot.data!;

          // 地図表示後にバックグラウンドでルート取得を開始
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchOrLoadRouteIfNeeded(position);
          });

          return MapScreenContent(
            initialPosition: LatLng(
              position.latitude,
              position.longitude,
            ),
            initialZoom: _savedZoomLevel ?? _defaultZoom,
            polylines: _routePolylines,
            markers: _routeMarkers,
            mapStyleMode: _mapStyleMode,
            onCameraIdle: _onCameraIdle,
            onMapCreated: (controller) async {
              mapController = controller;
              await controller
                  .setMapStyle(mapStyleForMode(_mapStyleMode));
              if (_savedRoutePoints != null &&
                  _savedRoutePoints!.isNotEmpty) {
                final bounds = boundsFromPoints(_savedRoutePoints!);
                if (bounds != null) {
                  await controller.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 30),
                  );
                  if (mounted) {
                    _startRouteAnimation(_savedRoutePoints!);
                  }
                }
              }
            },
            onMapStyleTap: () async {
              setState(() => _mapStyleMode = (_mapStyleMode + 1) % 3);
              await mapController?.setMapStyle(
                  mapStyleForMode(_mapStyleMode));
              await saveMapStyleMode(_mapStyleMode);
            },
            onRouteBoundsTap: _animateToRouteBounds,
            onMyLocationTap: _moveCameraToCurrentPosition,
            showMyLocationButton: !_locationTrackingService.isActive,
            brightnessSupported: _brightnessSupported,
            brightnessSliderValue: _brightnessSliderValue,
            onBrightnessChanged: (value) async {
              setState(() => _brightnessSliderValue = value);
              final brightness =
                  sliderValueToBrightness(_initialBrightness, value);
              try {
                await ScreenBrightness()
                    .setApplicationScreenBrightness(brightness);
              } catch (_) {}
            },
            isStreamActive: _locationTrackingService.isActive,
            onToggleLocationStream: _toggleLocationStream,
            progressBarValue: _locationTrackingService.progressBarValue,
          );
        },
      ),
    );
  }
}

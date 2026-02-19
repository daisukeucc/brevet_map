import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'api_config.dart';
import 'directions_repository.dart';
import 'first_launch_repository.dart';
import 'gpx_parser.dart';

/// 地図をモノクロ表示するためのスタイル JSON
const String _mapStyleGrayscale = '''
[
  {"featureType": "all", "elementType": "all", "stylers": [{"saturation": -100}]}
]
''';

/// 地図を反転表示（黒を多く）するためのスタイル JSON（ダークモード）
const String _mapStyleDark = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
  {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
  {"featureType": "administrative.province", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
  {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "road", "elementType": "labels.text.stroke", "stylers": [{"color": "#1d2c4d"}]},
  {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
  {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#0e1626"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
]
''';

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

  String? _mapStyleForMode(int mode) {
    switch (mode) {
      case 1:
        return _mapStyleGrayscale;
      case 2:
        return _mapStyleDark;
      default:
        return null;
    }
  }

  List<LatLng>? _savedRoutePoints;
  List<GpxPoi> _gpxPois = [];
  Timer? _routeAnimationTimer;
  List<LatLng>? _fullRoutePoints;
  int _animatedRoutePointCount = 0;

  static const _gpxChannel = MethodChannel('com.example.brevet_map/gpx');

  /// 「設定を開く」で設定アプリへ送った場合に true。フォア復帰時に位置情報を再取得するため
  bool _expectingReturnFromSettings = false;

  /// ボリュームボタンでズームするためのリスナー（iOSは volume_controller、Androidは keydown でインターセプト）
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<HardwareButton>? _volumeKeySubscription;
  double? _previousVolume;

  /// ボリュームキー1回あたりのズーム量
  static const _volumeZoomAmountUp = 1.2;
  static const _volumeZoomAmountDown = 1.2;

  /// ボリュームキー連打・長押しを無視するデバウンス（この間の同一キーは1回だけズーム）
  static const _volumeDebounce = Duration(milliseconds: 400);
  DateTime? _volumeLastKeyTime;
  HardwareButton? _volumeLastKeyButton;
  DateTime? _volumeLastChangeTime;
  bool? _volumeLastChangeUp;

  /// 位置情報ストリーム（開始ボタンで開始・停止）
  StreamSubscription<Position>? _positionStreamSubscription;

  /// 進行方向（bearing）計算用の前回位置
  Position? _lastPositionForBearing;

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

  /// 2点間の進行方向を度（0=北、90=東）で返す（移動が短い場合は null）
  double? _bearingFromPositions(Position from, Position to) {
    final dist = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    if (dist < 3.0) return null; // 3m未満は向きを更新しない（ジッター防止）
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLon = (to.longitude - from.longitude) * math.pi / 180;
    final x = math.sin(dLon) * math.cos(lat2);
    final y = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    var bearing = math.atan2(x, y) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  /// 位置取得中に表示する左→右アニメーションバー用
  static const _progressBarUpdateInterval = Duration(milliseconds: 100);
  static const _progressBarCycleDuration = Duration(milliseconds: 1800);
  ValueNotifier<double>? _progressBarValue;
  Timer? _progressBarTimer;

  /// スライダー表示値（0.0〜1.0）。0.5＝現在の輝度（初期値）。
  double _brightnessSliderValue = 0.5;

  /// 起動時の輝度。スライダー中央（0.5）がこの値になる。
  double _initialBrightness = 0.5;
  bool _brightnessSupported = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _positionFuture = _getPositionWithPermission();
    _preloadSavedRoute();
    _setupGpxChannel();
    _requestInitialGpxContent();
    _setupVolumeZoomListener();
    _loadInitialBrightness();
    WakelockPlus.enable();
    _loadSavedMapStyleMode();
  }

  void _setupGpxChannel() {
    _gpxChannel.setMethodCallHandler((call) async {
      if (call.method == 'onGpxFileReceived' && call.arguments != null) {
        final content = call.arguments as String?;
        if (content != null && content.isNotEmpty && mounted) {
          _applyImportedGpx(content);
        }
      }
    });
  }

  Future<void> _requestInitialGpxContent() async {
    try {
      final content =
          await _gpxChannel.invokeMethod<String?>('getInitialGpxContent');
      if (content != null && content.isNotEmpty && mounted) {
        _applyImportedGpx(content);
      }
    } on PlatformException catch (_) {}
  }

  /// GPXインポート時: 既存ルートを削除し、パース結果を保存して地図に反映
  Future<void> _applyImportedGpx(String gpxContent) async {
    final result = parseGpx(gpxContent);
    if (result == null) {
      if (gpxContent.trim().isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このファイルはGPX形式ではありません')),
        );
      }
      return;
    }
    if (result.trackPoints.isEmpty && result.waypoints.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPXにルートまたはウェイポイントが含まれていません')),
        );
      }
      return;
    }

    await clearSavedRoute();

    if (result.trackPoints.isNotEmpty) {
      final encoded = encodePolyline(result.trackPoints);
      await saveRouteEncoded(encoded);
      await markInitialRouteShown();
    }

    if (result.waypoints.isNotEmpty) {
      final poisJson = jsonEncode(
        result.waypoints.map((p) => p.toJson()).toList(),
      );
      await saveGpxPois(poisJson);
    }

    if (!mounted) return;
    setState(() {
      _savedRoutePoints =
          result.trackPoints.isNotEmpty ? result.trackPoints : null;
      _gpxPois = result.waypoints;
      _hasStartedInitialRouteFetch = true;
    });

    if (result.trackPoints.isNotEmpty) {
      _routeAnimationTimer?.cancel();
      _startRouteAnimation(result.trackPoints, animate: false);
      final bounds = _boundsFromPointsWithPois(
        result.trackPoints,
        result.waypoints.map((p) => p.position).toList(),
      );
      if (bounds != null && mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 30),
        );
      }
    } else if (result.waypoints.isNotEmpty) {
      await _updateStartGoalMarkers([]);
      if (mapController != null) {
        final bounds =
            _boundsFromPoints(result.waypoints.map((p) => p.position).toList());
        if (bounds != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 30),
          );
        }
      }
    }
  }

  /// 保存済みの地図表示モードを読み込み、適用する（未保存なら 0=カラー）
  Future<void> _loadSavedMapStyleMode() async {
    final mode = await loadMapStyleMode();
    if (!mounted) return;
    setState(() => _mapStyleMode = mode);
    await mapController?.setMapStyle(_mapStyleForMode(mode));
  }

  /// 起動時に現在の画面明るさを読み込み、スライダー中央の基準とする
  Future<void> _loadInitialBrightness() async {
    try {
      final value = await ScreenBrightness().current;
      final brightness = value.clamp(0.0, 1.0);
      if (mounted) {
        setState(() {
          _initialBrightness = brightness;
          _brightnessSliderValue = 0.5; // 真ん中＝今の輝度
        });
      }
    } catch (_) {
      if (mounted) setState(() => _brightnessSupported = false);
    }
  }

  /// スライダー値（0〜1、0.5＝初期輝度）を実際の輝度（0〜1）に変換
  double _sliderValueToBrightness(double slider) {
    if (slider <= 0.5) {
      return _initialBrightness * (slider / 0.5);
    }
    return _initialBrightness +
        (1.0 - _initialBrightness) * ((slider - 0.5) / 0.5);
  }

  /// ボリューム上でズームイン、下でズームアウト（長押しのリピートは無視して1回だけ）
  void _setupVolumeZoomListener() {
    if (Platform.isAndroid) {
      _volumeKeySubscription =
          FlutterAndroidVolumeKeydown.stream.listen((event) {
        if (mapController == null) return;
        final now = DateTime.now();
        if (_volumeLastKeyTime != null &&
            _volumeLastKeyButton == event &&
            now.difference(_volumeLastKeyTime!) < _volumeDebounce) {
          return; // 長押しリピートは無視
        }
        _volumeLastKeyTime = now;
        _volumeLastKeyButton = event;
        if (event == HardwareButton.volume_up) {
          mapController!
              .animateCamera(CameraUpdate.zoomBy(_volumeZoomAmountUp));
        } else if (event == HardwareButton.volume_down) {
          mapController!
              .animateCamera(CameraUpdate.zoomBy(-_volumeZoomAmountDown));
        }
      });
      return;
    }
    VolumeController.instance.showSystemUI = false;
    _volumeSubscription = VolumeController.instance.addListener((volume) {
      if (_previousVolume == null) {
        _previousVolume = volume;
        return;
      }
      final now = DateTime.now();
      final isUp = volume > _previousVolume!;
      final isDown = volume < _previousVolume!;
      if (isUp && mapController != null) {
        if (_volumeLastChangeTime != null &&
            _volumeLastChangeUp == true &&
            now.difference(_volumeLastChangeTime!) < _volumeDebounce) {
          VolumeController.instance.setVolume(_previousVolume!);
          return;
        }
        _volumeLastChangeTime = now;
        _volumeLastChangeUp = true;
        mapController!.animateCamera(CameraUpdate.zoomBy(_volumeZoomAmountUp));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      if (isDown && mapController != null) {
        if (_volumeLastChangeTime != null &&
            _volumeLastChangeUp == false &&
            now.difference(_volumeLastChangeTime!) < _volumeDebounce) {
          VolumeController.instance.setVolume(_previousVolume!);
          return;
        }
        _volumeLastChangeTime = now;
        _volumeLastChangeUp = false;
        mapController!
            .animateCamera(CameraUpdate.zoomBy(-_volumeZoomAmountDown));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      _previousVolume = volume;
    }, fetchInitialVolume: true);
  }

  /// 保存済みルートとPOIを事前に読み込む（地図の初期カメラ位置を設定するため）
  Future<void> _preloadSavedRoute() async {
    final isFirst = await isFirstLaunch();
    if (!isFirst) {
      final points = await _loadSavedRoute();
      final poisJson = await loadGpxPois();
      List<GpxPoi> pois = [];
      if (poisJson != null && poisJson.isNotEmpty) {
        try {
          final list = jsonDecode(poisJson) as List<dynamic>;
          pois = list
              .map((e) => GpxPoi.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          if (points != null && points.isNotEmpty) _savedRoutePoints = points;
          _gpxPois = pois;
        });
      }
    }
  }

  @override
  void dispose() {
    _savedZoomLevel = null;
    WakelockPlus.disable();
    _progressBarTimer?.cancel();
    _progressBarTimer = null;
    _progressBarValue = null;
    _positionStreamSubscription?.cancel();
    _volumeSubscription?.cancel();
    _volumeKeySubscription?.cancel();
    _routeAnimationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// ストリームで位置情報取得を開始または停止する
  void _toggleLocationStream() {
    if (_positionStreamSubscription != null) {
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _lastPositionForBearing = null;
      _progressBarTimer?.cancel();
      _progressBarTimer = null;
      _progressBarValue = null;
      saveLocationStreamActive(false);
      setState(() {});
      return;
    }
    _lastPositionForBearing = null;
    _lastBearing = 0.0;
    if (!_hasStartedLocationStreamThisSession) {
      setState(() {
        _savedZoomLevel = 15;
        _hasStartedLocationStreamThisSession = true;
      });
    }
    _progressBarValue = ValueNotifier(0.0);
    final step = _progressBarUpdateInterval.inMilliseconds /
        _progressBarCycleDuration.inMilliseconds;
    _progressBarTimer = Timer.periodic(_progressBarUpdateInterval, (t) {
      if (!mounted || _positionStreamSubscription == null) return;
      double v = _progressBarValue!.value + step;
      if (v >= 1.0) v = 0.0;
      _progressBarValue!.value = v;
    });
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );
    _positionStreamSubscription = stream.listen(
      (Position position) {
        if (!mounted || mapController == null) return;
        if (_lastPositionForBearing != null) {
          final b = _bearingFromPositions(_lastPositionForBearing!, position);
          if (b != null) _lastBearing = b;
        }
        _lastPositionForBearing = position;
        final target = LatLng(position.latitude, position.longitude);
        mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: target,
              bearing: _lastBearing,
              zoom: _savedZoomLevel ?? _trackingZoom,
              tilt: 0,
            ),
          ),
        );
      },
      onError: (_) {
        _positionStreamSubscription?.cancel();
        _positionStreamSubscription = null;
        _lastPositionForBearing = null;
        _progressBarTimer?.cancel();
        _progressBarTimer = null;
        _progressBarValue = null;
        if (mounted) setState(() {});
      },
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
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      _lastPositionForBearing = null;
      _progressBarTimer?.cancel();
      _progressBarTimer = null;
      _progressBarValue = null;
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
        _positionFuture = _getPositionWithPermission();
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
    final position = await _getCurrentPositionSilent();
    if (!mounted || position == null || mapController == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  /// 現在地を取得する。許可なし・無効の場合は null を返し、ダイアログは出さない
  /// キャッシュを優先して即返し、なければ medium 精度で取得（high より速い）
  Future<Position?> _getCurrentPositionSilent() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) return lastPosition;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showMessageDialog(
    String title,
    String message, {
    String okText = 'OK',
    VoidCallback? onOk,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onOk?.call();
              },
              child: Text(okText),
            ),
          ],
        );
      },
    );
  }

  Future<Position?> _getPositionWithPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報が無効です',
          '位置情報サービスがオフになっています。端末の設定でオンにしてください。',
          okText: '設定を開く',
          onOk: () {
            _expectingReturnFromSettings = true;
            Geolocator.openLocationSettings();
          },
        );
      });
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報の許可が必要です',
          '位置情報の許可が拒否されました。許可しない場合は現在地を表示できません。',
        );
      });
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessageDialog(
          '位置情報の許可が必要です',
          '位置情報の許可が「今後表示しない」になっています。アプリ設定から許可をオンにしてください。',
          okText: '設定を開く',
          onOk: () {
            _expectingReturnFromSettings = true;
            Geolocator.openAppSettings();
          },
        );
      });
      return null;
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// 保存済みルートを読み込む（2回目以降の起動時用）
  Future<List<LatLng>?> _loadSavedRoute() async {
    final encoded = await loadRouteEncoded();
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return decodePolyline(encoded);
    } catch (_) {
      return null;
    }
  }

  /// 初回起動: Directions API でルート取得→保存→描画。2回目以降: 保存済みルートを読み出して描画（API は呼ばない）
  /// 地図表示後にバックグラウンドで実行され、ルート取得後にアニメーションで表示する
  Future<void> _fetchOrLoadRouteIfNeeded(Position position) async {
    if (_hasStartedInitialRouteFetch) return;
    _hasStartedInitialRouteFetch = true;

    // 少し待ってから開始（地図の初期表示を優先）
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    List<LatLng>? points;
    final isFirst = await isFirstLaunch();

    if (isFirst) {
      final current = LatLng(position.latitude, position.longitude);
      final waypoints = computeWaypointsFor100kmLoop(
        position.latitude,
        position.longitude,
      );
      final result = await fetchDirections(
        origin: current,
        destination: current,
        apiKey: googleMapsApiKey,
        waypoints: waypoints,
      );
      if (result == null || result.points.isEmpty || !mounted) return;
      await saveRouteEncoded(result.encoded);
      await markInitialRouteShown();
      points = result.points;
    } else {
      // 保存済みルートは既に _preloadSavedRoute で読み込まれている可能性がある
      if (_savedRoutePoints != null && _savedRoutePoints!.isNotEmpty) {
        points = _savedRoutePoints;
      } else {
        points = await _loadSavedRoute();
        if (points == null || points.isEmpty || !mounted) return;
      }
    }

    if (!mounted) return;

    if (points == null || points.isEmpty) return;

    final pts = points;
    // ルートを徐々に描画するアニメーションを開始
    if (_routePolylines.isEmpty) {
      _startRouteAnimation(pts);
    }

    // ルート全体が見えるようにカメラをアニメーション
    if (mapController != null) {
      final bounds = _boundsFromPoints(pts);
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
    _routeAnimationTimer?.cancel();
    _fullRoutePoints = fullPoints;
    _animatedRoutePointCount = 0;

    // スタート・ゴール・POIのマーカーを表示
    _updateStartGoalMarkers(fullPoints);

    // ポイント数が多い（GPX想定）または animate: false の場合は即時表示
    if (!animate || fullPoints.length <= 10 || fullPoints.length > 500) {
      // アニメーションなし：全ポイントを即時表示
      setState(() {
        _routePolylines = {
          Polyline(
            polylineId: const PolylineId('initial_route'),
            points: fullPoints,
            color: Colors.red,
            width: 5,
          ),
        };
      });
      _animatedRoutePointCount = fullPoints.length;
      return;
    }

    // 最初の数ポイントをすぐに表示（アニメーションの開始点）
    const initialPoints = 10;
    final startPoints = fullPoints.sublist(0, initialPoints);

    setState(() {
      _routePolylines = {
        Polyline(
          polylineId: const PolylineId('initial_route'),
          points: startPoints,
          color: Colors.red,
          width: 5,
        ),
      };
    });
    _animatedRoutePointCount = startPoints.length;

    // 残りのポイントを段階的に追加
    _routeAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 20), // 20msごとに更新（約50fps）
      (timer) {
        if (!mounted || _fullRoutePoints == null) {
          timer.cancel();
          return;
        }

        const pointsPerFrame = 5;
        final nextCount = (_animatedRoutePointCount + pointsPerFrame)
            .clamp(0, _fullRoutePoints!.length);

        if (nextCount >= _fullRoutePoints!.length) {
          setState(() {
            _routePolylines = {
              Polyline(
                polylineId: const PolylineId('initial_route'),
                points: _fullRoutePoints!,
                color: Colors.red,
                width: 5,
              ),
            };
          });
          timer.cancel();
          _routeAnimationTimer = null;
        } else {
          setState(() {
            _routePolylines = {
              Polyline(
                polylineId: const PolylineId('initial_route'),
                points: _fullRoutePoints!.sublist(0, nextCount),
                color: Colors.red,
                width: 5,
              ),
            };
          });
          _animatedRoutePointCount = nextCount;
        }
      },
    );
  }

  /// 角丸の正方形マーカーを生成（右下が座標に来るよう anchor 1, 1 で配置する想定）
  Future<BitmapDescriptor> _createRoundedSquareMarkerIcon({
    required Color backgroundColor,
    required bool isPlayIcon,
  }) async {
    const size = 106.0;
    const radius = 31.0;
    const borderWidth = 6.0;
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

    // 枠線を角丸で見せるため、白い角丸四角→その内側に背景色の角丸四角を重ねる
    final outerRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size, size),
      const Radius.circular(radius),
    );
    final innerRadius = (radius - borderWidth).clamp(0.0, double.infinity);
    final innerRrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(borderWidth, borderWidth, size - borderWidth * 2,
          size - borderWidth * 2),
      Radius.circular(innerRadius),
    );
    canvas.drawRRect(outerRrect, Paint()..color = Colors.white);
    canvas.drawRRect(innerRrect, Paint()..color = backgroundColor);

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final cx = size / 2;
    final cy = size / 2;

    if (isPlayIcon) {
      const halfH = 20.0;
      const rightExtent = 18.0;
      final path = Path()
        ..moveTo(cx - rightExtent, cy - halfH)
        ..lineTo(cx - rightExtent, cy + halfH)
        ..lineTo(cx + rightExtent, cy)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else {
      const iconSize = 35.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              cx - iconSize / 2, cy - iconSize / 2, iconSize, iconSize),
          const Radius.circular(0),
        ),
        iconPaint,
      );
    }

    final picture = recorder.endRecording();
    final w = (size * pixelRatio).round();
    final h = (size * pixelRatio).round();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// インフォメーションアイコン
  Future<BitmapDescriptor> _createPoiInfoMarkerIcon() async {
    const size = 102.0;
    const radius = 40.0;
    const pixelRatio = 2.0;
    final cx = size / 2;
    final cy = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

    final circlePaint = Paint()
      ..color = Colors.orangeAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    const text = 'i';
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.w600,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final w = (size * pixelRatio).round();
    final h = (size * pixelRatio).round();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// チェックポイントアイコン
  Future<BitmapDescriptor> _createPoiCheckpointMarkerIcon() async {
    const size = 102.0;
    const radius = 40.0;
    const pixelRatio = 2.0;
    final cx = size / 2;
    final cy = size / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

    final circlePaint = Paint()
      ..color = Colors.lightBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

    final checkPath = Path()
      ..moveTo(cx - 13, cy)
      ..lineTo(cx - 2, cy + 11)
      ..lineTo(cx + 15, cy - 13);
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(checkPath, checkPaint);

    final picture = recorder.endRecording();
    final w = (size * pixelRatio).round();
    final h = (size * pixelRatio).round();
    final image = await picture.toImage(w, h);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  /// スタート・ゴール・POIのマーカーを更新
  Future<void> _updateStartGoalMarkers(List<LatLng> points) async {
    final markers = <Marker>{};
    BitmapDescriptor? startIcon;
    BitmapDescriptor? goalIcon;
    BitmapDescriptor? poiIconOrange;
    BitmapDescriptor? poiIconCheckpoint;
    try {
      if (points.isNotEmpty) {
        startIcon = await _createRoundedSquareMarkerIcon(
          backgroundColor: Colors.green,
          isPlayIcon: true,
        );
        goalIcon = await _createRoundedSquareMarkerIcon(
          backgroundColor: Colors.red,
          isPlayIcon: false,
        );
      }
      if (_gpxPois.isNotEmpty) {
        poiIconOrange = await _createPoiInfoMarkerIcon();
        poiIconCheckpoint = await _createPoiCheckpointMarkerIcon();
      }
    } catch (e) {
      return;
    }
    if (!mounted) return;
    if (points.isNotEmpty && startIcon != null && goalIcon != null) {
      final start = points.first;
      final goal = points.length > 1 ? points.last : start;
      final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
          (start.longitude - goal.longitude).abs() < 1e-6;
      final startAnchor =
          isSamePoint ? const Offset(0, 0) : const Offset(0.5, 0.5);
      markers.add(Marker(
        markerId: const MarkerId('start'),
        position: start,
        icon: startIcon,
        anchor: startAnchor,
        zIndex: 2,
      ));
      markers.add(Marker(
        markerId: const MarkerId('goal'),
        position: goal,
        icon: goalIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 1,
      ));
    }
    if (_gpxPois.isNotEmpty &&
        poiIconOrange != null &&
        poiIconCheckpoint != null) {
      for (var i = 0; i < _gpxPois.length; i++) {
        final poi = _gpxPois[i];
        final icon = poi.isControl ? poiIconCheckpoint : poiIconOrange;
        markers.add(Marker(
          markerId: MarkerId('poi_$i'),
          position: poi.position,
          icon: icon,
          anchor: const Offset(0.25, 0.25),
          zIndex: 0,
          onTap: () => _showPoiDetailSheet(poi),
        ));
      }
    }
    if (!mounted) return;
    setState(() {
      _routeMarkers = markers;
    });
  }

  void _showPoiDetailSheet(GpxPoi poi) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (poi.name != null && poi.name!.isNotEmpty) ...[
                    Text(
                      poi.name!,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (poi.description != null && poi.description!.isNotEmpty)
                    Text(poi.description!),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  LatLngBounds? _boundsFromPoints(List<LatLng> points) {
    if (points.isEmpty) return null;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  LatLngBounds? _boundsFromPointsWithPois(
      List<LatLng> points, List<LatLng> poiPoints) {
    final all = [...points, ...poiPoints];
    return _boundsFromPoints(all);
  }

  /// ルート全体表示
  Future<void> _animateToRouteBounds() async {
    final points = _fullRoutePoints ?? _savedRoutePoints;
    if (points == null || points.isEmpty || mapController == null) return;
    final bounds = _boundsFromPoints(points);
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('位置情報を取得できません'),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => Geolocator.openAppSettings(),
                      icon: const Icon(Icons.settings),
                      label: const Text('設定を開く'),
                    ),
                  ],
                ),
              ),
            );
          }

          final position = snapshot.data!;

          // 地図表示後にバックグラウンドでルート取得を開始
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchOrLoadRouteIfNeeded(position);
          });

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            position.latitude,
                            position.longitude,
                          ),
                          zoom: _savedZoomLevel ?? _defaultZoom,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        polylines: _routePolylines,
                        markers: _routeMarkers,
                        onCameraIdle: _onCameraIdle,
                        onMapCreated: (controller) async {
                          mapController = controller;
                          await controller
                              .setMapStyle(_mapStyleForMode(_mapStyleMode));
                          if (_savedRoutePoints != null &&
                              _savedRoutePoints!.isNotEmpty) {
                            final bounds =
                                _boundsFromPoints(_savedRoutePoints!);
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
                      ),
                      Positioned(
                        left: 16,
                        bottom: 24,
                        child: Tooltip(
                          message: _mapStyleMode == 0
                              ? '地図をモノクロ表示'
                              : _mapStyleMode == 1
                                  ? '地図を反転表示（ダーク）'
                                  : '地図を通常表示',
                          child: Material(
                            color: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.black26,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () async {
                                setState(() =>
                                    _mapStyleMode = (_mapStyleMode + 1) % 3);
                                await mapController?.setMapStyle(
                                    _mapStyleForMode(_mapStyleMode));
                                await saveMapStyleMode(_mapStyleMode);
                              },
                              customBorder: const CircleBorder(),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Icon(
                                  _mapStyleMode == 0
                                      ? Icons.filter_b_and_w
                                      : _mapStyleMode == 1
                                          ? Icons.dark_mode
                                          : Icons.color_lens,
                                  color: Colors.black87,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 16,
                        top: 24,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Tooltip(
                              message: 'ルート全体を表示',
                              child: Material(
                                color: Colors.white,
                                elevation: 5,
                                shadowColor: Colors.black26,
                                shape: const CircleBorder(),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: _animateToRouteBounds,
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: Icon(
                                      Icons.zoom_out_map,
                                      color: Colors.black87,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_positionStreamSubscription == null) ...[
                              const SizedBox(height: 12),
                              Tooltip(
                                message: '現在地を表示',
                                child: Material(
                                  color: Colors.white,
                                  elevation: 5,
                                  shadowColor: Colors.black26,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: _moveCameraToCurrentPosition,
                                    customBorder: const CircleBorder(),
                                    child: const SizedBox(
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.my_location,
                                        color: Colors.black87,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_brightnessSupported)
                        Positioned(
                          right: 16,
                          bottom: 24,
                          child: Material(
                            color: Colors.white,
                            elevation: 5,
                            shadowColor: Colors.black26,
                            borderRadius: BorderRadius.circular(24),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: SizedBox(
                                height: 120,
                                child: RotatedBox(
                                  quarterTurns: 3,
                                  child: Slider(
                                    value: _brightnessSliderValue,
                                    onChanged: (value) async {
                                      setState(
                                          () => _brightnessSliderValue = value);
                                      final brightness =
                                          _sliderValueToBrightness(value);
                                      try {
                                        await ScreenBrightness()
                                            .setApplicationScreenBrightness(
                                                brightness);
                                      } catch (_) {}
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: _positionStreamSubscription == null
                          ? Colors.green // スタートマーカーと同じ
                          : Colors.red, // ゴールマーカーと同じ
                      child: InkWell(
                        onTap: _toggleLocationStream,
                        child: SizedBox(
                          width: double.infinity,
                          height: 80,
                          child: Center(
                            child: Icon(
                              _positionStreamSubscription == null
                                  ? Icons.play_arrow
                                  : Icons.stop,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_positionStreamSubscription != null &&
                        _progressBarValue != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 3,
                        child: Container(
                          width: double.infinity,
                          color: Colors.red.shade900,
                          child: ClipRect(
                            child: ValueListenableBuilder<double>(
                              valueListenable: _progressBarValue!,
                              builder: (context, value, child) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    const barWidth = 80.0;
                                    final left = (value *
                                            (constraints.maxWidth + barWidth)) -
                                        barWidth;
                                    return Stack(
                                      children: [
                                        Positioned(
                                          left: left,
                                          top: 0,
                                          child: Container(
                                            width: barWidth,
                                            height: 3,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

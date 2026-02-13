import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter_android_volume_keydown/flutter_android_volume_keydown.dart';

import 'api_config.dart';
import 'directions_repository.dart';
import 'first_launch_repository.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  GoogleMapController? mapController;
  Future<Position?>? _positionFuture;
  Set<Polyline> _routePolylines = {};
  Set<Marker> _routeMarkers = {};
  bool _hasStartedInitialRouteFetch = false;
  List<LatLng>? _savedRoutePoints;
  Timer? _routeAnimationTimer;
  List<LatLng>? _fullRoutePoints;
  int _animatedRoutePointCount = 0;

  /// 「設定を開く」で設定アプリへ送った場合に true。フォア復帰時に位置情報を再取得するため
  bool _expectingReturnFromSettings = false;

  /// ボリュームボタンでズームするためのリスナー（iOSは volume_controller、Androidは keydown でインターセプト）
  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<HardwareButton>? _volumeKeySubscription;
  double? _previousVolume;

  /// ボリュームキー1回あたりのズーム量
  static const _volumeZoomAmountUp = 1.8;
  static const _volumeZoomAmountDown = 1.8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // アプリ起動時の地図表示・ルート表示: 位置取得と保存済みルートの事前読み込み
    _positionFuture = _getPositionWithPermission();
    _preloadSavedRoute();
    _setupVolumeZoomListener();
  }

  /// ボリューム上でズームイン、下でズームアウト
  void _setupVolumeZoomListener() {
    if (Platform.isAndroid) {
      _volumeKeySubscription =
          FlutterAndroidVolumeKeydown.stream.listen((event) {
        if (mapController == null) return;
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
      if (volume > _previousVolume! && mapController != null) {
        mapController!.animateCamera(CameraUpdate.zoomBy(_volumeZoomAmountUp));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      if (volume < _previousVolume! && mapController != null) {
        mapController!
            .animateCamera(CameraUpdate.zoomBy(-_volumeZoomAmountDown));
        VolumeController.instance.setVolume(_previousVolume!);
        return;
      }
      _previousVolume = volume;
    }, fetchInitialVolume: true);
  }

  /// 保存済みルートを事前に読み込む（地図の初期カメラ位置を設定するため）
  Future<void> _preloadSavedRoute() async {
    final isFirst = await isFirstLaunch();
    if (!isFirst) {
      final points = await _loadSavedRoute();
      if (points != null && points.isNotEmpty && mounted) {
        setState(() {
          _savedRoutePoints = points;
          // 事前読み込み時は表示せず、後でアニメーション表示する
        });
      }
    }
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    _volumeKeySubscription?.cancel();
    _routeAnimationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;

    // 設定アプリから戻ってきた場合のみ: 位置情報を再取得してウィジェットを再描画
    if (_expectingReturnFromSettings) {
      _expectingReturnFromSettings = false;
      if (!mounted) return;
      setState(() {
        _positionFuture = _getPositionWithPermission();
      });
      return;
    }

    // 通常のフォアグラウンド復帰: 現在地を取得してカメラのみ移動（地図は再描画しない）
    _moveCameraToCurrentPosition();
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
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      }
    }
  }

  /// ルートを徐々に描画するアニメーションを開始
  void _startRouteAnimation(List<LatLng> fullPoints) {
    _routeAnimationTimer?.cancel();
    _fullRoutePoints = fullPoints;
    _animatedRoutePointCount = 0;

    // 最初の数ポイントをすぐに表示（アニメーションの開始点）
    const initialPoints = 10;
    final startPoints = fullPoints.length > initialPoints
        ? fullPoints.sublist(0, initialPoints)
        : fullPoints;

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

    // スタート・ゴールのマーカーを表示
    _updateStartGoalMarkers(fullPoints);

    // 残りのポイントを段階的に追加
    if (fullPoints.length > initialPoints) {
      _routeAnimationTimer = Timer.periodic(
        const Duration(milliseconds: 20), // 20msごとに更新（約50fps）
        (timer) {
          if (!mounted || _fullRoutePoints == null) {
            timer.cancel();
            return;
          }

          // 一度に追加するポイント数（アニメーション速度の調整）
          const pointsPerFrame = 5;
          final nextCount = (_animatedRoutePointCount + pointsPerFrame)
              .clamp(0, _fullRoutePoints!.length);

          if (nextCount >= _fullRoutePoints!.length) {
            // アニメーション完了
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
            // 次のポイントを追加
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
  }

  /// 角丸の正方形マーカーを生成（右下が座標に来るよう anchor 1, 1 で配置する想定）
  Future<BitmapDescriptor> _createRoundedSquareMarkerIcon({
    required Color backgroundColor,
    required bool isPlayIcon,
  }) async {
    const size = 96.0;
    const radius = 14.0;
    const pixelRatio = 2.0;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size, size),
        const Radius.circular(radius),
      ),
      bgPaint,
    );

    final iconPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final cx = size / 2;
    final cy = size / 2;

    if (isPlayIcon) {
      const halfH = 18.0;
      const rightExtent = 16.0;
      final path = Path()
        ..moveTo(cx - rightExtent, cy - halfH)
        ..lineTo(cx - rightExtent, cy + halfH)
        ..lineTo(cx + rightExtent, cy)
        ..close();
      canvas.drawPath(path, iconPaint);
    } else {
      const iconSize = 32.0;
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

  /// スタート・ゴールのマーカーを更新
  /// 角丸正方形の中心がスタート・ゴール座標に来るよう anchor (0.5, 0.5) で配置
  Future<void> _updateStartGoalMarkers(List<LatLng> points) async {
    if (points.isEmpty) return;
    final start = points.first;
    final goal = points.length > 1 ? points.last : start;

    BitmapDescriptor? startIcon;
    BitmapDescriptor? goalIcon;
    try {
      startIcon = await _createRoundedSquareMarkerIcon(
        backgroundColor: Colors.green,
        isPlayIcon: true,
      );
      goalIcon = await _createRoundedSquareMarkerIcon(
        backgroundColor: Colors.red,
        isPlayIcon: false,
      );
    } catch (e) {
      return;
    }
    if (!mounted) return;

    // スタートとゴールが同じ座標のときはゴールを anchor (0,0) で表示（左上が座標に）
    final isSamePoint = (start.latitude - goal.latitude).abs() < 1e-6 &&
        (start.longitude - goal.longitude).abs() < 1e-6;
    final startAnchor =
        isSamePoint ? const Offset(0, 0) : const Offset(0.5, 0.5);

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('start'),
        position: start,
        icon: startIcon,
        anchor: startAnchor,
        zIndex: 1,
      ),
      Marker(
        markerId: const MarkerId('goal'),
        position: goal,
        icon: goalIcon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 0,
      ),
    };
    setState(() {
      _routeMarkers = markers;
    });
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

  /// ルート全体表示
  Future<void> _animateToRouteBounds() async {
    final points = _fullRoutePoints ?? _savedRoutePoints;
    if (points == null || points.isEmpty || mapController == null) return;
    final bounds = _boundsFromPoints(points);
    if (bounds == null) return;
    await mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
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
            return const Center(
              child: Text('位置情報を取得できません'),
            );
          }

          final position = snapshot.data!;

          // 地図表示後にバックグラウンドでルート取得を開始
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchOrLoadRouteIfNeeded(position);
          });

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    position.latitude,
                    position.longitude,
                  ),
                  zoom: 14.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                polylines: _routePolylines,
                markers: _routeMarkers,
                onMapCreated: (controller) async {
                  mapController = controller;
                  // 保存済みルートがある場合は、地図作成直後にルート全体が見えるようにカメラを移動
                  if (_savedRoutePoints != null &&
                      _savedRoutePoints!.isNotEmpty) {
                    final bounds = _boundsFromPoints(_savedRoutePoints!);
                    if (bounds != null) {
                      await controller.animateCamera(
                        CameraUpdate.newLatLngBounds(bounds, 80),
                      );
                      // カメラ移動後にアニメーション開始
                      if (mounted) {
                        _startRouteAnimation(_savedRoutePoints!);
                      }
                    }
                  }
                },
              ),
              // ルート全体表示ボタン（左下に配置、現在地ボタンと重ならない）
              Positioned(
                left: 16,
                bottom: 24,
                child: Tooltip(
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
              ),
            ],
          );
        },
      ),
    );
  }
}

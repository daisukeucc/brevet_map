import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'providers/providers.dart';
import 'repositories/first_launch_repository.dart';
import 'services/gpx_channel_service.dart';
import 'services/location_service.dart';
import 'services/volume_zoom_handler.dart';
import 'utils/map_utils.dart';
import 'widgets/location_error_view.dart';
import 'widgets/map_screen_content.dart';
import 'widgets/poi_detail_sheet.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  runApp(const ProviderScope(child: MyApp()));
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

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with WidgetsBindingObserver {
  Future<Position?>? _positionFuture;
  bool _expectingReturnFromSettings = false;
  double _lastBearing = 0.0;

  late final VolumeZoomHandler _volumeZoomHandler;

  static const double _trackingZoom = 15.0;
  static const double _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _volumeZoomHandler = VolumeZoomHandler(
      getController: () => ref.read(cameraControllerProvider),
    );
    _volumeZoomHandler.start();

    _positionFuture = getPositionWithPermission(
      context,
      onOpenSettings: () => _expectingReturnFromSettings = true,
    ).timeout(const Duration(seconds: 20), onTimeout: () => null);

    WakelockPlus.enable();

    ref.read(mapStateProvider.notifier).loadSavedRouteIfNeeded();

    GpxChannelService.setMethodCallHandler(_onGpxReceived);
    GpxChannelService.getInitialGpxContent().then((content) {
      if (content != null && content.isNotEmpty && mounted) {
        _onGpxReceived(content);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _volumeZoomHandler.dispose();
    ref.read(locationStreamProvider.notifier).stop();
    ref.read(mapStateProvider.notifier).cancelAnimation();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveMapStyleMode(ref.read(mapStateProvider).mapStyleMode);
      WakelockPlus.disable();
      ref.read(locationStreamProvider.notifier).stop();
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

    WakelockPlus.enable();

    if (_expectingReturnFromSettings) {
      _expectingReturnFromSettings = false;
      if (!mounted) return;
      setState(() {
        _positionFuture = getPositionWithPermission(
          context,
          onOpenSettings: () => _expectingReturnFromSettings = true,
        ).timeout(const Duration(seconds: 20), onTimeout: () => null);
      });
      return;
    }

    ref.read(locationStreamProvider.notifier).restoreFromSaved(
      onPosition: _onPositionUpdate,
    );
  }

  // --- コールバック ---

  /// GPX 受信ハンドラ（ネイティブ or 共有から）
  void _onGpxReceived(String content) {
    ref
        .read(mapStateProvider.notifier)
        .applyImportedGpx(
          content,
          animateCamera: (bounds) =>
              ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
        )
        .then((status) {
      if (!mounted) return;
      if (status == GpxApplyStatus.parseError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このファイルはGPX形式ではありません')),
        );
      } else if (status == GpxApplyStatus.empty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPXにルートまたはウェイポイントが含まれていません')),
        );
      }
    });
  }

  /// 位置更新時のカメラ移動処理（LocationTrackingService のコールバックに渡す）
  void _onPositionUpdate(Position position, Position? previous) {
    if (!mounted) return;
    if (previous != null) {
      final b = bearingFromPositions(previous, position);
      if (b != null) _lastBearing = b;
    }
    ref.read(cameraControllerProvider.notifier).animateTo(
      LatLng(position.latitude, position.longitude),
      zoom: ref.read(mapStateProvider).savedZoomLevel ?? _trackingZoom,
      bearing: _lastBearing,
    );
  }

  Future<void> _onCameraIdle() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null) return;
    await ref.read(mapStateProvider.notifier).onCameraIdle(controller);
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    ref.read(cameraControllerProvider.notifier).setController(controller);
    ref.read(mapStateProvider.notifier).setPoiTapHandler((poi) {
      showPoiDetailSheet(context,
          name: poi.name, description: poi.description);
    });
    await ref.read(mapStateProvider.notifier).onMapCreated(
      controller,
      animateCamera: (bounds) =>
          ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
    );
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
    if (!wasActive) {
      // 初回 ON 時にズームを 15 に設定
      ref.read(mapStateProvider.notifier).overrideSavedZoom(_trackingZoom);
    }
  }

  Future<void> _onGpsLevelTap() async {
    await ref.read(locationStreamProvider.notifier).switchGpsLevel(
      onPosition: _onPositionUpdate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);

    return Scaffold(
      body: FutureBuilder<Position?>(
        future: _positionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('位置情報の取得に失敗しました'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Scaffold(body: LocationErrorView());
          }

          final position = snapshot.data!;

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

          return MapScreenContent(
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
            onGpsLevelTap: _onGpsLevelTap,
          );
        },
      ),
    );
  }
}

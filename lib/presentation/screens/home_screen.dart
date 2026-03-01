import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/gpx_channel_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/volume_zoom_handler.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../widgets/location_error_view.dart';
import '../widgets/map_screen_content.dart';
import '../widgets/poi_detail_sheet.dart';

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
  Position? _currentPosition;

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

  void _onPositionUpdate(Position position, Position? previous) {
    if (!mounted) return;
    setState(() => _currentPosition = position);
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
    final zoom = ref.read(cameraControllerProvider).camera.zoom;
    await ref.read(mapStateProvider.notifier).onCameraIdle(zoom);
  }

  Future<void> _onMapReady() async {
    ref.read(mapStateProvider.notifier).setPoiTapHandler((poi) {
      showPoiDetailSheet(context, name: poi.name, description: poi.description);
    });
    await ref.read(mapStateProvider.notifier).onMapCreated(
      animateCamera: (bounds) =>
          ref.read(cameraControllerProvider.notifier).animateToBounds(bounds),
    );
  }

  Future<void> _onMapStyleTap() async {
    await ref.read(mapStateProvider.notifier).toggleMapStyle();
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
      ref.read(mapStateProvider.notifier).overrideSavedZoom(_trackingZoom);
    }
  }

  Future<void> _onGpsLevelTap() async {
    await ref.read(locationStreamProvider.notifier).switchGpsLevel(
      onPosition: _onPositionUpdate,
    );
  }

  Marker? get _locationMarker {
    final pos = _currentPosition;
    if (pos == null) return null;
    return Marker(
      point: LatLng(pos.latitude, pos.longitude),
      width: 16,
      height: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final mapController = ref.read(cameraControllerProvider);

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
            mapController: mapController,
            initialPosition: LatLng(position.latitude, position.longitude),
            initialZoom: mapState.savedZoomLevel ?? _defaultZoom,
            polylines: mapState.routePolylines,
            markers: mapState.routeMarkers,
            mapStyleMode: mapState.mapStyleMode,
            onCameraIdle: _onCameraIdle,
            onMapReady: _onMapReady,
            onMapStyleTap: _onMapStyleTap,
            onRouteBoundsTap: _onRouteBoundsTap,
            onMyLocationTap: _moveCameraToCurrentPosition,
            showMyLocationButton: !locationState.isActive,
            isStreamActive: locationState.isActive,
            onToggleLocationStream: _toggleLocationStream,
            locationMarker: _locationMarker,
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

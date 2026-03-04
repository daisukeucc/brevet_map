import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/user_poi.dart';
import '../../domain/services/gpx_channel_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/volume_zoom_handler.dart';
import '../../utils/map_utils.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/text_menu_dialog.dart';
import '../widgets/location_error_view.dart';
import '../widgets/map_screen_content.dart';
import '../widgets/poi_detail_sheet.dart';

const double _kmPerMile = 1.609344;

String _formatDistance(double km, int unit) {
  if (unit == 1) {
    final mi = km / _kmPerMile;
    return '${mi % 1 == 0 ? mi.toInt() : mi.toStringAsFixed(1)}mi';
  }
  return '${km % 1 == 0 ? km.toInt() : km}km';
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
  bool _isDragMode = false;
  bool _isMapTapAddMode = false;

  Timer? _sleepTimer;
  bool _isScreenDimmed = false;
  bool _wasStreamActiveBeforeDim = false;
  OverlayEntry? _dimOverlayEntry;

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

    loadSleepDuration().then((minutes) {
      if (!mounted) return;
      ref.read(sleepDurationProvider.notifier).state = minutes;
      _restartSleepTimer(minutes);
    });

    loadDistanceUnit().then((unit) {
      if (!mounted) return;
      ref.read(distanceUnitProvider.notifier).state = unit;
    });

    ref.read(mapStateProvider.notifier).loadSavedRouteIfNeeded();

    GpxChannelService.setMethodCallHandler(_confirmAndApplyGpx);
    GpxChannelService.getInitialGpxContent().then((content) {
      if (content != null && content.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _confirmAndApplyGpx(content);
        });
      }
    });
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _restoreBrightness();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _volumeZoomHandler.dispose();
    ref.read(locationStreamProvider.notifier).stop();
    ref.read(mapStateProvider.notifier).cancelAnimation();
    super.dispose();
  }

  // --- スリープタイマー ---

  void _dimScreen() {
    if (!mounted) return;
    _wasStreamActiveBeforeDim = ref.read(locationStreamProvider).isActive;
    setState(() => _isScreenDimmed = true);
    ScreenBrightness().setApplicationScreenBrightness(0.0);
    if (_wasStreamActiveBeforeDim) {
      ref.read(locationStreamProvider.notifier).stop();
    }
    _dimOverlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: _onUserInteraction,
          behavior: HitTestBehavior.opaque,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );
    Overlay.of(context).insert(_dimOverlayEntry!);
  }

  void _restoreBrightness() {
    if (!_isScreenDimmed) return;
    _dimOverlayEntry?.remove();
    _dimOverlayEntry = null;
    setState(() => _isScreenDimmed = false);
    ScreenBrightness().resetApplicationScreenBrightness();
    if (_wasStreamActiveBeforeDim) {
      _wasStreamActiveBeforeDim = false;
      ref.read(locationStreamProvider.notifier).toggle(
            onPosition: _onPositionUpdate,
          );
    }
  }

  void _restartSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    if (minutes > 0) {
      _sleepTimer = Timer(Duration(minutes: minutes), _dimScreen);
    }
  }

  void _onUserInteraction() {
    _restoreBrightness();
    _restartSleepTimer(ref.read(sleepDurationProvider));
  }

  void _onSleepDurationChanged(int minutes) {
    ref.read(sleepDurationProvider.notifier).state = minutes;
    saveSleepDuration(minutes);
    _restoreBrightness();
    _restartSleepTimer(minutes);
    final l10n = AppLocalizations.of(context)!;
    final message =
        minutes == 0 ? l10n.sleepOffMessage : l10n.sleepSetMessage(minutes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      saveMapStyleMode(ref.read(mapStateProvider).mapStyleMode);
      WakelockPlus.disable();
      ref.read(locationStreamProvider.notifier).stop();
      _sleepTimer?.cancel();
      _restoreBrightness();
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

    WakelockPlus.enable();
    _restartSleepTimer(ref.read(sleepDurationProvider));

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
          animateCamera: (bounds) => ref
              .read(cameraControllerProvider.notifier)
              .animateToBounds(bounds),
        )
        .then((status) {
      if (!mounted) return;
      if (status == GpxApplyStatus.parseError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.gpxInvalidFormat),
          ),
        );
      } else if (status == GpxApplyStatus.empty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.gpxNoRouteOrWaypoint),
          ),
        );
      }
    });
  }

  Future<void> _confirmAndApplyGpx(String content) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.routeOverwrite,
      cancelText: l10n.ng,
      confirmText: l10n.ok,
    );
    if (confirmed != true) return;
    _onGpxReceived(content);
  }

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
      showPoiDetailSheet(context, name: poi.name, description: poi.description);
    });
    ref.read(mapStateProvider.notifier).setUserPoiTapHandler((poi) {
      final l10n = AppLocalizations.of(context)!;
      final unit = ref.read(distanceUnitProvider);
      final prefix = poi.km != null ? '${_formatDistance(poi.km!, unit)}：' : '';
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
      ref.read(mapStateProvider.notifier).overrideSavedZoom(_trackingZoom);
    }
  }

  Future<void> _onGpsLevelTap() async {
    await ref.read(locationStreamProvider.notifier).switchGpsLevel(
          onPosition: _onPositionUpdate,
        );
  }

  Future<void> _onGpxImportTap() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.routeOverwrite,
      cancelText: l10n.ng,
      confirmText: l10n.ok,
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.gpx')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectGpxFile),
          backgroundColor: Colors.black.withValues(alpha: 0.6),
        ),
      );
      return;
    }
    final content = await File(path).readAsString();
    if (!mounted) return;
    _onGpxReceived(content);
  }

  Future<void> _onAddPoiTap() async {
    if (!mounted) return;
    final result = await showDialog<Object>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const _PoiManagementDialog(),
    );
    if (result == null || !mounted) return;

    if (result is _MapTapAddRequest) {
      _startMapTapAddMode();
      return;
    }
    if (result is _DistanceInputRequest) {
      await _showDistanceInputDialog();
      return;
    }
    if (result is _PoiEditTextRequest) {
      await _onEditPoiText(result.poi);
      return;
    }
    if (result is _PoiEditPositionRequest) {
      await _onEditPoiPosition(result.poi);
      return;
    }
  }

  Future<void> _onEditPoiText(UserPoi poi) async {
    if (!mounted) return;
    final distanceUnit = ref.read(distanceUnitProvider);
    final data = await showDialog<_AddPoiFormData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) =>
          _EditPoiTextDialog(poi: poi, distanceUnit: distanceUnit),
    );
    if (data == null || !mounted) return;

    LatLng? coord;
    final kmChanged = data.km != poi.km;
    if (kmChanged && data.km != null) {
      final routePoints = ref.read(mapStateProvider).savedRoutePoints;
      if (routePoints != null && routePoints.isNotEmpty) {
        coord = coordAtKm(routePoints, data.km!);
      }
    }

    final updatedPoi = UserPoi(
      type: data.type,
      km: data.km,
      title: data.title,
      body: data.body,
      lat: coord?.latitude ?? poi.lat,
      lng: coord?.longitude ?? poi.lng,
    );
    await ref.read(mapStateProvider.notifier).updateUserPoi(poi, updatedPoi);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.poiUpdated)),
    );
  }

  Future<void> _onEditPoiPosition(UserPoi poi) async {
    if (!mounted) return;
    setState(() => _isDragMode = true);
    await ref.read(cameraControllerProvider.notifier).animateTo(
          poi.position,
          zoom: 16.0,
        );
    if (!mounted) return;
    await ref.read(mapStateProvider.notifier).startPoiDrag(poi, (newLatLng) {
      _onPoiDragEnd(poi, newLatLng);
    });
  }

  Future<void> _onCancelDragMode() async {
    await ref.read(mapStateProvider.notifier).stopPoiDrag();
    if (!mounted) return;
    setState(() => _isDragMode = false);
  }

  void _startMapTapAddMode() {
    setState(() => _isMapTapAddMode = true);
  }

  Future<void> _showDistanceInputDialog() async {
    if (!mounted) return;
    final distanceUnit = ref.read(distanceUnitProvider);
    final data = await showDialog<_AddPoiFormData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _DistanceInputPoiDialog(distanceUnit: distanceUnit),
    );
    if (data == null || !mounted) return;
    if (data.km == null) return;
    final routePoints = ref.read(mapStateProvider).savedRoutePoints;
    if (routePoints == null || routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.routeNotLoaded)),
      );
      return;
    }
    final coord = coordAtKm(routePoints, data.km!);
    if (coord == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.kmPointNotFound)),
      );
      return;
    }
    final poi = UserPoi(
      type: data.type,
      km: data.km,
      title: data.title,
      body: data.body,
      lat: coord.latitude,
      lng: coord.longitude,
    );
    await ref.read(mapStateProvider.notifier).addUserPoi(poi);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.poiRegistered)),
    );
  }

  Future<void> _onCancelMapTapAddMode() async {
    if (!mounted) return;
    setState(() => _isMapTapAddMode = false);
  }

  Future<void> _onMapLongPress(LatLng position) async {
    if (!_isMapTapAddMode || !mounted) return;
    final data = await showDialog<_AddPoiFormData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => const _MapTapPoiAddDialog(),
    );
    if (!mounted) return;
    setState(() => _isMapTapAddMode = false);
    if (data == null) return;
    final poi = UserPoi(
      type: data.type,
      km: null,
      title: data.title,
      body: data.body,
      lat: position.latitude,
      lng: position.longitude,
    );
    await ref.read(mapStateProvider.notifier).addUserPoi(poi);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.poiRegistered)),
    );
  }

  Future<void> _onPoiDragEnd(UserPoi poi, LatLng newLatLng) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.changePoiPosition,
      cancelText: l10n.cancel,
      confirmText: l10n.change,
    );

    await ref.read(mapStateProvider.notifier).stopPoiDrag();
    if (!mounted) return;
    setState(() => _isDragMode = false);
    if (confirmed != true) return;

    final updatedPoi = UserPoi(
      type: poi.type,
      km: poi.km,
      title: poi.title,
      body: poi.body,
      lat: newLatLng.latitude,
      lng: newLatLng.longitude,
    );
    await ref.read(mapStateProvider.notifier).updateUserPoi(poi, updatedPoi);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.poiPositionChanged)),
    );
  }

  void _onDistanceUnitChanged(int unit) async {
    ref.read(distanceUnitProvider.notifier).state = unit;
    saveDistanceUnit(unit);
    await ref.read(mapStateProvider.notifier).refreshMarkersForUnitChange();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final message =
        unit == 0 ? l10n.distanceUnitSetToKm : l10n.distanceUnitSetToMile;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final sleepDuration = ref.watch(sleepDurationProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);

    return Stack(
      children: [
        Scaffold(
          body: FutureBuilder<Position?>(
            future: _positionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.locationFailed));
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
                sleepDuration: sleepDuration,
                onSleepDurationChanged: _onSleepDurationChanged,
                distanceUnit: distanceUnit,
                onDistanceUnitChanged: _onDistanceUnitChanged,
                onGpxImportTap: _onGpxImportTap,
                onAddPoiTap: _onAddPoiTap,
                hasUserPois: mapState.userPois.isNotEmpty,
                onUserInteraction: _onUserInteraction,
                isDragMode: _isDragMode,
                isMapTapAddMode: _isMapTapAddMode,
                onMapLongPress: _isMapTapAddMode ? _onMapLongPress : null,
              );
            },
          ),
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
                child: SizedBox(
                  height: 80,
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
                          ),
                        ),
                        TextButton(
                          onPressed: _onCancelDragMode,
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
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
        if (_isMapTapAddMode) ...[
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
                child: SizedBox(
                  height: 80,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.longPressPoiHint,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white60,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _onCancelMapTapAddMode,
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: TextStyle(
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

// ---------------------------------------------------------------------------
// POI管理ダイアログ
// ---------------------------------------------------------------------------

class _MapTapAddRequest {
  const _MapTapAddRequest();
}

class _DistanceInputRequest {
  const _DistanceInputRequest();
}

// ---------------------------------------------------------------------------
// 距離入力でPOI登録ダイアログ
// ---------------------------------------------------------------------------

class _DistanceInputPoiDialog extends StatefulWidget {
  const _DistanceInputPoiDialog({required this.distanceUnit});
  final int distanceUnit;

  @override
  State<_DistanceInputPoiDialog> createState() =>
      _DistanceInputPoiDialogState();
}

class _DistanceInputPoiDialogState extends State<_DistanceInputPoiDialog> {
  int _poiType = 0;
  final _kmController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _kmError;
  late final FocusNode _kmFocusNode;

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

  void _onSubmit() {
    final value = double.tryParse(_kmController.text.trim());
    if (value == null || value < 0) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmRequired);
      return;
    }
    // 入力値を内部保存用の km に変換（mile の場合は miles → km）
    final km = widget.distanceUnit == 1 ? value * _kmPerMile : value;
    setState(() => _kmError = null);
    Navigator.pop(
      context,
      _AddPoiFormData(
        km: km,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
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
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.register,
                        style: AppTextStyles.button),
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

class _AddPoiFormData {
  const _AddPoiFormData({
    this.km,
    required this.type,
    required this.title,
    required this.body,
  });
  final double? km;
  final int type;
  final String title;
  final String body;
}

class _PoiEditTextRequest {
  const _PoiEditTextRequest(this.poi);
  final UserPoi poi;
}

class _PoiEditPositionRequest {
  const _PoiEditPositionRequest(this.poi);
  final UserPoi poi;
}

class _PoiManagementDialog extends ConsumerStatefulWidget {
  const _PoiManagementDialog();

  @override
  ConsumerState<_PoiManagementDialog> createState() =>
      _PoiManagementDialogState();
}

class _PoiManagementDialogState extends ConsumerState<_PoiManagementDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            onTap: () => Navigator.pop(context, const _DistanceInputRequest()),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.poiAddByMapTap,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(context, const _MapTapAddRequest()),
          ),
        ],
      ),
    );
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
      Navigator.pop(context, _PoiEditTextRequest(poi));
    } else {
      Navigator.pop(context, _PoiEditPositionRequest(poi));
    }
  }

  Future<void> _onDeleteTap(UserPoi poi) async {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.poiDeleted)),
    );

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
    final sorted = [...userPois]..sort(
        (a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final poi = sorted[i];
        final distStr =
            poi.km != null ? _formatDistance(poi.km!, distanceUnit) : null;
        return DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _onEditTap(poi),
                  child: Text(AppLocalizations.of(context)!.edit,
                      style: AppTextStyles.buttonSmall),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _onDeleteTap(poi),
                  child: Text(AppLocalizations.of(context)!.delete,
                      style: AppTextStyles.buttonSmall),
                ),
              ],
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
      shape: const RoundedRectangleBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
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

class _MapTapPoiAddDialog extends StatefulWidget {
  const _MapTapPoiAddDialog();

  @override
  State<_MapTapPoiAddDialog> createState() => _MapTapPoiAddDialogState();
}

class _MapTapPoiAddDialogState extends State<_MapTapPoiAddDialog> {
  int _poiType = 0;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    Navigator.pop(
      context,
      _AddPoiFormData(
        km: null,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.register,
                        style: AppTextStyles.button),
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

class _EditPoiTextDialog extends StatefulWidget {
  const _EditPoiTextDialog({required this.poi, required this.distanceUnit});

  final UserPoi poi;
  final int distanceUnit;

  @override
  State<_EditPoiTextDialog> createState() => _EditPoiTextDialogState();
}

class _EditPoiTextDialogState extends State<_EditPoiTextDialog> {
  late int _poiType;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _poiType = widget.poi.type;
    _titleController = TextEditingController(text: widget.poi.title);
    _bodyController = TextEditingController(text: widget.poi.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    Navigator.pop(
      context,
      _AddPoiFormData(
        km: widget.poi.km,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnRoute = widget.poi.km != null;
    final kmLabel = isOnRoute
        ? _formatDistance(widget.poi.km!, widget.distanceUnit)
        : l10n.offRoute;
    final titleText =
        isOnRoute ? l10n.poiAtKmPoint(kmLabel) : l10n.poiOffRoutePoi;
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    titleText,
                    style: AppTextStyles.headline,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.change,
                        style: AppTextStyles.button),
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

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
  bool _isDragMode = false;

  Timer? _sleepTimer;
  bool _isScreenDimmed = false;
  bool _wasStreamActiveBeforeDim = false;

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
    _wasStreamActiveBeforeDim = ref.read(locationStreamProvider).isActive;
    setState(() => _isScreenDimmed = true);
    ScreenBrightness().setApplicationScreenBrightness(0.0);
    if (_wasStreamActiveBeforeDim) {
      ref.read(locationStreamProvider.notifier).stop();
    }
  }

  void _restoreBrightness() {
    if (!_isScreenDimmed) return;
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
    final message =
        minutes == 0 ? '画面スリープをOFFにしました' : '画面スリープを$minutes分に設定しました';
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
          const SnackBar(content: Text('このファイルはGPX形式ではありません')),
        );
      } else if (status == GpxApplyStatus.empty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPXにルートまたはウェイポイントが含まれていません')),
        );
      }
    });
  }

  Future<void> _confirmAndApplyGpx(String content) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: const Text(
          '現在のルートを上書きします',
          style: TextStyle(fontSize: 17),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NG', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
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
      final kmStr =
          poi.km % 1 == 0 ? '${poi.km.toInt()}' : '${poi.km}';
      final title = poi.title.isEmpty ? '(タイトルなし)' : poi.title;
      showPoiDetailSheet(
        context,
        name: '${kmStr}km：$title',
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: const Text(
          '現在のルートを上書きします',
          style: TextStyle(fontSize: 17),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NG', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result == null || result.files.single.path == null) return;
    final path = result.files.single.path!;
    if (!path.toLowerCase().endsWith('.gpx')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('GPXファイルを選択してください'),
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
      builder: (context) => const _AddPoiDialog(),
    );
    if (result == null || !mounted) return;

    if (result is _PoiEditTextRequest) {
      await _onEditPoiText(result.poi);
      return;
    }
    if (result is _PoiEditPositionRequest) {
      await _onEditPoiPosition(result.poi);
      return;
    }
    if (result is! _AddPoiFormData) return;

    final data = result;
    final routePoints = ref.read(mapStateProvider).savedRoutePoints;
    if (routePoints == null || routePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルートが読み込まれていません')),
      );
      return;
    }

    final coord = coordAtKm(routePoints, data.km);
    if (coord == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('指定したkm地点が見つかりません')),
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
      const SnackBar(content: Text('POIを追加しました')),
    );
  }

  Future<void> _onEditPoiText(UserPoi poi) async {
    if (!mounted) return;
    final data = await showDialog<_AddPoiFormData>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _EditPoiTextDialog(poi: poi),
    );
    if (data == null || !mounted) return;

    LatLng? coord;
    if (data.km != poi.km) {
      final routePoints = ref.read(mapStateProvider).savedRoutePoints;
      if (routePoints != null && routePoints.isNotEmpty) {
        coord = coordAtKm(routePoints, data.km);
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
      const SnackBar(content: Text('POIを変更しました')),
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

  Future<void> _onPoiDragEnd(UserPoi poi, LatLng newLatLng) async {
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: const Text('この位置に変更する', style: TextStyle(fontSize: 17)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('変更', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
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
      const SnackBar(content: Text('マーカーの位置を変更しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final sleepDuration = ref.watch(sleepDurationProvider);

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
                sleepDuration: sleepDuration,
                onSleepDurationChanged: _onSleepDurationChanged,
                onGpxImportTap: _onGpxImportTap,
                onAddPoiTap: _onAddPoiTap,
                onUserInteraction: _onUserInteraction,
                isDragMode: _isDragMode,
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
                        const Expanded(
                          child: Text(
                            'マーカーをドラッグして位置を変更して下さい',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.white60,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _onCancelDragMode,
                          child: const Text(
                            'キャンセル',
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
        if (_isScreenDimmed)
          Positioned.fill(
            child: GestureDetector(
              onTap: _onUserInteraction,
              child: const ColoredBox(color: Colors.black),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// POI追加ダイアログ
// ---------------------------------------------------------------------------

class _AddPoiFormData {
  const _AddPoiFormData({
    required this.km,
    required this.type,
    required this.title,
    required this.body,
  });
  final double km;
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

class _AddPoiDialog extends ConsumerStatefulWidget {
  const _AddPoiDialog();

  @override
  ConsumerState<_AddPoiDialog> createState() => _AddPoiDialogState();
}

class _AddPoiDialogState extends ConsumerState<_AddPoiDialog>
    with SingleTickerProviderStateMixin {
  int _poiType = 0;
  final _kmController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _kmError;
  TabController? _tabController;

  bool get _hasPois => ref.watch(mapStateProvider).userPois.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (ref.read(mapStateProvider).userPois.isNotEmpty) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasPois && _tabController == null && mounted) {
      _tabController = TabController(length: 2, vsync: this);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final km = double.tryParse(_kmController.text.trim());
    if (km == null || km < 0) {
      setState(() => _kmError = '有効なkm値を入力してください');
      return;
    }
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

  List<Widget> _buildFormFields() {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            child: TextField(
              controller: _kmController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                errorText: _kmError,
                errorMaxLines: 2,
              ),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 17),
            ),
          ),
          const SizedBox(width: 8),
          const Text('km地点にPOIを追加', style: TextStyle(fontSize: 17)),
        ],
      ),
      const SizedBox(height: 28),
      const Text('POIタイプ', style: TextStyle(fontSize: 15)),
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
            const Text('チェックポイント', style: TextStyle(fontSize: 17)),
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
            const Text('インフォメーション', style: TextStyle(fontSize: 17)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      TextField(
        controller: _titleController,
        decoration: const InputDecoration(
          labelText: 'タイトル',
          isDense: true,
        ),
        style: const TextStyle(fontSize: 17),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _bodyController,
        decoration: const InputDecoration(
          labelText: '本文',
          isDense: true,
        ),
        style: const TextStyle(fontSize: 17),
        maxLines: 3,
        minLines: 3,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: _onSubmit,
            child: const Text('追加', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    ];
  }

  Widget _buildAddTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildFormFields(),
        ),
      ),
    );
  }

  Future<void> _onEditTap(UserPoi poi) async {
    final action = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('テキストを変更'),
              onTap: () => Navigator.pop(context, 0),
            ),
            ListTile(
              title: const Text('マーカーの位置を変更'),
              onTap: () => Navigator.pop(context, 1),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    if (action == 0) {
      Navigator.pop(context, _PoiEditTextRequest(poi));
    } else {
      Navigator.pop(context, _PoiEditPositionRequest(poi));
    }
  }

  Future<void> _onDeleteTap(UserPoi poi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: const Text(
          'このPOIを削除しますか？',
          style: TextStyle(fontSize: 17),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(fontSize: 17)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await ref.read(mapStateProvider.notifier).deleteUserPoi(poi);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('POIを削除しました')),
    );

    if (ref.read(mapStateProvider).userPois.isEmpty) {
      Navigator.pop(context);
    }
  }

  Widget _buildEditTab() {
    final userPois = ref.watch(mapStateProvider).userPois;
    final sorted = [...userPois]..sort((a, b) => a.km.compareTo(b.km));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final poi = sorted[i];
        final kmStr = poi.km % 1 == 0 ? '${poi.km.toInt()}' : '${poi.km}';
        return DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: ListTile(
            title: Text(
              '$kmStr km：${poi.title.isEmpty ? '(タイトルなし)' : poi.title}',
              style: const TextStyle(fontSize: 15),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => _onEditTap(poi),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('編集'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _onDeleteTap(poi),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('削除'),
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
    if (!_hasPois || _tabController == null) {
      return Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'POIを追加',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ..._buildFormFields(),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'POIを追加'),
                Tab(text: 'POIを編集・削除'),
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
// POIテキスト編集ダイアログ
// ---------------------------------------------------------------------------

class _EditPoiTextDialog extends StatefulWidget {
  const _EditPoiTextDialog({required this.poi});

  final UserPoi poi;

  @override
  State<_EditPoiTextDialog> createState() => _EditPoiTextDialogState();
}

class _EditPoiTextDialogState extends State<_EditPoiTextDialog> {
  late int _poiType;
  late final TextEditingController _kmController;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  String? _kmError;

  @override
  void initState() {
    super.initState();
    _poiType = widget.poi.type;
    final km = widget.poi.km;
    final kmStr = km % 1 == 0 ? '${km.toInt()}' : '$km';
    _kmController = TextEditingController(text: kmStr);
    _titleController = TextEditingController(text: widget.poi.title);
    _bodyController = TextEditingController(text: widget.poi.body);
  }

  @override
  void dispose() {
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final km = double.tryParse(_kmController.text.trim());
    if (km == null || km < 0) {
      setState(() => _kmError = '有効なkm値を入力してください');
      return;
    }
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
              const Text(
                'テキストを変更',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _kmController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        errorText: _kmError,
                        errorMaxLines: 2,
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('km地点', style: TextStyle(fontSize: 17)),
                ],
              ),
              const SizedBox(height: 28),
              const Text('POIタイプ', style: TextStyle(fontSize: 15)),
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
                    const Text('チェックポイント', style: TextStyle(fontSize: 17)),
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
                    const Text('インフォメーション', style: TextStyle(fontSize: 17)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: '本文',
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 17),
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル', style: TextStyle(fontSize: 17)),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: const Text('変更', style: TextStyle(fontSize: 17)),
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

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
import '../handlers/app_settings_handler.dart';
import '../handlers/contact_handler.dart';
import '../handlers/language_handler.dart';
import '../handlers/location_sharing_handler.dart';
import '../handlers/settings_menu_handler.dart';
import '../handlers/share_handler.dart';
import '../handlers/battery_display_handler.dart';
import '../handlers/sleep_settings_handler.dart';
import '../handlers/share_url_handler.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/connectivity_gate.dart'
    show
        ConnectivityGate,
        ConnectivityGateState,
        ConnectivityCheckingView,
        OfflinePlaceholderView;
import '../widgets/map_screen_content.dart';
import 'map_markers.dart';
import '../widgets/poi_detail_sheet.dart';

part 'home_screen_share.dart';
part 'home_screen_location.dart';
part 'home_screen_build.dart';

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
    with WidgetsBindingObserver, _ShareUrlMixin, _LocationStreamMixin, _BuildMixin {
  @override
  bool _isDragMode = false;

  @override
  bool _isMapTapAddMode = false;

  late final VolumeZoomHandler _volumeZoomHandler;

  /// 初回インストールか（null=未取得、true=初回、false=2回目以降）
  bool? _isFirstLaunch;

  /// 初回起動時に ConnectivityGate がオフラインと判定したか
  @override
  bool _isConnectivityOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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

    loadScreenSleep().then((value) {
      if (!mounted) return;
      ref.read(screenSleepProvider.notifier).state = value;
      if (!value) WakelockPlus.enable();
    });

    loadBatteryDisplay().then((value) {
      if (!mounted) return;
      ref.read(batteryDisplayProvider.notifier).state = value;
    });

    loadDistanceUnit().then((unit) {
      if (!mounted) return;
      ref.read(distanceUnitProvider.notifier).state = unit;
    });

    loadLocale().then((code) {
      if (!mounted) return;
      if (code != null && code.isNotEmpty) {
        ref.read(localeProvider.notifier).state = Locale(code);
      }
    });

    ref.read(mapStateProvider.notifier).loadSavedRouteIfNeeded();

    isFirstLaunch()
        .timeout(const Duration(seconds: 3), onTimeout: () => false)
        .then((first) {
      if (mounted) setState(() => _isFirstLaunch = first);
    });

    _initShareFlow();

    GpxChannelService.setMethodCallHandler((content) {
      if (mounted) {
        showConfirmAndApplyGpx(
          context,
          ref,
          content,
          onSuccess: () => setState(() => _isRouteBoundsMode = true),
        );
      }
    });
    GpxChannelService.getInitialGpxContent().then((content) {
      if (content != null && content.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showConfirmAndApplyGpx(
            context,
            ref,
            content,
            onSuccess: () => setState(() => _isRouteBoundsMode = true),
          );
        });
      }
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      ref.read(locationStreamProvider.notifier).stop();
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

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
    }
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
            top: MediaQuery.of(context).padding.top,
            bottom: 80,
            left: 0,
            right: 0,
            child: const IgnorePointer(
              child: Center(
                child: Icon(
                  Icons.my_location,
                  size: 56,
                  color: Colors.white,
                ),
              ),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            final center = ref
                                .read(cameraControllerProvider)
                                ?.camera
                                .center;
                            if (center == null) return;
                            ref
                                .read(mapStateProvider.notifier)
                                .confirmPoiDrag(center);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.changePoiPosition,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              decoration: TextDecoration.none,
                            ),
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
          if (_isMapTapAddMode && _pendingSharedPosition == null)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              bottom: 80,
              left: 0,
              right: 0,
              child: const IgnorePointer(
                child: Center(
                  child: Icon(
                    Icons.my_location,
                    size: 56,
                    color: Colors.white,
                  ),
                ),
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 15,
                    ),
                    child: Row(
                      children: [
                        if (_pendingSharedPosition != null) ...[
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .registerThisPlaceAsPoi,
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
                        ] else ...[
                          const Spacer(),
                          TextButton(
                            onPressed: _onConfirmMapTapPosition,
                            child: Text(
                              AppLocalizations.of(context)!.registerAtPosition,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
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

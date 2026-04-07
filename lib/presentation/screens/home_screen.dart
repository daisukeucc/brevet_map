import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../config/default_map_install_coordinates.dart';
import '../../data/repositories/first_launch_repository.dart';
import '../../domain/services/default_map_position_resolver.dart';
import '../../domain/services/gpx_channel_service.dart';
import '../../domain/services/location_service.dart';
import '../../domain/services/marker_icon_service.dart';
import '../../domain/services/share_channel_service.dart';
import '../../domain/services/volume_zoom_handler.dart';
import '../../utils/date_formatting_localization.dart';
import '../../utils/map_utils.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../handlers/gpx_import_handler.dart';
import '../handlers/poi_management_handler.dart';
import '../handlers/app_settings_handler.dart';
import 'about_app_screen.dart';
import '../handlers/contact_handler.dart';
import '../handlers/language_handler.dart';
import '../handlers/location_sharing_handler.dart';
import '../handlers/settings_menu_handler.dart';
import '../handlers/share_handler.dart';
import '../handlers/battery_display_handler.dart';
import '../handlers/sleep_settings_handler.dart';
import '../handlers/share_url_handler.dart';
import '../handlers/subscription_handler.dart';
import '../theme/app_text_styles.dart';
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
part 'home_screen_poi.dart';
part 'home_screen_location.dart';
part 'home_screen_build.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage>
    with
        WidgetsBindingObserver,
        _ShareUrlMixin,
        _PoiModeMixin,
        _LocationStreamMixin,
        _BuildMixin {
  late final VolumeZoomHandler _volumeZoomHandler;

  /// 初回インストールか（null=確認中、true=初回、false=2回目以降）
  bool? _isFirstLaunch;

  @override
  Position _positionFromLatLng(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
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

  Position _positionFromInstallConstants() {
    final picked = ref.read(localeProvider);
    final c = picked != null
        ? defaultInstallCoordinatesForLocaleCode(localeToCode(picked))
        : defaultInstallCoordinatesForSystemLocale(
            ui.PlatformDispatcher.instance.locale,
          );
    return _positionFromLatLng(c.lat, c.lng);
  }

  /// GPS 未取得時のフォールバック。表示中ルートの先頭があればそれを優先し、なければプリファレンス解決済みキャッシュ。
  @override
  Position _fallbackPosition() {
    final pts = ref.read(mapStateProvider).savedRoutePoints;
    if (pts != null && pts.isNotEmpty) {
      final p = pts.first;
      return _positionFromLatLng(p.latitude, p.longitude);
    }
    return _cachedDefaultPosition ?? _positionFromInstallConstants();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _volumeZoomHandler = VolumeZoomHandler(
      getController: () => ref.read(cameraControllerProvider),
    );
    _volumeZoomHandler.start();

    _cachedDefaultPosition = _positionFromInstallConstants();
    // 初回フレーム後に位置取得と既定座標のプリファレンス解決
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ensureDateFormattingInitialized();
      _fetchPositionInBackground();
      resolveDefaultMapCoordinates().then((c) {
        if (!mounted) return;
        setState(() {
          _cachedDefaultPosition = _positionFromLatLng(c.lat, c.lng);
        });
      });
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
        ref.read(localeProvider.notifier).state = codeToLocale(code);
      }
    });

    ref.read(mapStateProvider.notifier).loadSavedRouteIfNeeded();

    // 初回インストール判定（例外・タイムアウト時は false にフォールバック）
    isFirstLaunch()
        .timeout(const Duration(seconds: 3), onTimeout: () => false)
        .then((first) {
      if (mounted) setState(() => _isFirstLaunch = first);
    }).catchError((_) {
      if (mounted) setState(() => _isFirstLaunch = false);
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
      // 共有シート表示中は Android でもアプリが paused/inactive に遷移するが、
      // 位置情報ストリームは停止しない（iOS との挙動を統一する）
      if (!_isShareMode) {
        ref.read(locationStreamProvider.notifier).stop();
      }
      if (state == AppLifecycleState.paused) return;
    }

    if (state != AppLifecycleState.resumed) return;

    // 共有シートから本アプリを選択してフォアグラウンドに戻った場合、
    // 共有モードをリセットして吹き出しが残らないようにする
    if (_isShareMode) {
      setState(() {
        _isShareMode = false;
        _shareHp = null;
        _isRouteBoundsMode = true;
      });
    }

    if (_expectingReturnFromSettings) {
      _expectingReturnFromSettings = false;
      if (!mounted) return;
      _fetchPositionInBackground();
    }

    unawaited(_resumeLocationStreamIfNeeded());
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _isFirstLaunch == null
              ? const ConnectivityCheckingView()
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
                      builder: (context, gateState, onRetry) {
                        if (gateState == ConnectivityGateState.checking) {
                          return const ConnectivityCheckingView();
                        }
                        if (gateState == ConnectivityGateState.offline) {
                          return OfflinePlaceholderView(onRetry: onRetry);
                        }
                        return _buildBody(context);
                      },
                    )
                  : _buildBody(context),
        ),
        ..._buildDragModeOverlays(context),
        ..._buildPoiAddModeOverlays(context),
      ],
    );
  }
}

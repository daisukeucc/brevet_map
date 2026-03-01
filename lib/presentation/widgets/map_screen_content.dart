import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/offline_map_notifier.dart';
import 'battery_indicator.dart';
import 'location_bottom_bar.dart';
import 'map_style_button.dart';
import 'map_tool_buttons.dart';
import 'offline_tile_provider.dart';

/// 地図画面の本体。地図・オーバーレイ・下部バーをまとめる。
class MapScreenContent extends StatelessWidget {
  const MapScreenContent({
    super.key,
    required this.mapController,
    required this.initialPosition,
    required this.initialZoom,
    required this.polylines,
    required this.markers,
    required this.mapStyleMode,
    required this.onCameraIdle,
    required this.onMapReady,
    required this.onMapStyleTap,
    required this.onRouteBoundsTap,
    required this.onMyLocationTap,
    required this.showMyLocationButton,
    required this.isStreamActive,
    required this.onToggleLocationStream,
    required this.onOfflineMapDownloadTap,
    required this.offlineMapState,
    required this.onUseOfflineMapTap,
    required this.onUseOnlineMapTap,
    this.locationMarker,
    this.progressBarValue,
    this.isLowMode = false,
    this.isStreamAccuracyLow = false,
    this.onGpsLevelTap,
    this.onUserInteraction,
  });

  final MapController mapController;
  final LatLng initialPosition;
  final double initialZoom;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final int mapStyleMode;
  final VoidCallback onCameraIdle;
  final VoidCallback onMapReady;
  final VoidCallback onMapStyleTap;
  final VoidCallback onRouteBoundsTap;
  final VoidCallback onMyLocationTap;
  final bool showMyLocationButton;
  final bool isStreamActive;
  final VoidCallback onToggleLocationStream;
  final VoidCallback onOfflineMapDownloadTap;
  final OfflineMapState offlineMapState;
  final VoidCallback onUseOfflineMapTap;
  final VoidCallback onUseOnlineMapTap;

  /// 現在地ドット（位置ストリーム中のみ表示）
  final Marker? locationMarker;

  final ValueNotifier<double>? progressBarValue;

  /// true のとき位置情報ストリームボタンをグレー表示する（LOWモード時）
  final bool isLowMode;

  /// 位置ストリームの精度が low のとき true（GPSボタンのラベルを「LOW」にする）
  final bool isStreamAccuracyLow;

  final VoidCallback? onGpsLevelTap;

  /// 画面タッチ時（5分無操作LOWモード解除用）
  final VoidCallback? onUserInteraction;

  String get _tileUrl =>
      'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png';

  String get _attribution => '© Carto, © OpenStreetMap contributors';

  TileProvider get _tileProvider =>
      offlineMapState.isUsing && offlineMapState.offlineDirPath != null
          ? OfflineTileProvider(offlineMapState.offlineDirPath!)
          : NetworkTileProvider();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerDown: (_) => onUserInteraction?.call(),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: mapController,
                    options: MapOptions(
                      initialCenter: initialPosition,
                      initialZoom: initialZoom,
                      onMapReady: onMapReady,
                      onMapEvent: (event) {
                        if (event is MapEventMoveEnd) onCameraIdle();
                      },
                    ),
                    children: [
                      if (mapStyleMode == 2)
                        ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.2126,
                            -0.7152,
                            -0.0722,
                            0,
                            290,
                            -0.2126,
                            -0.7152,
                            -0.0722,
                            0,
                            290,
                            -0.2126,
                            -0.7152,
                            -0.0722,
                            0,
                            290,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: TileLayer(
                            urlTemplate: _tileUrl,
                            userAgentPackageName: 'com.example.brevet_map',
                            tileProvider: _tileProvider,
                          ),
                        )
                      else
                        TileLayer(
                          urlTemplate: _tileUrl,
                          userAgentPackageName: 'com.example.brevet_map',
                          tileProvider: _tileProvider,
                        ),
                      PolylineLayer(polylines: polylines),
                      MarkerLayer(
                        markers: [
                          ...markers,
                          if (locationMarker != null) locationMarker!,
                        ],
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          child: Text(
                            _attribution,
                            style: TextStyle(
                              fontSize: 11,
                              color: mapStyleMode == 2
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 16,
                    bottom: 24,
                    child: MapStyleButton(
                      mapStyleMode: mapStyleMode,
                      onTap: onMapStyleTap,
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 24,
                    child: Tooltip(
                      message: '設定',
                      child: Material(
                        color: Colors.white,
                        elevation: 5,
                        shadowColor: Colors.black26,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            shape: const RoundedRectangleBorder(),
                            builder: (_) => _SettingsBottomSheet(
                              onOfflineMapDownloadTap: () {
                                Navigator.pop(context);
                                onOfflineMapDownloadTap();
                              },
                              isOfflineMapAvailable: offlineMapState.isAvailable,
                              isOfflineMapUsing: offlineMapState.isUsing,
                              onUseOfflineMapTap: () {
                                Navigator.pop(context);
                                onUseOfflineMapTap();
                              },
                              onUseOnlineMapTap: () {
                                Navigator.pop(context);
                                onUseOnlineMapTap();
                              },
                            ),
                          ),
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 60,
                            height: 60,
                            child: Icon(
                              Icons.more_vert,
                              color: Colors.blueGrey,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 24,
                    child: Center(
                      child: BatteryIndicator(),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 24,
                    child: MapToolButtons(onRouteBoundsTap: onRouteBoundsTap),
                  ),
                  if (showMyLocationButton)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: Tooltip(
                        message: '現在地を表示',
                        child: Material(
                          color: Colors.white,
                          elevation: 5,
                          shadowColor: Colors.black26,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: onMyLocationTap,
                            customBorder: const CircleBorder(),
                            child: const SizedBox(
                              width: 60,
                              height: 60,
                              child: Icon(
                                Icons.my_location,
                                color: Colors.blueGrey,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (isStreamActive && onGpsLevelTap != null)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: _GpsLevelButton(
                        isLowMode: isLowMode,
                        isStreamAccuracyLow: isStreamAccuracyLow,
                        onTap: onGpsLevelTap!,
                      ),
                    ),
                  if (offlineMapState.isDownloading)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'ダウンロード中...',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: 240,
                                child: LinearProgressIndicator(
                                  value: offlineMapState.downloadProgress,
                                  backgroundColor: Colors.white38,
                                  valueColor: const AlwaysStoppedAnimation(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(offlineMapState.downloadProgress * 100).toInt()}%',
                                style:
                                    const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          LocationBottomBar(
            isStreamActive: isStreamActive,
            onTap: onToggleLocationStream,
            progressBarValue: progressBarValue,
            isLowMode: isLowMode,
          ),
        ],
      ),
    );
  }
}

/// 設定ボトムシート
class _SettingsBottomSheet extends StatelessWidget {
  const _SettingsBottomSheet({
    required this.onOfflineMapDownloadTap,
    required this.isOfflineMapAvailable,
    required this.isOfflineMapUsing,
    required this.onUseOfflineMapTap,
    required this.onUseOnlineMapTap,
  });

  final VoidCallback onOfflineMapDownloadTap;
  final bool isOfflineMapAvailable;
  final bool isOfflineMapUsing;
  final VoidCallback onUseOfflineMapTap;
  final VoidCallback onUseOnlineMapTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.download_for_offline_outlined),
            title: const Text('オフラインマップをダウンロード'),
            onTap: onOfflineMapDownloadTap,
          ),
          if (isOfflineMapUsing)
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('オンラインマップを使用'),
              onTap: onUseOnlineMapTap,
            )
          else if (isOfflineMapAvailable)
            ListTile(
              leading: const Icon(Icons.wifi_off),
              title: const Text('オフラインマップを使用'),
              onTap: onUseOfflineMapTap,
            ),
        ],
      ),
    );
  }
}

/// 位置情報レベル切り替えボタン
class _GpsLevelButton extends StatelessWidget {
  const _GpsLevelButton({
    required this.isLowMode,
    required this.isStreamAccuracyLow,
    required this.onTap,
  });

  final bool isLowMode;
  final bool isStreamAccuracyLow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isLowMode ? Colors.blueGrey : Colors.white;
    final textColor = isLowMode ? Colors.white : Colors.blueGrey;
    final label = isStreamAccuracyLow ? 'LOW' : 'GPS';

    return Tooltip(
      message: '位置情報レベルを切り替え',
      child: Material(
        color: backgroundColor,
        elevation: 5,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

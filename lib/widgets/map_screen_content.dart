import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_bottom_bar.dart';
import 'map_style_button.dart';
import 'map_tool_buttons.dart';

/// 地図画面の本体。地図・オーバーレイ・下部バーをまとめる。
class MapScreenContent extends StatelessWidget {
  const MapScreenContent({
    super.key,
    required this.initialPosition,
    required this.initialZoom,
    required this.polylines,
    required this.markers,
    required this.mapStyleMode,
    required this.onCameraIdle,
    required this.onMapCreated,
    required this.onMapStyleTap,
    required this.onRouteBoundsTap,
    required this.onMyLocationTap,
    required this.showMyLocationButton,
    required this.isStreamActive,
    required this.onToggleLocationStream,
    this.progressBarValue,
    this.isLowMode = false,
    this.onGpsLevelTap,
    this.onUserInteraction,
  });

  final LatLng initialPosition;
  final double initialZoom;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final int mapStyleMode;
  final VoidCallback onCameraIdle;
  final void Function(GoogleMapController controller) onMapCreated;
  final VoidCallback onMapStyleTap;
  final VoidCallback onRouteBoundsTap;
  final VoidCallback onMyLocationTap;
  final bool showMyLocationButton;
  final bool isStreamActive;
  final VoidCallback onToggleLocationStream;
  final ValueNotifier<double>? progressBarValue;

  /// true のとき位置情報ストリームボタンをグレー表示する（LOWモード時）
  final bool isLowMode;

  final VoidCallback? onGpsLevelTap;

  /// 画面タッチ時（5分無操作LOWモード解除用）
  final VoidCallback? onUserInteraction;

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
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: initialPosition,
                      zoom: initialZoom,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    zoomControlsEnabled: false,
                    polylines: polylines,
                    markers: markers,
                    onCameraIdle: onCameraIdle,
                    onMapCreated: onMapCreated,
                  ),
                  if (!isLowMode)
                    Positioned(
                      left: 16,
                      bottom: 24,
                      child: MapStyleButton(
                        mapStyleMode: mapStyleMode,
                        onTap: onMapStyleTap,
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
                    ),
                  if (isStreamActive && onGpsLevelTap != null)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: _GpsLevelButton(
                        isLowMode: isLowMode,
                        onTap: onGpsLevelTap!,
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

/// 位置情報レベル切り替えボタン
class _GpsLevelButton extends StatelessWidget {
  const _GpsLevelButton({
    required this.isLowMode,
    required this.onTap,
  });

  final bool isLowMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isLowMode ? Colors.blueGrey : Colors.white;
    final textColor = isLowMode ? Colors.white : Colors.blueGrey;

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
            width: 44,
            height: 44,
            child: Center(
              child: Text(
                'LOW',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
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

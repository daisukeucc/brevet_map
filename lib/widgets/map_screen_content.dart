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
    this.streamAccuracyLabel,
    this.onGpsLevelTap,
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
  /// ストリームON時のみ使用。表示用ラベル（NML / LOW）
  final String? streamAccuracyLabel;
  final VoidCallback? onGpsLevelTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: initialPosition,
                    zoom: initialZoom,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  polylines: polylines,
                  markers: markers,
                  onCameraIdle: onCameraIdle,
                  onMapCreated: onMapCreated,
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
                if (isStreamActive &&
                    streamAccuracyLabel != null &&
                    onGpsLevelTap != null)
                  Positioned(
                    right: 16,
                    bottom: 24,
                    child: Tooltip(
                      message: '位置情報レベルを切り替え',
                      child: Material(
                        color: Colors.white,
                        elevation: 5,
                        shadowColor: Colors.black26,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: onGpsLevelTap,
                          customBorder: const CircleBorder(),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Center(
                              child: Text(
                                streamAccuracyLabel!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          LocationBottomBar(
            isStreamActive: isStreamActive,
            onTap: onToggleLocationStream,
            progressBarValue: progressBarValue,
          ),
        ],
      ),
    );
  }
}

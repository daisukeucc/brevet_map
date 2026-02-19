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
                  child: MapToolButtons(
                    onRouteBoundsTap: onRouteBoundsTap,
                    onMyLocationTap: onMyLocationTap,
                    showMyLocationButton: showMyLocationButton,
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

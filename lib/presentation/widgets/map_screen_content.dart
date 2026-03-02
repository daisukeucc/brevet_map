import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'battery_indicator.dart';
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
    required this.sleepDuration,
    required this.onSleepDurationChanged,
    required this.onGpxImportTap,
    required this.onAddPoiTap,
    this.isDragMode = false,
    this.progressBarValue,
    this.isLowMode = false,
    this.isStreamAccuracyLow = false,
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

  /// 位置ストリームの精度が low のとき true（GPSボタンのラベルを「LOW」にする）
  final bool isStreamAccuracyLow;

  final VoidCallback? onGpsLevelTap;

  /// 画面スリープまでの時間（分）。0=OFF
  final int sleepDuration;

  /// スリープ時間変更コールバック
  final void Function(int) onSleepDurationChanged;

  /// GPXファイルインポートコールバック
  final VoidCallback onGpxImportTap;

  /// POI追加コールバック
  final VoidCallback onAddPoiTap;

  /// true のときマーカードラッグ編集モード（全ボタンを非表示にする）
  final bool isDragMode;

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
                  if (!isDragMode)
                    Positioned(
                      left: 16,
                      bottom: 24,
                      child: MapStyleButton(
                        mapStyleMode: mapStyleMode,
                        onTap: onMapStyleTap,
                      ),
                    ),
                  if (!isStreamActive && !isDragMode)
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
                                sleepDuration: sleepDuration,
                                onSleepDurationChanged: onSleepDurationChanged,
                                onGpxImportTap: () {
                                  final navigator = Navigator.of(context);
                                  Future.delayed(
                                    const Duration(milliseconds: 200),
                                    () {
                                      navigator.pop();
                                      onGpxImportTap();
                                    },
                                  );
                                },
                                onAddPoiTap: () {
                                  final navigator = Navigator.of(context);
                                  Future.delayed(
                                    const Duration(milliseconds: 200),
                                    () {
                                      navigator.pop();
                                      onAddPoiTap();
                                    },
                                  );
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
                  if (!isDragMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 24,
                      child: Center(
                        child: BatteryIndicator(),
                      ),
                    ),
                  if (!isDragMode)
                    Positioned(
                      right: 16,
                      top: 24,
                      child: MapToolButtons(onRouteBoundsTap: onRouteBoundsTap),
                    ),
                  if (showMyLocationButton && !isDragMode)
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
                            child: SizedBox(
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
                  if (isStreamActive && onGpsLevelTap != null && !isDragMode)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: _GpsLevelButton(
                        isLowMode: isLowMode,
                        isStreamAccuracyLow: isStreamAccuracyLow,
                        onTap: onGpsLevelTap!,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AbsorbPointer(
            absorbing: isDragMode,
            child: Opacity(
              opacity: isDragMode ? 0.0 : 1.0,
              child: LocationBottomBar(
                isStreamActive: isStreamActive,
                onTap: onToggleLocationStream,
                progressBarValue: progressBarValue,
                isLowMode: isLowMode,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 設定ボトムシート
class _SettingsBottomSheet extends StatefulWidget {
  const _SettingsBottomSheet({
    required this.sleepDuration,
    required this.onSleepDurationChanged,
    required this.onGpxImportTap,
    required this.onAddPoiTap,
  });

  final int sleepDuration;
  final void Function(int) onSleepDurationChanged;
  final VoidCallback onGpxImportTap;
  final VoidCallback onAddPoiTap;

  @override
  State<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<_SettingsBottomSheet> {
  late int _sleepDuration;

  @override
  void initState() {
    super.initState();
    _sleepDuration = widget.sleepDuration;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.blueGrey),
            title: const Text(
              'GPXファイルをインポート',
              style: TextStyle(fontSize: 17),
            ),
            onTap: widget.onGpxImportTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            horizontalTitleGap: 8,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.bedtime, color: Colors.blueGrey),
                const SizedBox(width: 8),
                const Text('画面スリープ設定', style: TextStyle(fontSize: 17)),
              ],
            ),
          ),
          _SleepDurationSelector(
            value: _sleepDuration,
            onChanged: (v) {
              setState(() => _sleepDuration = v);
              widget.onSleepDurationChanged(v);
              Future.delayed(const Duration(milliseconds: 400), () {
                if (context.mounted) Navigator.pop(context);
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_location_alt, color: Colors.blueGrey),
            title: const Text(
              'POIを追加',
              style: TextStyle(fontSize: 17),
            ),
            onTap: widget.onAddPoiTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            horizontalTitleGap: 8,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// スリープ時間ラジオボタン行
class _SleepDurationSelector extends StatelessWidget {
  const _SleepDurationSelector({
    required this.value,
    required this.onChanged,
  });

  final int value;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    const options = [(0, 'OFF'), (1, '1分'), (5, '5分'), (10, '10分')];
    return Padding(
      padding: const EdgeInsets.only(left: 38),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (int i = 0; i < options.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            GestureDetector(
              onTap: () => onChanged(options[i].$1),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Radio<int>(
                    value: options[i].$1,
                    groupValue: value,
                    onChanged: (v) => onChanged(v!),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  Text(options[i].$2, style: const TextStyle(fontSize: 17)),
                ],
              ),
            ),
          ],
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

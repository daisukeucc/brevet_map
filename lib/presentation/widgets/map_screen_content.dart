import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_localizations.dart';
import 'battery_indicator.dart';
import 'location_bottom_bar.dart';
import 'map_style_button.dart';
import 'map_tool_buttons.dart';
import 'radio_selection_dialog.dart';
import 'settings_bottom_sheet.dart';

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
    required this.distanceUnit,
    required this.onDistanceUnitChanged,
    required this.onGpxImportTap,
    required this.onAddPoiTap,
    this.hasUserPois = false,
    this.isDragMode = false,
    this.isMapTapAddMode = false,
    this.onMapLongPress,
    this.progressBarValue,
    this.isLowMode = false,
    this.isStreamAccuracyLow = false,
    this.onGpsLevelTap,
    this.onUserInteraction,
    this.offlineCenter,
  });

  /// オフライン時に地図の代わりに中央に表示するウィジェット。
  /// 非 null の場合、GoogleMap の代わりにこれを表示（ボタン・下部バーは通常表示）。
  final Widget? offlineCenter;

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

  /// 距離単位。0=km, 1=mile
  final int distanceUnit;

  /// 距離単位変更コールバック
  final void Function(int) onDistanceUnitChanged;

  /// GPXファイルインポートコールバック
  final VoidCallback onGpxImportTap;

  /// POI登録コールバック
  final VoidCallback onAddPoiTap;

  /// ユーザーPOIが1件以上登録されている場合 true
  final bool hasUserPois;

  /// true のときマーカードラッグ編集モード（全ボタンを非表示にする）
  final bool isDragMode;

  /// true のとき地図タップでPOI登録モード（全ボタンを非表示にする）
  final bool isMapTapAddMode;

  /// 地図長押し時コールバック（地図タップ登録モード時）
  final void Function(LatLng)? onMapLongPress;

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
                  if (offlineCenter != null)
                    Positioned.fill(child: offlineCenter!)
                  else
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
                      onLongPress: onMapLongPress,
                    ),
                  if (!isDragMode && !isMapTapAddMode)
                    Positioned(
                      left: 16,
                      bottom: 24,
                      child: MapStyleButton(
                        mapStyleMode: mapStyleMode,
                        onTap: onMapStyleTap,
                      ),
                    ),
                  if (!isStreamActive && !isDragMode && !isMapTapAddMode)
                    Positioned(
                      left: 16,
                      top: 24,
                      child: Tooltip(
                        message: AppLocalizations.of(context)!.settings,
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
                              builder: (_) => SettingsBottomSheet(
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
                                hasUserPois: hasUserPois,
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
                                onSleepSettingsTap: () async {
                                  final navigator = Navigator.of(context);
                                  final l10n = AppLocalizations.of(context)!;
                                  await Future.delayed(
                                      const Duration(milliseconds: 200));
                                  navigator.pop();
                                  if (!context.mounted) return;
                                  showRadioSelectionDialog<int>(
                                    context: context,
                                    title: l10n.sleepSettings,
                                    options: [
                                      (0, l10n.sleepOff),
                                      (1, l10n.sleep1min),
                                      (5, l10n.sleep5min),
                                      (10, l10n.sleep10min),
                                    ],
                                    initialValue: sleepDuration,
                                    onChanged: onSleepDurationChanged,
                                  );
                                },
                                onDistanceUnitTap: () async {
                                  final navigator = Navigator.of(context);
                                  final l10n = AppLocalizations.of(context)!;
                                  await Future.delayed(
                                      const Duration(milliseconds: 200));
                                  navigator.pop();
                                  if (!context.mounted) return;
                                  showRadioSelectionDialog<int>(
                                    context: context,
                                    title: l10n.distanceUnit,
                                    options: [
                                      (0, l10n.unitKm),
                                      (1, l10n.unitMile)
                                    ],
                                    initialValue: distanceUnit,
                                    onChanged: onDistanceUnitChanged,
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
                  if (!isDragMode && !isMapTapAddMode)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 24,
                      child: Center(
                        child: BatteryIndicator(),
                      ),
                    ),
                  if (!isDragMode && !isMapTapAddMode)
                    Positioned(
                      right: 16,
                      top: 24,
                      child: MapToolButtons(onRouteBoundsTap: onRouteBoundsTap),
                    ),
                  if (showMyLocationButton && !isDragMode && !isMapTapAddMode)
                    Positioned(
                      right: 16,
                      bottom: 24,
                      child: Tooltip(
                        message: AppLocalizations.of(context)!.showMyLocation,
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
                  if (isStreamActive &&
                      onGpsLevelTap != null &&
                      !isDragMode &&
                      !isMapTapAddMode)
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
            absorbing: isDragMode || isMapTapAddMode,
            child: Opacity(
              opacity: (isDragMode || isMapTapAddMode) ? 0.0 : 1.0,
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
      message: AppLocalizations.of(context)!.switchGpsLevel,
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

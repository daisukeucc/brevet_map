import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../l10n/app_localizations.dart';
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
                              builder: (_) => _SettingsBottomSheet(
                                sleepDuration: sleepDuration,
                                onSleepDurationChanged: onSleepDurationChanged,
                                distanceUnit: distanceUnit,
                                onDistanceUnitChanged: onDistanceUnitChanged,
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

/// 設定ボトムシート
class _SettingsBottomSheet extends StatefulWidget {
  const _SettingsBottomSheet({
    required this.sleepDuration,
    required this.onSleepDurationChanged,
    required this.distanceUnit,
    required this.onDistanceUnitChanged,
    required this.onGpxImportTap,
    required this.hasUserPois,
    required this.onAddPoiTap,
  });

  final int sleepDuration;
  final void Function(int) onSleepDurationChanged;
  final int distanceUnit;
  final void Function(int) onDistanceUnitChanged;
  final VoidCallback onGpxImportTap;
  final bool hasUserPois;
  final VoidCallback onAddPoiTap;

  @override
  State<_SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<_SettingsBottomSheet> {
  late int _sleepDuration;
  late int _distanceUnit;

  @override
  void initState() {
    super.initState();
    _sleepDuration = widget.sleepDuration;
    _distanceUnit = widget.distanceUnit;
  }

  void _showSleepDurationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (0, l10n.sleepOff),
      (1, l10n.sleep1min),
      (5, l10n.sleep5min),
      (10, l10n.sleep10min),
    ];
    showDialog<void>(
      context: context,
      builder: (ctx) {
        int selected = _sleepDuration;
        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            shape: const RoundedRectangleBorder(),
            title: Text(l10n.sleepSettings),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((e) => RadioListTile<int>(
                        title: Text(e.$2),
                        value: e.$1,
                        groupValue: selected,
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => selected = v);
                          setState(() => _sleepDuration = v);
                          widget.onSleepDurationChanged(v);
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (ctx.mounted) Navigator.pop(ctx);
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _showDistanceUnitDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = [(0, l10n.unitKm), (1, l10n.unitMile)];
    showDialog<void>(
      context: context,
      builder: (ctx) {
        int selected = _distanceUnit;
        return StatefulBuilder(
          builder: (_, setDialogState) => AlertDialog(
            shape: const RoundedRectangleBorder(),
            title: Text(l10n.distanceUnit),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map((e) => RadioListTile<int>(
                        title: Text(e.$2),
                        value: e.$1,
                        groupValue: selected,
                        onChanged: (v) {
                          if (v == null) return;
                          setDialogState(() => selected = v);
                          setState(() => _distanceUnit = v);
                          widget.onDistanceUnitChanged(v);
                          Future.delayed(const Duration(milliseconds: 400), () {
                            if (ctx.mounted) Navigator.pop(ctx);
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.gpxImport,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onGpxImportTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.add_location_alt, color: Colors.black54),
            title: Text(
              widget.hasUserPois
                  ? AppLocalizations.of(context)!.poiAddEdit
                  : AppLocalizations.of(context)!.poiAdd,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onAddPoiTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.sleepSettings,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: () => _showSleepDurationDialog(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 20,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.straighten, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.distanceUnit,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: () => _showDistanceUnitDialog(context),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 20,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          const SizedBox(height: 15),
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

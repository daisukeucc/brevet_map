import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';

import '../../config/tile_config.dart';
import '../../l10n/app_localizations.dart';
import '../handlers/settings_menu_handler.dart';
import 'battery_indicator.dart';
import 'callout_overlay.dart';
import 'gps_level_button.dart';
import 'location_bottom_bar.dart';
import 'map_style_button.dart';
import 'map_tool_buttons.dart';
import 'settings_bottom_sheet.dart';

/// 地図画面の本体。地図・オーバーレイ・下部バーをまとめる。
class MapScreenContent extends StatefulWidget {
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
    required this.onSleepSettingsTap,
    required this.onDistanceUnitTap,
    required this.onGpxImportTap,
    required this.onGpxExportTap,
    required this.onOfflineMapTap,
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
    this.onShareTap,
    this.calloutPosition,
    this.calloutText,
    this.calloutHp,
    this.isShareMode = false,
  });

  /// 共有モード時 true（スクリーンショット用に四隅ボタン・バッテリーを非表示にする）
  final bool isShareMode;

  /// 吹き出し表示時の現在地（共有モード用）
  final LatLng? calloutPosition;

  /// 吹き出しのメインテキスト
  final String? calloutText;

  /// 吹き出しのHP値（0.0〜1.0）。null のときゲージ非表示
  final double? calloutHp;

  /// 共有ボタンタップ時のコールバック。GlobalKey を渡して共有フローを実行する。
  final void Function(GlobalKey key)? onShareTap;

  /// オフライン時に地図の代わりに中央に表示するウィジェット。
  /// 非 null の場合、FlutterMap の代わりにこれを表示（ボタン・下部バーは通常表示）。
  final Widget? offlineCenter;

  final LatLng initialPosition;
  final double initialZoom;
  final List<Polyline> polylines;
  final List<Marker> markers;
  final int mapStyleMode;
  final VoidCallback onCameraIdle;
  final void Function(MapController controller) onMapCreated;
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

  /// スリープ設定メニュータップ時のコールバック（フロー全体を実行）
  final VoidCallback onSleepSettingsTap;

  /// 距離単位メニュータップ時のコールバック（フロー全体を実行）
  final VoidCallback onDistanceUnitTap;

  /// GPXファイルインポートコールバック
  final VoidCallback onGpxImportTap;

  /// GPXファイルエクスポートコールバック
  final VoidCallback onGpxExportTap;

  /// オフラインマップコールバック
  final VoidCallback onOfflineMapTap;

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
  State<MapScreenContent> createState() => _MapScreenContentState();
}

class _MapScreenContentState extends State<MapScreenContent> {
  late final MapController _mapController;
  late final FMTCTileProvider _tileProvider;
  final GlobalKey _screenshotKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // initState 時点で TileConfig.initUserAgentPackageName() は main() で完了済み
    _tileProvider = FMTCTileProvider(
      stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
      headers: {'User-Agent': TileConfig.userAgent},
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated(_mapController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: Listener(
              onPointerDown: (_) => widget.onUserInteraction?.call(),
              child: RepaintBoundary(
                key: _screenshotKey,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          if (widget.offlineCenter != null)
                            Positioned.fill(child: widget.offlineCenter!)
                          else
                            _buildMap(),
                          if (!widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            Positioned(
                              left: 16,
                              bottom: 24,
                              child: MapStyleButton(
                                mapStyleMode: widget.mapStyleMode,
                                onTap: widget.onMapStyleTap,
                              ),
                            ),
                          if (widget.isStreamActive &&
                              widget.onShareTap != null &&
                              !widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            Positioned(
                              left: 16,
                              top: 24,
                              child: Tooltip(
                                message: AppLocalizations.of(context)!.share,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 5,
                                  shadowColor: Colors.black26,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () =>
                                        widget.onShareTap?.call(_screenshotKey),
                                    customBorder: const CircleBorder(),
                                    child: SizedBox(
                                      width: 60,
                                      height: 60,
                                      child: Center(
                                        child: Transform.translate(
                                          offset: const Offset(-3, 0),
                                          child: const Icon(
                                            Icons.share,
                                            color: Colors.blueGrey,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (!widget.isStreamActive &&
                              !widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
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
                                        onGpxImportTap: () => popSheetAndCall(
                                            context, widget.onGpxImportTap),
                                        onGpxExportTap: () => popSheetAndCall(
                                            context, widget.onGpxExportTap),
                                        onOfflineMapTap: () => popSheetAndCall(
                                            context, widget.onOfflineMapTap),
                                        hasUserPois: widget.hasUserPois,
                                        onAddPoiTap: () => popSheetAndCall(
                                            context, widget.onAddPoiTap),
                                        onSleepSettingsTap: () =>
                                            popSheetAndCall(context,
                                                widget.onSleepSettingsTap),
                                        onDistanceUnitTap: () =>
                                            popSheetAndCall(context,
                                                widget.onDistanceUnitTap),
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
                          if (!widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            const Positioned(
                              left: 0,
                              right: 0,
                              top: 24,
                              child: Center(
                                child: BatteryIndicator(),
                              ),
                            ),
                          if (!widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            Positioned(
                              right: 16,
                              top: 24,
                              child: MapToolButtons(
                                  onRouteBoundsTap: widget.onRouteBoundsTap),
                            ),
                          if (widget.showMyLocationButton &&
                              !widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            Positioned(
                              right: 16,
                              bottom: 24,
                              child: Tooltip(
                                message: AppLocalizations.of(context)!
                                    .showMyLocation,
                                child: Material(
                                  color: Colors.white,
                                  elevation: 5,
                                  shadowColor: Colors.black26,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: widget.onMyLocationTap,
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
                          if (widget.isStreamActive &&
                              widget.onGpsLevelTap != null &&
                              !widget.isShareMode &&
                              !widget.isDragMode &&
                              !widget.isMapTapAddMode)
                            Positioned(
                              right: 16,
                              bottom: 24,
                              child: GpsLevelButton(
                                isLowMode: widget.isLowMode,
                                isStreamAccuracyLow: widget.isStreamAccuracyLow,
                                onTap: widget.onGpsLevelTap!,
                              ),
                            ),
                        ],
                      ),
                    ),
                    AbsorbPointer(
                      absorbing: widget.isDragMode || widget.isMapTapAddMode,
                      child: Opacity(
                        opacity: (widget.isDragMode || widget.isMapTapAddMode)
                            ? 0.0
                            : 1.0,
                        child: LocationBottomBar(
                          isStreamActive: widget.isStreamActive,
                          onTap: widget.onToggleLocationStream,
                          progressBarValue: widget.progressBarValue,
                          isLowMode: widget.isLowMode,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TileLayer _buildTileLayer(String urlTemplate, bool useOsmOrg) {
    return TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: TileConfig.userAgentPackageName,
      subdomains: useOsmOrg ? const [] : const ['a', 'b', 'c'],
      tileProvider: _tileProvider,
    );
  }

  Widget _buildMap() {
    final isDark = widget.mapStyleMode == 2;
    final languageCode = Localizations.localeOf(context).languageCode;
    final urlTemplate = TileConfig.getTileUrlTemplate(languageCode);
    // tile.openstreetmap.org は OSM 推奨のためサブドメインなし（subdomains: []）
    final useOsmOrg = urlTemplate.contains('tile.openstreetmap.org');
    final map = FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.initialPosition,
        initialZoom: widget.initialZoom,
        onMapReady: () {
          // flutter_map の既知の不具合: 初回表示でタイルがグレーのままになる場合がある
          // workaround: 微移動で MapEventWithMove を発火させ、タイル読み込みを促す
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            final cam = _mapController.camera;
            _mapController.move(cam.center, cam.zoom + 0.0001);
            Future.delayed(const Duration(milliseconds: 50), () {
              if (!mounted) return;
              _mapController.move(cam.center, cam.zoom);
              setState(() {});
            });
          });
        },
        onMapEvent: (event) {
          if (event is MapEventMoveEnd) {
            widget.onCameraIdle();
          }
        },
        onLongPress: (_, point) => widget.onMapLongPress?.call(point),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        if (isDark)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              -0.2126,
              -0.7152,
              -0.0722,
              0,
              265,
              -0.2126,
              -0.7152,
              -0.0722,
              0,
              265,
              -0.2126,
              -0.7152,
              -0.0722,
              0,
              285,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: _buildTileLayer(urlTemplate, useOsmOrg),
          )
        else
          _buildTileLayer(urlTemplate, useOsmOrg),
        Align(
          alignment: Alignment.bottomRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.6),
            ),
            child: widget.isShareMode
                ? Text.rich(
                    TextSpan(
                      text: 'Powered by ',
                      style: (Theme.of(context).textTheme.bodySmall ??
                              const TextStyle())
                          .copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black54,
                      ),
                      children: [
                        TextSpan(
                          text: 'Brevet Map',
                          style: (Theme.of(context).textTheme.bodySmall ??
                                  const TextStyle())
                              .copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    TileConfig.attribution,
                    style: (Theme.of(context).textTheme.bodySmall ??
                            const TextStyle())
                        .copyWith(
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black54,
                    ),
                  ),
          ),
        ),
        if (widget.polylines.isNotEmpty)
          PolylineLayer(polylines: widget.polylines),
        if (widget.markers.isNotEmpty) MarkerLayer(markers: widget.markers),
        if (widget.calloutPosition != null &&
            widget.calloutText != null &&
            widget.offlineCenter == null)
          CalloutOverlay(
            position: widget.calloutPosition!,
            text: widget.calloutText!,
            hp: widget.calloutHp,
          ),
      ],
    );
    return map;
  }
}

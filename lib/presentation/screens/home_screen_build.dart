part of 'home_screen.dart';

/// build() 補助メソッド・マップイベントハンドラをまとめた mixin。
/// [_MyHomePageState] に mix-in して使用する。
mixin _BuildMixin on ConsumerState<MyHomePage>, _LocationStreamMixin, _ShareUrlMixin, _PoiModeMixin {
  // _isDragMode / _isMapTapAddMode は _PoiModeMixin が保有。
  // _pendingSharedPosition / _sharePreviewIcon / _isShareMode / _shareHp は _ShareUrlMixin が保有。
  // abstract 宣言は不要。

  // ── 定数 ─────────────────────────────────────────────────────────────────

  /// デフォルトズームレベル
  double get _defaultZoom => 12.0;

  // ── メソッド ─────────────────────────────────────────────────────────────

  void _onUserInteraction() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  Widget _buildOfflineLayout(BuildContext context, VoidCallback onRetry) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final tileProviderKey = ref.watch(mapTileProviderKeyProvider);
    final position = _initialPosition ?? _defaultPosition();

    return MapScreenContent(
      key: ValueKey(tileProviderKey),
      initialPosition: LatLng(position.latitude, position.longitude),
      initialZoom: mapState.savedZoomLevel ?? _defaultZoom,
      polylines: mapState.routePolylines,
      markers: mapState.routeMarkers,
      mapStyleMode: mapState.mapStyleMode,
      onCameraIdle: _onCameraIdle,
      onMapCreated: _onMapCreated,
      onMapStyleTap: _onMapStyleTap,
      onRouteBoundsTap: _onRouteBoundsTap,
      isRouteBoundsMode: _isRouteBoundsMode,
      isStreamActive: locationState.isActive,
      onToggleLocationStream: _toggleLocationStream,
      progressBarValue: locationState.progressBarValue,
      isScreenSleepOn: ref.watch(screenSleepProvider),
      onSleepToggleTap: () {
        final current = ref.read(screenSleepProvider);
        handleScreenSleepChange(context, ref, !current);
      },
      onAppSettingsTap: () => showAppSettingsScreen(
        context,
        onDistanceUnitTap: () => showDistanceUnitFlow(context, ref),
        onLanguageTap: () => showLanguageSelectionFlow(context, ref),
        onBatteryDisplayTap: () => showBatteryDisplayDialog(context, ref),
        onLocationSharingTap: () => shareCurrentLocation(context),
        onContactUsTap: () => openContactEmail(context),
      ),
      onGpxImportTap: () => handleGpxImportTap(
        context,
        ref,
        onSuccess: () => setState(() => _isRouteBoundsMode = true),
      ),
      onGpxExportTap: () => handleGpxExportTap(context, ref),
      onOfflineMapTap: () => handleOfflineMapTap(context, ref),
      onAddPoiTap: () => handleAddPoiTap(
        context,
        ref,
        getMounted: () => mounted,
        onStartMapTapAddMode: () => setState(() => _isMapTapAddMode = true),
        onStartDragMode: () => setState(() => _isDragMode = true),
        onDragEnd: (p, latLng) => handlePoiDragEnd(
          context,
          ref,
          p,
          latLng,
          onStopDragMode: () => setState(() => _isDragMode = false),
        ),
      ),
      hasUserPois: mapState.userPois.isNotEmpty,
      onUserInteraction: _onUserInteraction,
      isDragMode: _isDragMode,
      isMapTapAddMode: _isMapTapAddMode || _pendingSharedPosition != null,
      showBatteryLevel: ref.watch(batteryDisplayProvider),
      offlineCenter: OfflinePlaceholderView(onRetry: onRetry),
      isShareMode: _isShareMode,
      onShareTap: (key) {
        handleShareButtonTap(
          context: context,
          ref: ref,
          screenshotKey: key,
          currentPosition: _latestStreamPosition != null
              ? LatLng(
                  _latestStreamPosition!.latitude,
                  _latestStreamPosition!.longitude,
                )
              : null,
          previousPosition: _previousStreamPosition != null
              ? LatLng(
                  _previousStreamPosition!.latitude,
                  _previousStreamPosition!.longitude,
                )
              : null,
          onShareModeChanged: (isShareMode, {shareHp}) => setState(() {
            _isShareMode = isShareMode;
            _shareHp = shareHp;
          }),
          getMounted: () => mounted,
          onAfterCameraAnimation: (zoomBefore) {
            if (ref.read(locationStreamProvider).isActive) {
              _savedStreamZoom = zoomBefore;
            }
          },
        );
      },
    );
  }

  Widget _buildMapLayout(BuildContext context) {
    final mapState = ref.watch(mapStateProvider);
    final locationState = ref.watch(locationStreamProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);
    final tileProviderKey = ref.watch(mapTileProviderKeyProvider);
    final position = _initialPosition ?? _defaultPosition();

    // 位置取得が完了してからルート作成（ネットワークチェックでオンライン表示が先になる場合の対策）
    if (_positionFetchCompleted && !_hasTriggeredInitialRouteFetch) {
      _hasTriggeredInitialRouteFetch = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mapStateProvider.notifier).fetchOrLoadRouteIfNeeded(
          position,
          animateCamera: (bounds) async {
            if (bounds != null) {
              await ref
                  .read(cameraControllerProvider.notifier)
                  .animateToBounds(bounds);
            }
          },
        );
      });
    }

    final fallbackPos = _initialPosition ?? _defaultPosition();
    final markers = buildMapMarkers(
      baseMarkers: mapState.routeMarkers,
      pendingPosition: _pendingSharedPosition,
      sharePreviewIcon: _sharePreviewIcon,
      streamPosition: _latestStreamPosition,
      fallbackPosition: LatLng(fallbackPos.latitude, fallbackPos.longitude),
      isStreamActive: locationState.isActive,
      isDarkMode: mapState.mapStyleMode == 2,
    );

    final calloutData = computeCalloutData(
      isShareMode: _isShareMode,
      hasPosition: locationState.isActive ||
          _latestStreamPosition != null ||
          _initialPosition != null,
      currentPosition: () {
        final pos =
            _latestStreamPosition ?? _initialPosition ?? _defaultPosition();
        return LatLng(pos.latitude, pos.longitude);
      }(),
      previousPosition: _previousStreamPosition != null
          ? LatLng(
              _previousStreamPosition!.latitude,
              _previousStreamPosition!.longitude,
            )
          : null,
      routePoints: mapState.fullRoutePoints ?? mapState.savedRoutePoints,
      distanceUnit: distanceUnit,
    );

    return Stack(
      children: [
        MapScreenContent(
          key: ValueKey(tileProviderKey),
          initialPosition: LatLng(position.latitude, position.longitude),
          initialZoom: mapState.savedZoomLevel ?? _defaultZoom,
          polylines: mapState.routePolylines,
          markers: markers,
          calloutPosition: calloutData.position,
          calloutText: calloutData.text,
          calloutHp: _shareHp,
          mapStyleMode: mapState.mapStyleMode,
          onCameraIdle: _onCameraIdle,
          onMapCreated: _onMapCreated,
          onMapStyleTap: _onMapStyleTap,
          onRouteBoundsTap: _onRouteBoundsTap,
          isRouteBoundsMode: _isRouteBoundsMode,
          isStreamActive: locationState.isActive,
          onToggleLocationStream: _toggleLocationStream,
          progressBarValue: locationState.progressBarValue,
          isScreenSleepOn: ref.watch(screenSleepProvider),
          onSleepToggleTap: () {
            final current = ref.read(screenSleepProvider);
            handleScreenSleepChange(context, ref, !current);
          },
          onAppSettingsTap: () => showAppSettingsScreen(
            context,
            onDistanceUnitTap: () => showDistanceUnitFlow(context, ref),
            onLanguageTap: () => showLanguageSelectionFlow(context, ref),
            onBatteryDisplayTap: () => showBatteryDisplayDialog(context, ref),
            onLocationSharingTap: () => shareCurrentLocation(context),
            onContactUsTap: () => openContactEmail(context),
          ),
          onGpxImportTap: () => handleGpxImportTap(
            context,
            ref,
            onSuccess: () => setState(() => _isRouteBoundsMode = true),
          ),
          onGpxExportTap: () => handleGpxExportTap(context, ref),
          onOfflineMapTap: () => handleOfflineMapTap(context, ref),
          onAddPoiTap: () => handleAddPoiTap(
            context,
            ref,
            getMounted: () => mounted,
            onStartMapTapAddMode: () => setState(() => _isMapTapAddMode = true),
            onStartDragMode: () => setState(() => _isDragMode = true),
            onDragEnd: (p, latLng) => handlePoiDragEnd(
              context,
              ref,
              p,
              latLng,
              onStopDragMode: () => setState(() => _isDragMode = false),
            ),
          ),
          hasUserPois: mapState.userPois.isNotEmpty,
          onUserInteraction: _onUserInteraction,
          isDragMode: _isDragMode,
          isMapTapAddMode: _isMapTapAddMode || _pendingSharedPosition != null,
          showBatteryLevel: ref.watch(batteryDisplayProvider),
          isShareMode: _isShareMode,
          onShareTap: (key) {
            handleShareButtonTap(
              context: context,
              ref: ref,
              screenshotKey: key,
              currentPosition: _latestStreamPosition != null
                  ? LatLng(
                      _latestStreamPosition!.latitude,
                      _latestStreamPosition!.longitude,
                    )
                  : null,
              previousPosition: _previousStreamPosition != null
                  ? LatLng(
                      _previousStreamPosition!.latitude,
                      _previousStreamPosition!.longitude,
                    )
                  : null,
              onShareModeChanged: (isShareMode, {shareHp}) => setState(() {
                _isShareMode = isShareMode;
                _shareHp = shareHp;
              }),
              getMounted: () => mounted,
              onAfterCameraAnimation: (zoomBefore) {
                if (ref.read(locationStreamProvider).isActive) {
                  _savedStreamZoom = zoomBefore;
                }
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _onCameraIdle() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null) return;
    await ref.read(mapStateProvider.notifier).onCameraIdle(controller);
  }

  Future<void> _onMapCreated(MapController controller) async {
    ref.read(cameraControllerProvider.notifier).setController(controller);
    ref.read(mapStateProvider.notifier).setPoiTapHandler((poi) {
      showPoiDetailSheet(context, name: poi.name, description: poi.description);
    });
    ref.read(mapStateProvider.notifier).setUserPoiTapHandler((poi) {
      final l10n = AppLocalizations.of(context)!;
      final unit = ref.read(distanceUnitProvider);
      final prefix = poi.km != null ? '${formatDistance(poi.km!, unit)}：' : '';
      final title = poi.title.isEmpty ? l10n.titleNone : poi.title;
      showPoiDetailSheet(
        context,
        name: '$prefix$title',
        description: poi.body,
      );
    });
    await ref.read(mapStateProvider.notifier).onMapCreated(
          controller,
          animateCamera: (bounds) => ref
              .read(cameraControllerProvider.notifier)
              .animateToBounds(bounds),
        );
    // 共有URLから起動した場合、地図作成後に該当座標へズーム（起動直後はcontroller未設定のためここで実行）
    if (_pendingSharedPosition != null && mounted) {
      await ref.read(cameraControllerProvider.notifier).animateTo(
            _pendingSharedPosition!,
            zoom: 18.0,
          );
    }
  }

  Future<void> _onMapStyleTap() async {
    final controller = ref.read(cameraControllerProvider);
    await ref.read(mapStateProvider.notifier).toggleMapStyle(controller);
  }

  Widget _buildBody(BuildContext context) {
    return _buildMapLayout(context);
  }
}

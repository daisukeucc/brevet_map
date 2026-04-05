part of 'home_screen.dart';

/// 位置情報ストリーム関連の状態・ロジックをまとめた mixin。
/// [_MyHomePageState] に mix-in して使用する。
mixin _LocationStreamMixin on ConsumerState<MyHomePage>, _ShareUrlMixin {
  void _showSampleRouteDialog(BuildContext context);

  Position _fallbackPosition();

  Position _positionFromLatLng(double lat, double lng);

  // ── このmixinが所有するstate ──────────────────────────────────────────────

  /// 初期表示位置。GPS 取得成功で設定。未取得時は [_cachedDefaultPosition] を使う
  Position? _initialPosition;

  /// プリファレンスまたは既定インストール座標から解決したフォールバック位置
  Position? _cachedDefaultPosition;

  /// 位置ストリームON時の最新位置（現在地マーカー表示用）
  Position? _latestStreamPosition;

  /// 直前の位置（bearing による往路/復路判定用）
  Position? _previousStreamPosition;

  /// ルート拡大モード中は true（現在地追従を停止してルート全体を表示）
  bool _isRouteBoundsMode = true;

  /// 位置ストリームON直後の初回位置更新か（初回はデフォルトズーム、以降は現在表示ズームを維持）
  bool _isFirstPositionAfterStreamOn = false;

  /// シェアボタンタップ後にズームを復元するための保存値
  double? _savedStreamZoom;

  /// 直前のベアリング（停止中でも最後の値を維持）
  double _lastBearing = 0.0;

  /// 起動時に位置取得に失敗した場合、案内 SnackBar を一度だけ表示したか
  bool _hasShownLocationUnavailableHint = false;


  /// 初回ルート取得を実行したか（addPostFrameCallback の多重登録防止）
  bool _hasTriggeredInitialRouteFetch = false;

  /// 位置取得の試行が完了したか（成功・失敗・タイムアウト問わず）
  bool _positionFetchCompleted = false;

  /// 設定画面から戻るとき true（フォアグラウンド復帰時に位置再取得を行う）
  bool _expectingReturnFromSettings = false;

  // ── 定数 ─────────────────────────────────────────────────────────────────

  /// 停止判定の速度閾値（m/s）。これ以下では GPS ベアリングを更新しない。≒5.4 km/h
  static const double _movingSpeedThreshold = 1.5;

  /// 現在地追従時のズームレベル
  static const double _trackingZoom = 15.0;

  // ── メソッド ─────────────────────────────────────────────────────────────

  /// バックグラウンドで位置を取得し、完了後にルート取得を開始する
  void _fetchPositionInBackground() {
    getPositionWithPermission(
      context,
      onOpenSettings: () => _expectingReturnFromSettings = true,
    ).timeout(const Duration(seconds: 20), onTimeout: () => null).then((pos) {
      if (!mounted) return;
      setState(() {
        if (pos != null) _initialPosition = pos;
        _positionFetchCompleted = true;
      });
      if (pos == null && !_hasShownLocationUnavailableHint) {
        _hasShownLocationUnavailableHint = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showAppSnackBar(
            context,
            AppLocalizations.of(context)!.locationUnavailableWithRetry,
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.openSettings,
              textColor: Colors.white,
              onPressed: () => Geolocator.openAppSettings(),
            ),
          );
        });
      }
      _hasTriggeredInitialRouteFetch = true;
      final position = pos ?? _fallbackPosition();
      ref.read(mapStateProvider.notifier).fetchOrLoadRouteIfNeeded(
        position,
        animateCamera: (bounds) async {
          if (bounds != null) {
            await ref
                .read(cameraControllerProvider.notifier)
                .animateToBounds(bounds);
          }
        },
        onFirstRouteShown: () => _showSampleRouteDialog(context),
      );
    });
  }

  /// 位置ストリームから位置が更新されたときのコールバック
  void _onPositionUpdate(Position position, Position? previous) {
    if (!mounted) return;
    _previousStreamPosition = previous;
    _latestStreamPosition = position;

    // ルートが前半・後半に分割されている場合、現在地の進捗で描画順を更新
    if (ref.read(mapStateProvider).routePolylines.length == 2) {
      final routePoints = ref.read(mapStateProvider).savedRoutePoints;
      if (routePoints != null && routePoints.isNotEmpty) {
        final notifier = ref.read(mapStateProvider.notifier);
        final result = notifier.computeAlongTrackM(
          LatLng(position.latitude, position.longitude),
          previous: previous != null
              ? LatLng(previous.latitude, previous.longitude)
              : null,
        );
        final isSecondHalf = result.alongTrackM >= notifier.halfRouteDistanceM;
        notifier.updateHalfDisplay(isSecondHalf);
      }
    }

    // 共有モード中はカメラを移動しない（スクリーンショット用のルート全体表示を維持する）
    if (_isShareMode) {
      setState(() {});
      return;
    }
    // ルート拡大モード中はカメラを移動しない（ルート全体表示を維持する）
    if (_isRouteBoundsMode) {
      setState(() {});
      return;
    }
    // 走行中（速度 > 閾値）のみ GPS ベアリングで更新。停止中は最後のベアリングを維持。
    if (previous != null && position.speed > _movingSpeedThreshold) {
      final b = bearingFromPositions(previous, position);
      if (b != null) _lastBearing = b;
    }
    final double zoomToUse;
    if (_isFirstPositionAfterStreamOn) {
      zoomToUse = _trackingZoom;
      _isFirstPositionAfterStreamOn = false;
    } else if (_savedStreamZoom != null) {
      zoomToUse = _savedStreamZoom!;
      _savedStreamZoom = null;
    } else {
      zoomToUse = ref.read(cameraControllerProvider)?.camera.zoom ??
          ref.read(mapStateProvider).savedZoomLevel ??
          _trackingZoom;
    }
    ref.read(cameraControllerProvider.notifier).animateTo(
          LatLng(position.latitude, position.longitude),
          zoom: zoomToUse,
          bearing: _lastBearing,
        );
    setState(() {});
  }

  /// 位置情報サービスと権限をチェックし、不可の場合は SnackBar を表示して false を返す
  Future<bool> _checkLocationAndShowError() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return false;
      final l10n = AppLocalizations.of(context)!;
      showAppSnackBar(
        context,
        l10n.locationServiceOff,
        action: SnackBarAction(
          label: l10n.openSettings,
          textColor: Colors.white,
          onPressed: Geolocator.openLocationSettings,
        ),
      );
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;

    if (permission == LocationPermission.deniedForever) {
      showAppSnackBar(
        context,
        l10n.locationPermissionDeniedForever,
        action: SnackBarAction(
          label: l10n.openSettings,
          textColor: Colors.white,
          onPressed: Geolocator.openAppSettings,
        ),
      );
      return false;
    }

    if (permission == LocationPermission.denied) {
      showAppSnackBar(context, l10n.locationPermissionDenied);
      return false;
    }

    return true;
  }

  /// 位置情報ストリームのON/OFFを切り替える
  Future<void> _toggleLocationStream() async {
    final wasActive = ref.read(locationStreamProvider).isActive;
    if (!wasActive) {
      if (!await _checkLocationAndShowError()) return;
    }
    await ref.read(locationStreamProvider.notifier).toggle(
          onPosition: _onPositionUpdate,
        );
    if (wasActive) {
      setState(() {
        _latestStreamPosition = null;
        _previousStreamPosition = null;
      });
    } else {
      _isFirstPositionAfterStreamOn = true;
    }
  }

  /// フォアグラウンド復帰時: バックグラウンドで止めたストリームをセッション中は再開する
  Future<void> _resumeLocationStreamIfNeeded() async {
    final resumed = await ref
        .read(locationStreamProvider.notifier)
        .resumeForegroundIfNeeded(
          onPosition: _onPositionUpdate,
          ensurePermission: _checkLocationAndShowError,
        );
    if (!mounted) return;
    if (resumed) {
      setState(() => _isFirstPositionAfterStreamOn = true);
    }
  }

  /// ルート拡大ボタンのタップ処理
  Future<void> _onRouteBoundsTap() async {
    if (_isRouteBoundsMode) {
      setState(() => _isRouteBoundsMode = false);
      final knownPos =
          _latestStreamPosition ?? _initialPosition ?? _fallbackPosition();
      await ref.read(cameraControllerProvider.notifier).animateTo(
            LatLng(knownPos.latitude, knownPos.longitude),
            zoom: _trackingZoom,
            bearing: _lastBearing,
          );
    } else {
      final bounds = ref.read(mapStateProvider.notifier).getRouteBounds();
      if (bounds != null) {
        setState(() => _isRouteBoundsMode = true);
        await ref
            .read(cameraControllerProvider.notifier)
            .animateToBounds(bounds);
      }
    }
  }
}

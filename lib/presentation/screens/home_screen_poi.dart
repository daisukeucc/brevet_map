part of 'home_screen.dart';

/// POI追加モード・ドラッグモード関連の状態・ロジック・オーバーレイUIをまとめた mixin。
/// [_MyHomePageState] に mix-in して使用する。
mixin _PoiModeMixin on ConsumerState<MyHomePage>, _ShareUrlMixin {
  // ── このmixinが所有するstate ──────────────────────────────────────────────

  /// POIドラッグ移動モード中は true
  bool _isDragMode = false;

  /// 地図タップでPOI追加するモード中は true
  bool _isMapTapAddMode = false;

  // ── メソッド ─────────────────────────────────────────────────────────────

  Future<void> _onCancelDragMode() async {
    await ref.read(mapStateProvider.notifier).stopPoiDrag();
    if (!mounted) return;
    setState(() => _isDragMode = false);
  }

  Future<void> _onCancelMapTapAddMode() async {
    if (!mounted) return;
    setState(() => _isMapTapAddMode = false);
  }

  Future<void> _onConfirmMapTapPosition() async {
    final center = ref.read(cameraControllerProvider)?.camera.center;
    if (center == null || !mounted) return;
    await handleMapLongPressPoiAdd(
      context,
      ref,
      center,
      initialTitle: null,
      onComplete: () => setState(() => _isMapTapAddMode = false),
    );
  }

  // ── オーバーレイUI ────────────────────────────────────────────────────────

  /// ドラッグモード中に表示する Stack オーバーレイ一覧を返す。
  /// モードが OFF のときは空リストを返す。
  List<Widget> _buildDragModeOverlays(BuildContext context) {
    if (!_isDragMode) return const [];
    final l10n = AppLocalizations.of(context)!;
    return [
      const Positioned.fill(
        child: IgnorePointer(
          child: ColoredBox(color: Color(0x66000000)),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top,
        bottom: 80,
        left: 0,
        right: 0,
        child: const IgnorePointer(
          child: Center(
            child: Icon(Icons.my_location, size: 56, color: Colors.white),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.6),
          child: SafeArea(
            top: false,
            bottom: false,
            child: SizedBox(
              height: 96,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        final center =
                            ref.read(cameraControllerProvider)?.camera.center;
                        if (center == null) return;
                        ref
                            .read(mapStateProvider.notifier)
                            .confirmPoiDrag(center);
                      },
                      child: Text(
                        l10n.changePoiPosition,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onCancelDragMode,
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  /// POI追加モード（地図タップ・共有プレビュー）中に表示する Stack オーバーレイ一覧を返す。
  /// モードが OFF のときは空リストを返す。
  List<Widget> _buildPoiAddModeOverlays(BuildContext context) {
    if (!_isMapTapAddMode && _pendingSharedPosition == null) return const [];
    final l10n = AppLocalizations.of(context)!;
    return [
      const Positioned.fill(
        child: IgnorePointer(
          child: ColoredBox(color: Color(0x66000000)),
        ),
      ),
      if (_isMapTapAddMode && _pendingSharedPosition == null)
        Positioned(
          top: MediaQuery.of(context).padding.top,
          bottom: 80,
          left: 0,
          right: 0,
          child: const IgnorePointer(
            child: Center(
              child: Icon(Icons.my_location, size: 56, color: Colors.white),
            ),
          ),
        ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: ColoredBox(
          color: Colors.grey.shade800,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 25,
                vertical: 15,
              ),
              child: Row(
                children: [
                  if (_pendingSharedPosition != null) ...[
                    Expanded(
                      child: Text(
                        l10n.registerThisPlaceAsPoi,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontWeight: FontWeight.normal,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    TextButton(
                      onPressed: _onCancelSharePreview,
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onConfirmSharePreview,
                      child: Text(
                        l10n.ok,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    TextButton(
                      onPressed: _onConfirmMapTapPosition,
                      child: Text(
                        l10n.registerAtPosition,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _onCancelMapTapAddMode,
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

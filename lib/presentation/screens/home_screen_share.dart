part of 'home_screen.dart';

/// 共有URLフロー関連の状態・ロジックをまとめた mixin。
/// [_MyHomePageState] に mix-in して使用する。
mixin _ShareUrlMixin on ConsumerState<MyHomePage> {
  // ── このmixinが所有するstate ──────────────────────────────────────────────

  /// 共有リンクから取得した座標。非 null のときプレビューマーカー表示・登録確認UI表示
  LatLng? _pendingSharedPosition;

  /// 共有リンクから取得した施設名。POI登録時のタイトル初期値に使用
  String? _pendingSharedPlaceName;

  /// 共有プレビュー用の現在地風アイコン
  Widget? _sharePreviewIcon;

  /// 共有モード中（吹き出し表示中）は true
  bool _isShareMode = false;

  /// 共有モード時のHP値（0.0〜1.0）。ダイアログで設定
  double? _shareHp;

  // ── メソッド ─────────────────────────────────────────────────────────────

  /// initState から呼び出す。共有URLチャンネルのハンドラ登録とアイコン初期化を行う。
  void _initShareFlow() {
    createSharePreviewMarkerIcon().then((icon) {
      if (mounted) setState(() => _sharePreviewIcon = icon);
    });
    ShareChannelService.setMethodCallHandler(_onSharedUrlReceived);
    ShareChannelService.getInitialSharedUrl().then((url) {
      if (url != null && url.isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onSharedUrlReceived(url);
        });
      }
    });
  }

  /// 共有URLを受信したときのコールバック
  Future<void> _onSharedUrlReceived(String url) async {
    if (!mounted) return;
    await handleSharedUrlReceived(context, ref, url,
        onParsed: (position, placeName) {
      if (!mounted) return;
      setState(() {
        _pendingSharedPosition = position;
        _pendingSharedPlaceName = placeName;
      });
    });
  }

  /// 共有プレビューをキャンセルする
  void _onCancelSharePreview() {
    setState(() {
      _pendingSharedPosition = null;
      _pendingSharedPlaceName = null;
    });
  }

  /// 共有プレビューを確定してPOIとして登録する
  Future<void> _onConfirmSharePreview() async {
    final position = _pendingSharedPosition;
    if (position == null || !mounted) return;
    final placeName = _pendingSharedPlaceName;
    await handleConfirmSharePreview(
      context,
      ref,
      position,
      placeName,
      onClear: () {
        if (!mounted) return;
        setState(() {
          _pendingSharedPosition = null;
          _pendingSharedPlaceName = null;
        });
      },
    );
  }
}

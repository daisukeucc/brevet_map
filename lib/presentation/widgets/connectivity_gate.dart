import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/connectivity_check.dart';

/// 接続状態
enum ConnectivityGateState {
  /// 接続確認中
  checking,

  /// オフライン
  offline,

  /// オンライン
  online,
}

/// ネットワーク接続をチェックし、[builder] で状態に応じた UI を構築する。
///
/// connectivity_plus の iOS でのクラッシュを避けるため、
/// HTTP リクエストで実インターネット到達をチェックしている。
///
/// オフライン時もボタンなどを表示したい場合は、[builder] で
/// [ConnectivityGateState.offline] のときに同じレイアウトでオフライン表示を返す。
///
/// GoogleMap は [ConnectivityGateState.online] のときのみ作成すること（オフラインクラッシュ回避）。
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({
    super.key,
    required this.builder,
    this.onOnline,
    this.onOffline,
  });

  /// 接続状態に応じて UI を構築する。offline 時は [onRetry] で再接続を試行できる。
  final Widget Function(
    BuildContext context,
    ConnectivityGateState state,
    VoidCallback onRetry,
  ) builder;

  /// オフライン → オンラインに切り替わった時に呼ばれるコールバック
  final VoidCallback? onOnline;

  /// オフラインと判定された時に呼ばれるコールバック
  final VoidCallback? onOffline;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _hasCheckedConnectivity = false;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final wasOffline = _isOffline;
    final isOnline = await checkConnectivity();
    if (!mounted) return;
    setState(() {
      _hasCheckedConnectivity = true;
      _isOffline = !isOnline;
      if (wasOffline && isOnline) widget.onOnline?.call();
      if (!isOnline) widget.onOffline?.call();
    });
  }

  void _onRetry() {
    setState(() {
      _hasCheckedConnectivity = false;
    });
    _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedConnectivity) {
      return widget.builder(context, ConnectivityGateState.checking, _onRetry);
    }
    if (_isOffline) {
      return widget.builder(context, ConnectivityGateState.offline, _onRetry);
    }
    return widget.builder(context, ConnectivityGateState.online, _onRetry);
  }
}

/// 接続確認中の表示（builder の checking 時に使用可能）
///
/// [message] を指定するとその文言を使用。
/// 未指定時は「接続を確認しています」を使用（初回の ConnectivityGate 用）。
/// 位置取得待ちのときは `fetchingLocation` を渡すと「位置情報を取得しています」になる。
class ConnectivityCheckingView extends StatelessWidget {
  const ConnectivityCheckingView({super.key, this.message});

  /// 表示するメッセージ。null のときは接続確認用の文言を使用
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = message ??
        AppLocalizations.of(context)!.checkingConnectivity;
    return ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              text,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// オフライン時の中央表示（地図エリアに配置。ボタン等と組み合わせて使用）
class OfflinePlaceholderView extends StatelessWidget {
  const OfflinePlaceholderView({
    super.key,
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.offline,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.retryConnectivity),
            ),
          ],
        ),
      ),
    );
  }
}

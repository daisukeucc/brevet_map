import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// ネットワーク接続をチェックし、オフライン時は子ウィジェットを非表示にして
/// プレースホルダーを表示する。オンライン時のみ [child] を表示する。
///
/// GoogleMap のオフラインクラッシュ回避のため、接続確認後にのみ子を表示する。
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({
    super.key,
    required this.child,
    this.onOnline,
  });

  /// オンライン時のみ表示するコンテンツ
  final Widget child;

  /// オフライン → オンラインに切り替わった時に呼ばれるコールバック
  final VoidCallback? onOnline;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  bool _hasCheckedConnectivity = false;
  bool _isOffline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (!mounted) return;
    final offline = _isConnectivityOffline(results);
    if (_hasCheckedConnectivity && offline != _isOffline) {
      setState(() {
        _isOffline = offline;
        if (!offline) widget.onOnline?.call();
      });
    }
  }

  bool _isConnectivityOffline(List<ConnectivityResult> results) {
    return results.length == 1 && results.single == ConnectivityResult.none;
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (!mounted) return;
      setState(() {
        _hasCheckedConnectivity = true;
        _isOffline = _isConnectivityOffline(results);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasCheckedConnectivity = true;
        _isOffline = false;
      });
    }
  }

  Future<void> _onRetry() async {
    setState(() => _hasCheckedConnectivity = false);
    await _checkConnectivity();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasCheckedConnectivity) {
      return _ConnectivityCheckingView();
    }
    if (_isOffline) {
      return _OfflinePlaceholderView(
        onRetry: _onRetry,
      );
    }
    return widget.child;
  }
}

/// 接続確認中の表示
class _ConnectivityCheckingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.grey.shade100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.checkingConnectivity,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

/// オフライン時のプレースホルダー表示
class _OfflinePlaceholderView extends StatelessWidget {
  const _OfflinePlaceholderView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded,
                  size: 64, color: Colors.grey.shade400),
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
      ),
    );
  }
}

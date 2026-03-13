import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../providers/providers.dart';

/// スリープタイマーの制御を担当するクラス。
/// 指定分数後に画面を暗転し、タップで復帰させる。
class SleepTimerController {
  SleepTimerController({
    required this.overlayState,
    required this.ref,
    required bool Function() getMounted,
    required void Function(Position position, Position? previous)
        onPositionUpdate,
  })  : _getMounted = getMounted,
        _onPositionUpdate = onPositionUpdate;

  final OverlayState overlayState;
  final WidgetRef ref;
  final bool Function() _getMounted;
  final void Function(Position position, Position? previous) _onPositionUpdate;

  Timer? _timer;
  OverlayEntry? _dimOverlayEntry;
  bool _wasStreamActiveBeforeDim = false;

  /// タイマーを指定分数で再開する。0の場合はタイマーを停止する。
  void restart(int minutes) {
    _timer?.cancel();
    _timer = null;
    if (minutes > 0) {
      _timer = Timer(Duration(minutes: minutes), _dimScreen);
    }
  }

  /// タイマーを停止し、暗転中なら復帰する。
  void cancel() {
    _timer?.cancel();
    _timer = null;
    restoreBrightness();
  }

  /// 暗転を解除し、タイマーを再開する。ユーザーがタップしたときやアプリ復帰時に呼ぶ。
  void restoreBrightness() {
    if (_dimOverlayEntry == null) return;
    _dimOverlayEntry?.remove();
    _dimOverlayEntry = null;
    ScreenBrightness().resetApplicationScreenBrightness();
    if (_wasStreamActiveBeforeDim) {
      _wasStreamActiveBeforeDim = false;
      ref.read(locationStreamProvider.notifier).toggle(
            onPosition: _onPositionUpdate,
          );
    }
  }

  void _dimScreen() {
    if (!_getMounted()) return;
    Navigator.maybeOf(overlayState.context)
        ?.popUntil((route) => route is! PopupRoute);
    _wasStreamActiveBeforeDim = ref.read(locationStreamProvider).isActive;
    ScreenBrightness().setApplicationScreenBrightness(0.0);
    if (_wasStreamActiveBeforeDim) {
      ref.read(locationStreamProvider.notifier).stop();
    }
    _dimOverlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: GestureDetector(
          onTap: _onUserInteraction,
          behavior: HitTestBehavior.opaque,
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const FlutterLogo(
                      size: 120,
                      style: FlutterLogoStyle.markOnly,
                      textColor: Color(0xFF333333),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlayState.insert(_dimOverlayEntry!);
  }

  void _onUserInteraction() {
    restoreBrightness();
    restart(ref.read(sleepDurationProvider));
  }

  /// リソースを解放する。dispose 時に呼ぶ。
  void dispose() {
    _timer?.cancel();
    _timer = null;
    restoreBrightness();
  }
}

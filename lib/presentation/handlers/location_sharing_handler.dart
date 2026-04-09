import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../utils/snackbar_utils.dart';

/// 現在地の座標を Google Maps URL で共有する
Future<void> shareCurrentLocation(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  // sharePositionOrigin 用に await 前に取得（iOS share_plus v10 で必須・画面内に収める）
  final screenSize = MediaQuery.of(context).size;
  final shareOrigin = Rect.fromLTWH(
    screenSize.width / 2,
    screenSize.height / 2,
    1,
    1,
  );

  // 位置情報サービスの確認
  if (!await Geolocator.isLocationServiceEnabled()) {
    showAppSnackBarWithMessenger(messenger, l10n.locationUnavailable);
    return;
  }

  // 権限の確認・要求
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    showAppSnackBarWithMessenger(messenger, l10n.locationPermissionRequired);
    return;
  }

  final position = await _getPositionForSharing();

  if (!context.mounted) return;

  if (position == null) {
    showAppSnackBarWithMessenger(messenger, l10n.locationUnavailable);
    return;
  }

  final url = kGoogleMapsLocationUrl(position.latitude, position.longitude);
  // await しない: Share.share は share sheet が閉じるまで完了しないため
  // ローディングインジケータが share sheet 表示中に出続けるのを防ぐ
  Share.share(url, sharePositionOrigin: shareOrigin);
}

/// iOS でも確実に動作する位置取得。
/// キャッシュがあればすぐ返し、なければ getPositionStream で最初の1点を取得する。
Future<Position?> _getPositionForSharing() async {
  final last = await Geolocator.getLastKnownPosition();
  if (last != null) return last;

  final completer = Completer<Position?>();
  StreamSubscription<Position>? sub;
  Timer? timer;

  sub = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.low,
    ),
  ).listen(
    (pos) {
      if (!completer.isCompleted) completer.complete(pos);
    },
    onError: (_) {
      if (!completer.isCompleted) completer.complete(null);
    },
    cancelOnError: true,
  );

  timer = Timer(const Duration(seconds: 20), () {
    if (!completer.isCompleted) completer.complete(null);
  });

  final result = await completer.future;
  await sub.cancel();
  timer.cancel();
  return result;
}

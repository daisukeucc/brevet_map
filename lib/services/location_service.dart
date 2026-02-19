import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 現在地を取得する。許可なし・無効の場合は null。ダイアログは出さない。
Future<Position?> getCurrentPositionSilent() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }
  try {
    final lastPosition = await Geolocator.getLastKnownPosition();
    if (lastPosition != null) return lastPosition;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.medium,
    );
  } catch (_) {
    return null;
  }
}

/// 位置情報の許可を確認し、取得できたら [Position] を返す。不可の場合はダイアログを表示し null。
Future<Position?> getPositionWithPermission(
  BuildContext context, {
  required VoidCallback onOpenSettings,
  Future<void> Function(BuildContext, String title, String message,
      {String okText, VoidCallback? onOk})? showMessageDialog,
}) async {
  final showDialog = showMessageDialog ?? _showMessageDialog;

  if (!await Geolocator.isLocationServiceEnabled()) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context,
        '位置情報が無効です',
        '位置情報サービスがオフになっています。端末の設定でオンにしてください。',
        okText: '設定を開く',
        onOk: () {
          onOpenSettings();
          Geolocator.openLocationSettings();
        },
      );
    });
    return null;
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context,
        '位置情報の許可が必要です',
        '位置情報の許可が拒否されました。許可しない場合は現在地を表示できません。',
      );
    });
    return null;
  }

  if (permission == LocationPermission.deniedForever) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context,
        '位置情報の許可が必要です',
        '位置情報の許可が「今後表示しない」になっています。アプリ設定から許可をオンにしてください。',
        okText: '設定を開く',
        onOk: () {
          onOpenSettings();
          Geolocator.openAppSettings();
        },
      );
    });
    return null;
  }

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}

Future<void> _showMessageDialog(
  BuildContext context,
  String title,
  String message, {
  String okText = 'OK',
  VoidCallback? onOk,
}) async {
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onOk?.call();
          },
          child: Text(okText),
        ),
      ],
    ),
  );
}

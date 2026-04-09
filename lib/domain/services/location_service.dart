import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';

/// 現在地取得のタイムアウト（起動時・その他で待ちすぎないようにする）
const Duration _locationTimeout = Duration(seconds: 15);

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
      timeLimit: _locationTimeout,
    );
  } on TimeoutException {
    return await Geolocator.getLastKnownPosition();
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
      final l10n = AppLocalizations.of(context);
      if (l10n == null || !context.mounted) return;
      showDialog(
        context,
        l10n.locationInvalid,
        l10n.locationServiceOff,
        okText: l10n.openSettings,
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
      final l10n = AppLocalizations.of(context);
      if (l10n == null || !context.mounted) return;
      showDialog(
        context,
        l10n.locationPermissionRequired,
        l10n.locationPermissionDenied,
      );
    });
    return null;
  }

  if (permission == LocationPermission.deniedForever) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null || !context.mounted) return;
      showDialog(
        context,
        l10n.locationPermissionRequired,
        l10n.locationPermissionDeniedForever,
        okText: l10n.openSettings,
        onOk: () {
          onOpenSettings();
          Geolocator.openAppSettings();
        },
      );
    });
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _locationTimeout,
    );
  } on TimeoutException {
    // タイムアウト時はキャッシュ位置があれば返す（スプラッシュで止まらないようにする）
    return await Geolocator.getLastKnownPosition();
  }
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

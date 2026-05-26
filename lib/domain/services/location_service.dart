import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../l10n/app_localizations.dart';

/// 現在地取得のタイムアウト（起動時・その他で待ちすぎないようにする）
const Duration _locationTimeout = Duration(seconds: 15);

/// [resolvePositionForPoiCheckIn] 失敗理由（ダイアログ文言の切り替え用）。
enum PoiCheckInLocationFailReason {
  serviceOff,
  permissionDenied,
  permissionDeniedForever,
  positionUnavailable,
}

/// POI チェックイン事前確認用の位置取得結果。ダイアログは表示しない。
sealed class PoiCheckInLocationResolveResult {}

/// 現在地を取得できた。
final class PoiCheckInLocationResolved extends PoiCheckInLocationResolveResult {
  PoiCheckInLocationResolved(this.position);
  final Position position;
}

/// 現在地を取得できなかった。
final class PoiCheckInLocationFailed extends PoiCheckInLocationResolveResult {
  PoiCheckInLocationFailed(this.reason);
  final PoiCheckInLocationFailReason reason;
}

/// サービス・権限・GPS を順に確認し現在地を返す。UI は呼び出し側で表示すること。
Future<PoiCheckInLocationResolveResult> resolvePositionForPoiCheckIn() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    return PoiCheckInLocationFailed(PoiCheckInLocationFailReason.serviceOff);
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied) {
    return PoiCheckInLocationFailed(PoiCheckInLocationFailReason.permissionDenied);
  }

  if (permission == LocationPermission.deniedForever) {
    return PoiCheckInLocationFailed(
      PoiCheckInLocationFailReason.permissionDeniedForever,
    );
  }

  try {
    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: _locationTimeout,
    );
    return PoiCheckInLocationResolved(pos);
  } on TimeoutException {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return PoiCheckInLocationResolved(last);
    return PoiCheckInLocationFailed(
      PoiCheckInLocationFailReason.positionUnavailable,
    );
  } catch (_) {
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return PoiCheckInLocationResolved(last);
    return PoiCheckInLocationFailed(
      PoiCheckInLocationFailReason.positionUnavailable,
    );
  }
}

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

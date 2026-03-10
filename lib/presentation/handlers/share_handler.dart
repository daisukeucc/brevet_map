import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';

/// ルート上とみなす距離の閾値（メートル）
const double _onRouteThresholdM = 1000;

/// 共有テキスト（全言語共通・英語表記）
const String _shareSuffix = 'Powerd by Brevet Map';

/// 地図スクリーンショットの共有フローを実行する。
/// ルートがある場合は拡大表示し、ルート上（1km以内）であれば距離を含むテキストを共有する。
Future<void> showShareFlow(
  BuildContext context,
  WidgetRef ref,
  GlobalKey screenshotKey, {
  LatLng? currentPosition,
  LatLng? previousPosition,
}) async {
  final boundary = screenshotKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null || !context.mounted) return;

  try {
    // 1. ルートを拡大表示
    final mapState = ref.read(mapStateProvider);
    final routePoints = mapState.fullRoutePoints ?? mapState.savedRoutePoints;
    final bounds = routePoints != null && routePoints.isNotEmpty
        ? boundsFromPoints(routePoints)
        : null;
    if (bounds != null) {
      await ref.read(cameraControllerProvider.notifier).animateToBounds(bounds);
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!context.mounted) return;

    // 2. ルート上にいるか判定・距離取得
    final unit = ref.read(distanceUnitProvider);
    String shareText;
    if (routePoints != null &&
        routePoints.isNotEmpty &&
        currentPosition != null) {
      final pos = LatLng(currentPosition.latitude, currentPosition.longitude);
      final result = getRouteLegWithBearing(
        routePoints,
        pos,
        previousPosition: previousPosition,
      );
      if (result.toRouteM < _onRouteThresholdM) {
        final distKm = result.alongTrackM / 1000;
        final totalM = distanceAlongTrackFromStart(
          routePoints,
          routePoints.length - 1,
        );
        if (result.alongTrackM < 500) {
          shareText = 'Start!\n$_shareSuffix';
        } else if (totalM > 0 && (totalM - result.alongTrackM) < 500) {
          shareText = 'Goal!\n$_shareSuffix';
        } else {
          shareText = '${formatDistance(distKm, unit)} Now!\n$_shareSuffix';
        }
      } else {
        shareText = 'Ready to Start!\n$_shareSuffix';
      }
    } else {
      shareText = 'Ready to Start!\n$_shareSuffix';
    }

    // 3. ボタン含む複雑なシーンの描画完了を待つ
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) return;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null || !context.mounted) return;

    final tempDir = await getTemporaryDirectory();
    final fileName = 'brevet_map_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (!context.mounted) return;
    await Share.shareXFiles([XFile(file.path)], text: shareText);
  } catch (e) {
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.shareFailed);
    }
  }
}

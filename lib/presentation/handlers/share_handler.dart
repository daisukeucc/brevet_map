import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart' hide getRouteLegWithBearing;
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/hp_setup_dialog.dart';

/// ルート上とみなす距離の閾値（メートル）
const double _onRouteThresholdM = 1000;

/// スクショ撮影完了から共有吹き出しを自動で消すまでの時間。
/// 共有シート終了の検知に失敗しても残り続けないようにする。
const Duration _shareCalloutAutoHideDuration = Duration(seconds: 8);

/// 吹き出し用のメインテキストを取得する。
/// [computeAlong] はダウンサンプル済みの alongTrackM と toRouteM を返す関数。
/// [totalRouteM] はルート総距離（メートル）。
String getLocationCalloutMainText({
  required LatLng? currentPosition,
  required ({double alongTrackM, double toRouteM}) Function(LatLng)
      computeAlong,
  required double totalRouteM,
  required int unit,
}) {
  if (currentPosition == null) return '@--km';
  final result = computeAlong(currentPosition);
  if (result.toRouteM >= _onRouteThresholdM) {
    return '@--km';
  }
  final distKm = result.alongTrackM / 1000;
  if (result.alongTrackM < 500) {
    return 'Start!';
  }
  if (totalRouteM > 0 && (totalRouteM - result.alongTrackM) < 500) {
    return 'Goal!';
  }
  return '@${formatDistance(distKm, unit)}!';
}

/// 吹き出し表示用の位置とテキストを算出する。
/// isShareMode かつ 位置あり の場合のみ non-null を返す。
({LatLng? position, String? text}) computeCalloutData({
  required bool isShareMode,
  required bool hasPosition,
  required LatLng? currentPosition,
  LatLng? previousPosition,
  required ({double alongTrackM, double toRouteM}) Function(LatLng)
      computeAlong,
  required double totalRouteM,
  required int distanceUnit,
}) {
  if (!isShareMode || !hasPosition || currentPosition == null) {
    return (position: null, text: null);
  }
  return (
    position: currentPosition,
    text: getLocationCalloutMainText(
      currentPosition: currentPosition,
      computeAlong: computeAlong,
      totalRouteM: totalRouteM,
      unit: distanceUnit,
    ),
  );
}

/// 共有ボタンタップ時の処理。HP設定ダイアログ→吹き出し表示→共有フローを実行する。
Future<void> handleShareButtonTap({
  required BuildContext context,
  required WidgetRef ref,
  required GlobalKey screenshotKey,
  LatLng? currentPosition,
  LatLng? previousPosition,
  required void Function(bool isShareMode, {double? shareHp})
      onShareModeChanged,
  required bool Function() getMounted,
  void Function(double zoomBefore)? onAfterCameraAnimation,
}) async {
  final hp = await showHpSetupDialog(context);
  if (hp == null || !getMounted()) return;

  onShareModeChanged(true, shareHp: hp / 100);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showShareFlow(
      context,
      ref,
      screenshotKey,
      currentPosition: currentPosition,
      previousPosition: previousPosition,
      onAfterCameraAnimation: onAfterCameraAnimation,
      onExitShareMode: () {
        if (getMounted()) onShareModeChanged(false);
      },
    );
  });
}

/// 地図スクリーンショットの共有フローを実行する。
/// ルートがある場合は拡大表示し、ルート上（1km以内）であれば距離を含むテキストを共有する。
///
/// [onExitShareMode] は次のいずれかで呼ぶ。
/// - [Share.shareXFiles] 完了時（共有シートが閉じたあと）
/// - 撮影失敗・ファイル書き込み失敗など、共有フローを続けられないとき
/// - 撮影完了から [_shareCalloutAutoHideDuration] 経過時（タイマー）
///
/// 共有シート終了の検知に失敗しても、タイマーで吹き出しは消える。
/// [MyHomePage] の `resumed` でも共有モードを落とすフォールバックあり。
Future<void> showShareFlow(
  BuildContext context,
  WidgetRef ref,
  GlobalKey screenshotKey, {
  LatLng? currentPosition,
  LatLng? previousPosition,
  void Function(double zoomBefore)? onAfterCameraAnimation,
  required void Function() onExitShareMode,
}) async {
  var exitedShareMode = false;
  Timer? calloutAutoHideTimer;

  void ensureExitShareMode() {
    calloutAutoHideTimer?.cancel();
    calloutAutoHideTimer = null;
    if (exitedShareMode) return;
    exitedShareMode = true;
    onExitShareMode();
  }

  final boundary = screenshotKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null || !context.mounted) {
    ensureExitShareMode();
    return;
  }

  try {
    // 1. ルートを拡大表示
    final mapState = ref.read(mapStateProvider);
    final routePoints = mapState.fullRoutePoints ?? mapState.savedRoutePoints;
    final bounds = routePoints != null && routePoints.isNotEmpty
        ? boundsFromPoints(routePoints)
        : null;
    double? zoomBefore;
    if (bounds != null) {
      zoomBefore = ref.read(cameraControllerProvider)?.camera.zoom ?? 16.0;
      await ref.read(cameraControllerProvider.notifier).animateToBounds(bounds);
      // animateToBounds 後の実際のズームを savedZoomLevel に反映する（ズーム表示の更新）
      final zoomAfter = ref.read(cameraControllerProvider)?.camera.zoom;
      if (zoomAfter != null) {
        ref.read(mapStateProvider.notifier).overrideSavedZoom(zoomAfter);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!context.mounted) {
      ensureExitShareMode();
      return;
    }

    // 2. ボタン含む複雑なシーンの描画完了を待つ
    await Future.delayed(const Duration(milliseconds: 150));
    if (!context.mounted) {
      ensureExitShareMode();
      return;
    }

    // 共有用: 1.75 で画質優先（2.0 に近い鮮明さ、やや軽め）
    final image = await boundary.toImage(pixelRatio: 1.75);
    // スクリーンショット撮影後にズームを復元（GPS 位置更新での zoom 上書きを防ぐため）
    if (zoomBefore != null) onAfterCameraAnimation?.call(zoomBefore);
    // 撮影完了をトリガーに吹き出し自動解除タイマー（共有シート検知失敗時の保険）
    calloutAutoHideTimer =
        Timer(_shareCalloutAutoHideDuration, ensureExitShareMode);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    if (byteData == null || !context.mounted) {
      ensureExitShareMode();
      return;
    }

    final gpxName = await loadGpxMetadataName();
    final fileName = 'brevet_map_${DateTime.now().millisecondsSinceEpoch}.png';

    // iOS: getTemporaryDirectory() だと共有シートがファイルを読めず失敗することがあるため、
    // Documents ディレクトリを使用する（share_plus issue #263, #1088 等）
    final dir = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final shareDir = Directory('${dir.path}/share');
    if (!await shareDir.exists()) await shareDir.create(recursive: true);
    final file = File('${shareDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    if (!context.mounted) {
      ensureExitShareMode();
      return;
    }

    // iPad / iOS: sharePositionOrigin が必須の場合がある（share_plus issue #3697 等）
    final sharePositionOrigin = Platform.isIOS
        ? Rect.fromPoints(const Offset(0, 0), const Offset(1, 1))
        : null;

    await Share.shareXFiles(
      [
        XFile(
          file.path,
          mimeType: 'image/png',
          name: fileName,
        ),
      ],
      text: [
        if (gpxName != null && gpxName.trim().isNotEmpty)
          '#${gpxName.replaceAll(RegExp(r'[ 　]'), '').replaceAll('.', '_')}',
        '@BrevetMap',
      ].join('\n'),
      sharePositionOrigin: sharePositionOrigin,
    );
    ensureExitShareMode();
  } catch (e) {
    ensureExitShareMode();
    if (context.mounted) {
      showAppSnackBar(context, AppLocalizations.of(context)!.shareFailed);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/coordinates_from_url.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';
import 'poi_management_handler.dart';

/// 共有URL受信時の処理。URLをパースし、座標があれば onParsed を呼ぶ。
Future<void> handleSharedUrlReceived(
  BuildContext context,
  WidgetRef ref,
  String url, {
  required void Function(LatLng position, String? placeName) onParsed,
}) async {
  final trimmedUrl = url.trim();
  if (trimmedUrl.isEmpty) return;

  final coords = extractCoordinatesFromUrlString(trimmedUrl);
  if (!context.mounted) return;

  if (coords != null) {
    final position = LatLng(coords.lat, coords.lng);
    final placeName = extractPlaceNameFromUrlString(trimmedUrl);
    Navigator.of(context).popUntil((route) => route is! PopupRoute);
    onParsed(position, placeName);
    await ref.read(cameraControllerProvider.notifier).animateTo(
          position,
          zoom: 18.0,
        );
  } else {
    showAppSnackBar(context, AppLocalizations.of(context)!.shareUrlInvalid);
  }
}

/// 共有プレビューでPOI登録を確定したときの処理。
Future<void> handleConfirmSharePreview(
  BuildContext context,
  WidgetRef ref,
  LatLng position,
  String? placeName, {
  required void Function() onClear,
}) async {
  if (!context.mounted) return;

  onClear();

  final distanceUnit = ref.read(distanceUnitProvider);
  final routePoints = ref.read(mapStateProvider).savedRoutePoints;
  final totalRouteKm = routePoints != null && routePoints.isNotEmpty
      ? distanceAlongTrackFromStart(routePoints, routePoints.length - 1) / 1000
      : null;
  String? initialKmText;
  if (routePoints != null && routePoints.isNotEmpty) {
    final opts = alongTrackTapOptionsForPoint(routePoints, position);
    if (opts.length > 1) {
      if (!context.mounted) return;
      final picked = await showOverlappingRouteLegPickDialog(
        context,
        options: opts,
        distanceUnit: distanceUnit,
      );
      if (picked == null || !context.mounted) {
        return;
      }
      initialKmText = formatDistanceNumeric(
        opts[picked].alongTrackM / 1000,
        distanceUnit,
      );
    } else {
      initialKmText = formatDistanceNumeric(
        opts.single.alongTrackM / 1000,
        distanceUnit,
      );
    }
  }

  final brevetMeta = await loadBrevetMeta();
  if (!context.mounted) return;

  UserPoi? findPreviousPoiFor(double km) {
    final list = ref.read(mapStateProvider).userPois;
    UserPoi? prev;
    for (final p in list) {
      if (p.km != null &&
          !p.isNote &&
          p.km! < km &&
          (prev == null || p.km! > prev.km!)) {
        prev = p;
      }
    }
    return prev;
  }

  double? elevationGainFromRouteStartFor(double km) {
    final ms = ref.read(mapStateProvider);
    final pts = ms.savedRoutePoints;
    final elevs = ms.savedTrackElevations;
    if (pts == null ||
        pts.isEmpty ||
        elevs == null ||
        elevs.length != pts.length) {
      return null;
    }
    final i = trackIndexNearestAlongRouteKm(pts, km, distanceBetweenLatLng);
    return elevationGainBetweenIndices(elevs, 0, i);
  }

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (dialogContext) => AddPoiDialog(
      initialTitle: placeName,
      distanceUnit: distanceUnit,
      totalRouteKm: totalRouteKm,
      initialKmText: initialKmText,
      brevetStartTimeUtc: brevetMeta?.startTime,
      findPreviousPoi: findPreviousPoiFor,
      elevationGainFromRouteStart: elevationGainFromRouteStartFor,
      onSave: (data) async {
        final poi =
            await userPoiFromMapTapAddForm(data: data, position: position);
        await ref.read(mapStateProvider.notifier).addUserPoi(poi);
        await recalculateSchedulesAfterAdd(ref);
        if (context.mounted) {
          showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
        }
      },
    ),
  );
}

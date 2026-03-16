import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/app_constants.dart';
import '../../domain/services/location_service.dart';
import '../../l10n/app_localizations.dart';
import '../utils/snackbar_utils.dart';

/// 現在地の座標を Google Maps URL で共有する
Future<void> shareCurrentLocation(BuildContext context) async {
  final position = await getCurrentPositionSilent();

  if (!context.mounted) return;

  if (position == null) {
    showAppSnackBar(context, AppLocalizations.of(context)!.locationUnavailable);
    return;
  }

  final url = kGoogleMapsLocationUrl(position.latitude, position.longitude);
  await Share.share(url);
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';
import '../utils/snackbar_utils.dart';

/// 距離単位を変更したときのハンドラ。
Future<void> handleDistanceUnitChange(
  BuildContext context,
  WidgetRef ref,
  int unit,
) async {
  ref.read(distanceUnitProvider.notifier).state = unit;
  saveDistanceUnit(unit);
  await ref.read(mapStateProvider.notifier).refreshMarkersForUnitChange();
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final message =
      unit == 0 ? l10n.distanceUnitSetToKm : l10n.distanceUnitSetToMile;
  showAppSnackBar(context, message);
}

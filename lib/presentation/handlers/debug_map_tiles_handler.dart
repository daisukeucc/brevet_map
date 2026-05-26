import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../providers/providers.dart';

/// デバッグビルド専用: OSM 既定タイルと CARTO Voyager 系の切り替え。
void showDebugMapTilesDialog(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  showDialog<void>(
    context: context,
    builder: (ctx) {
      final cartoOn = ref.read(debugCartoVoyagerTilesEnabledProvider);
      return AlertDialog(
        title: Text(l10n.debugMapTilesDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.debugMapTilesOptionDefaultOsm),
              trailing: cartoOn ? null : const Icon(Icons.check),
              onTap: () {
                final was = ref.read(debugCartoVoyagerTilesEnabledProvider);
                ref.read(debugCartoVoyagerTilesEnabledProvider.notifier).state =
                    false;
                ref.read(debugCartoVoyagerLightProvider.notifier).state = false;
                if (was) {
                  ref.read(mapTileProviderKeyProvider.notifier).state++;
                }
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text(l10n.debugMapTilesOptionCartoVoyager),
              trailing: cartoOn ? const Icon(Icons.check) : null,
              onTap: () {
                final was = ref.read(debugCartoVoyagerTilesEnabledProvider);
                ref.read(debugCartoVoyagerTilesEnabledProvider.notifier).state =
                    true;
                if (!was) {
                  ref.read(mapTileProviderKeyProvider.notifier).state++;
                }
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.debugMapTilesDialogCancel),
          ),
        ],
      );
    },
  );
}

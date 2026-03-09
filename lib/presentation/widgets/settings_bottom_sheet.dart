import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 設定ボトムシート
class SettingsBottomSheet extends StatefulWidget {
  const SettingsBottomSheet({
    required this.onGpxImportTap,
    required this.onGpxExportTap,
    required this.onOfflineMapTap,
    required this.hasUserPois,
    required this.onAddPoiTap,
    required this.onSleepSettingsTap,
    required this.onDistanceUnitTap,
  });

  final VoidCallback onGpxImportTap;
  final VoidCallback onGpxExportTap;
  final VoidCallback onOfflineMapTap;
  final bool hasUserPois;
  final VoidCallback onAddPoiTap;
  final VoidCallback onSleepSettingsTap;
  final VoidCallback onDistanceUnitTap;

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.gpxImport,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onGpxImportTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.map, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.offlineMap,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onOfflineMapTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.add_location_alt, color: Colors.black54),
            title: Text(
              widget.hasUserPois
                  ? AppLocalizations.of(context)!.poiAddEdit
                  : AppLocalizations.of(context)!.poiAdd,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onAddPoiTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.gpxExport,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onGpxExportTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 22,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.bedtime, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.sleepSettings,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onSleepSettingsTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 20,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          ListTile(
            leading: const Icon(Icons.straighten, color: Colors.black54),
            title: Text(
              AppLocalizations.of(context)!.distanceUnit,
              style: const TextStyle(fontSize: 15),
            ),
            onTap: widget.onDistanceUnitTap,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            horizontalTitleGap: 20,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

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
    required this.onAppSettingsTap,
  });

  final VoidCallback onGpxImportTap;
  final VoidCallback onGpxExportTap;
  final VoidCallback onOfflineMapTap;
  final bool hasUserPois;
  final VoidCallback onAddPoiTap;
  final VoidCallback onSleepSettingsTap;
  final VoidCallback onAppSettingsTap;

  @override
  State<SettingsBottomSheet> createState() => _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends State<SettingsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (
        icon: Icons.download,
        label: l10n.gpxImport,
        onTap: widget.onGpxImportTap
      ),
      (icon: Icons.map, label: l10n.offlineMap, onTap: widget.onOfflineMapTap),
      (
        icon: Icons.add_location_alt,
        label: widget.hasUserPois ? l10n.poiAddEdit : l10n.poiAdd,
        onTap: widget.onAddPoiTap,
      ),
      (icon: Icons.upload, label: l10n.gpxExport, onTap: widget.onGpxExportTap),
      (
        icon: Icons.bedtime,
        label: l10n.sleepSettings,
        onTap: widget.onSleepSettingsTap
      ),
      (
        icon: Icons.settings,
        label: l10n.appSettingsTitle,
        onTap: widget.onAppSettingsTap
      ),
    ];

    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon, color: Colors.black54),
              title: Text(item.label, style: const TextStyle(fontSize: 15)),
              onTap: item.onTap,
              contentPadding: const EdgeInsets.symmetric(horizontal: 23),
              horizontalTitleGap: 20,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            ),
          ),
          const SizedBox(height: 25),
        ],
      ),
    );
  }
}

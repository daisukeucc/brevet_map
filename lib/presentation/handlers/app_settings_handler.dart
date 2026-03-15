import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 設定画面を表示する
void showAppSettingsScreen(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const _AppSettingsScreen()),
  );
}

class _AppSettingsScreen extends StatelessWidget {
  const _AppSettingsScreen();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.settings,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
        shape: const Border(),
      ),
      body: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.locationSharing),
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.aboutApp),
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.rateApp),
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.contactUs),
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.distanceUnit),
          const Divider(height: 1, thickness: 1),
          _SettingsTile(label: l10n.language),
          const Divider(height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 15)),
      trailing: const Icon(Icons.chevron_right, color: Colors.black45),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
    );
  }
}

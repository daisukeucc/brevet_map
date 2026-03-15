import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

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
    final items = [
      l10n.locationSharing,
      l10n.aboutApp,
      l10n.rateApp,
      l10n.contactUs,
      l10n.distanceUnit,
      l10n.language,
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.settings, style: AppTextStyles.title),
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
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children:
                items.map((label) => _SettingsTile(label: label)).toList(),
          ),
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
    return Column(
      children: [
        ListTile(
          title: Text(label, style: AppTextStyles.bodySmall),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}

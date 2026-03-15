import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// 設定画面を表示する
void showAppSettingsScreen(
  BuildContext context, {
  required VoidCallback onDistanceUnitTap,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          _AppSettingsScreen(onDistanceUnitTap: onDistanceUnitTap),
    ),
  );
}

class _AppSettingsScreen extends StatelessWidget {
  const _AppSettingsScreen({required this.onDistanceUnitTap});

  final VoidCallback onDistanceUnitTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (label: l10n.locationSharing, onTap: null as VoidCallback?),
      (label: l10n.aboutApp, onTap: null),
      (label: l10n.rateApp, onTap: null),
      (label: l10n.contactUs, onTap: null),
      (label: l10n.distanceUnit, onTap: onDistanceUnitTap),
      (label: l10n.language, onTap: null),
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
            children: items
                .map((item) =>
                    _SettingsTile(label: item.label, onTap: item.onTap))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(label, style: AppTextStyles.bodySmall),
          trailing: const Icon(Icons.chevron_right, color: Colors.black45),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
        ),
        const Divider(height: 1, thickness: 1),
      ],
    );
  }
}

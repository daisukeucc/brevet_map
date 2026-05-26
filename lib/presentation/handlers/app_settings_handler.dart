import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// 設定画面を表示する
void showAppSettingsScreen(
  BuildContext context, {
  required VoidCallback onDistanceUnitTap,
  required VoidCallback onLanguageTap,
  required VoidCallback onBatteryDisplayTap,
  required VoidCallback onLocationSharingTap,
  required VoidCallback onCheckInTap,
  required VoidCallback onContactUsTap,
  required VoidCallback onSubscriptionTap,
  required VoidCallback onAboutAppTap,
  VoidCallback? onDebugMapTilesTap,
}) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => _AppSettingsScreen(
        onDistanceUnitTap: onDistanceUnitTap,
        onLanguageTap: onLanguageTap,
        onBatteryDisplayTap: onBatteryDisplayTap,
        onLocationSharingTap: onLocationSharingTap,
        onCheckInTap: onCheckInTap,
        onContactUsTap: onContactUsTap,
        onSubscriptionTap: onSubscriptionTap,
        onAboutAppTap: onAboutAppTap,
        onDebugMapTilesTap: onDebugMapTilesTap,
      ),
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        )),
        child: child,
      ),
    ),
  );
}

class _AppSettingsScreen extends StatefulWidget {
  const _AppSettingsScreen({
    required this.onDistanceUnitTap,
    required this.onLanguageTap,
    required this.onBatteryDisplayTap,
    required this.onLocationSharingTap,
    required this.onCheckInTap,
    required this.onContactUsTap,
    required this.onSubscriptionTap,
    required this.onAboutAppTap,
    this.onDebugMapTilesTap,
  });

  final VoidCallback onDistanceUnitTap;
  final VoidCallback onLanguageTap;
  final VoidCallback onBatteryDisplayTap;
  final VoidCallback onLocationSharingTap;
  final VoidCallback onCheckInTap;
  final VoidCallback onContactUsTap;
  final VoidCallback onSubscriptionTap;
  final VoidCallback onAboutAppTap;
  final VoidCallback? onDebugMapTilesTap;

  @override
  State<_AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<_AppSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = [
      (label: l10n.locationSharing, onTap: widget.onLocationSharingTap),
      (label: l10n.checkInSettingsTitle, onTap: widget.onCheckInTap),
      (label: l10n.batteryLevelDisplay, onTap: widget.onBatteryDisplayTap),
      (label: l10n.distanceUnit, onTap: widget.onDistanceUnitTap),
      (label: l10n.language, onTap: widget.onLanguageTap),
      if (widget.onDebugMapTilesTap != null)
        (label: l10n.debugMapTilesMenu, onTap: widget.onDebugMapTilesTap!),
      (label: l10n.subscription, onTap: widget.onSubscriptionTap),
      (label: l10n.aboutApp, onTap: widget.onAboutAppTap),
      (label: l10n.contactUs, onTap: widget.onContactUsTap),
      // (label: l10n.rateApp, onTap: null),
    ];

    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.appSettingsTitle, style: AppTextStyles.title),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close, size: 28),
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

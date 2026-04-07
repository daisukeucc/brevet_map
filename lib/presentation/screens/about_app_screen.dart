import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../oss_licenses.dart';
import '../theme/app_text_styles.dart';

/// 「このアプリについて」画面を表示する（設定・その他から）
void showAboutAppScreen(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      pageBuilder: (_, __, ___) => const AboutAppScreen(),
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

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(l10n.aboutApp, style: AppTextStyles.title),
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
            Expanded(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        '${snapshot.error}',
                        style: AppTextStyles.bodySmall,
                      ),
                    );
                  }
                  final info = snapshot.data;
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.appTitleBrand,
                              style: AppTextStyles.headline,
                              textAlign: TextAlign.center,
                            ),
                            if (info != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${info.version} (${info.buildNumber})',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      ListTile(
                        title: Text(
                          l10n.openSourceLicenses,
                          style: AppTextStyles.bodySmall,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: Colors.black45,
                        ),
                        onTap: () => _openOssList(context),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        visualDensity: const VisualDensity(
                          horizontal: 0,
                          vertical: -2,
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openOssList(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const _OssLicensesListScreen(),
      ),
    );
  }
}

class _OssLicensesListScreen extends StatelessWidget {
  const _OssLicensesListScreen();

  static List<OssLicense> get _sorted {
    final list = List<OssLicense>.from(ossLicenses);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = _sorted;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.openSourceLicenses, style: AppTextStyles.title),
        centerTitle: true,
        shape: const Border(),
      ),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final o = items[index];
          return ListTile(
            title: Text(o.name, style: AppTextStyles.bodySmall),
            subtitle: Text(
              '${o.version} · ${o.licenseSummary}',
              style: AppTextStyles.buttonSmall,
            ),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => _OssLicenseDetailScreen(license: o),
                ),
              );
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
          );
        },
      ),
    );
  }
}

class _OssLicenseDetailScreen extends StatelessWidget {
  const _OssLicenseDetailScreen({required this.license});

  final OssLicense license;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          license.name,
          style: AppTextStyles.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        shape: const Border(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          license.licenseText,
          style: const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: Colors.black87,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

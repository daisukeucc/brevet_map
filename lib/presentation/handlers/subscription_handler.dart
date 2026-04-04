import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// 定期購入ダイアログを表示する
Future<void> showSubscriptionDialog(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();

  // アカウント情報を事前取得
  String accountId = '--';
  String expiryText = '--';
  try {
    final info = await Purchases.getCustomerInfo();
    if (!context.mounted) return;
    accountId = info.originalAppUserId;
    final entitlement = info.entitlements.active['premium'];
    if (entitlement != null) {
      final expiry = DateTime.tryParse(entitlement.expirationDate ?? '');
      if (expiry != null) {
        expiryText = DateFormat.yMMMd(locale).format(expiry.toLocal());
      }
    }
  } catch (_) {}

  if (!context.mounted) return;

  final selected = await showDialog<int>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
            child: Row(
              children: [
                Text(
                  l10n.subscriptionAccountId(
                    accountId.length > 10
                        ? '${accountId.substring(0, 10)}...'
                        : accountId,
                  ),
                  style: AppTextStyles.label,
                ),
                const SizedBox(width: 3),
                GestureDetector(
                  onTap: () =>
                      Clipboard.setData(ClipboardData(text: accountId)),
                  child: const Icon(
                    Icons.copy,
                    size: 17,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 12),
            child: Text(
              l10n.subscriptionExpiry(expiryText),
              style: AppTextStyles.label,
            ),
          ),
          ListTile(
            title: Text(l10n.restorePurchases, style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(ctx, 0),
          ),
          ListTile(
            title: Text(l10n.subscriptionTerms, style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(ctx, 1),
          ),
          ListTile(
            title: Text(l10n.manageSubscription, style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(ctx, 2),
          ),
        ],
      ),
    ),
  );

  if (selected == null) return;

  if (selected == 0) {
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black45,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await Purchases.restorePurchases();
    } catch (_) {}
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: SafeArea(
          bottom: false,
          child: Text(
            l10n.restorePurchasesSuccess,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0x99000000),
      ),
    );
    return;
  }

  final url = selected == 1
      ? kSubscriptionTermsUrl
      : (Platform.isIOS
          ? kManageSubscriptionIosUrl
          : kManageSubscriptionAndroidUrl);
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_formatting_localization.dart';
import '../../utils/string_utils.dart';
import '../theme/app_text_styles.dart';

String _billingPeriodLabel(String? iso, AppLocalizations l10n) {
  if (iso == null || iso.isEmpty) return '';
  switch (iso) {
    case 'P1W':
      return l10n.subscriptionBillingPeriodWeek;
    case 'P1M':
      return l10n.subscriptionBillingPeriodMonth;
    case 'P3M':
      return l10n.subscriptionBillingPeriodThreeMonths;
    case 'P6M':
      return l10n.subscriptionBillingPeriodSixMonths;
    case 'P1Y':
    case 'P12M':
      return l10n.subscriptionBillingPeriodYear;
    default:
      return l10n.subscriptionBillingPeriodUnknown(iso);
  }
}

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// 購読中プロダクトの [StoreProduct]（Offerings または getProducts）
Future<StoreProduct?> _storeProductForEntitlement(
  EntitlementInfo entitlement,
  List<Package> packages,
) async {
  final id = entitlement.productIdentifier;
  for (final pkg in packages) {
    if (pkg.storeProduct.identifier == id) return pkg.storeProduct;
  }
  try {
    final prods = await Purchases.getProducts([id]);
    if (prods.isNotEmpty) return prods.first;
  } catch (_) {}
  return null;
}

/// 表示名と ISO8601 請求周期（例: P1M / P1Y）。ストア取得失敗時は識別子のみ
Future<({String displayName, String? billingPeriodIso})>
    _resolvePremiumPlanInfo(
  EntitlementInfo entitlement,
  List<Package> packages,
) async {
  final id = entitlement.productIdentifier;
  final sp = await _storeProductForEntitlement(entitlement, packages);
  if (sp != null) {
    final raw = sp.title.trim();
    final name = raw.isNotEmpty ? storeProductTitleForDisplay(raw) : id;
    return (displayName: name, billingPeriodIso: sp.subscriptionPeriod);
  }
  return (displayName: id, billingPeriodIso: null);
}

/// 月額／年額などユーザー向けの請求単位ラベル（[StoreProduct.subscriptionPeriod] 用）
String? _billingUnitLabel(String? iso, AppLocalizations l10n) {
  if (iso == null || iso.isEmpty) return null;
  switch (iso) {
    case 'P1W':
      return l10n.subscriptionUnitWeekly;
    case 'P1M':
      return l10n.subscriptionUnitMonthly;
    case 'P1Y':
    case 'P12M':
      return l10n.subscriptionUnitYearly;
    default:
      return _billingPeriodLabel(iso, l10n);
  }
}

/// [Offering.availablePackages] は iOS などで同一ストア商品を複数の [Package] として
/// 返すことがある（パッケージ識別子は異なるが [StoreProduct.identifier] は同じ）。
/// 「プランと価格」一覧ではストア商品 ID ごとに 1 行にまとめる。
List<Package> _deduplicatePackagesByStoreProductId(List<Package> packages) {
  final seen = <String>{};
  final out = <Package>[];
  for (final pkg in packages) {
    final id = pkg.storeProduct.identifier;
    if (seen.add(id)) {
      out.add(pkg);
    }
  }
  return out;
}

/// 定期購入ダイアログを表示する（プラン・価格・規約リンクを含む）
/// メニュー項目のタップでは閉じず、閉じるボタンのみで閉じる。
Future<void> showSubscriptionDialog(BuildContext context) async {
  await ensureDateFormattingInitialized();
  if (!context.mounted) return;

  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();

  String accountId = '--';
  EntitlementInfo? premiumEntitlement;
  var offeringsFailed = false;
  var packages = <Package>[];

  try {
    final info = await Purchases.getCustomerInfo();
    if (!context.mounted) return;
    accountId = info.originalAppUserId;
    premiumEntitlement = info.entitlements.active['premium'];
  } catch (_) {}

  try {
    final offerings = await Purchases.getOfferings();
    if (!context.mounted) return;
    final current = offerings.current;
    if (current != null && current.availablePackages.isNotEmpty) {
      packages = List<Package>.from(current.availablePackages);
    } else {
      for (final o in offerings.all.values) {
        if (o.availablePackages.isNotEmpty) {
          packages = List<Package>.from(o.availablePackages);
          break;
        }
      }
    }
  } catch (_) {
    offeringsFailed = true;
  }

  packages = _deduplicatePackagesByStoreProductId(packages);

  if (!context.mounted) return;

  String? initialPremiumPlanName;
  String? initialBillingPeriodIso;
  if (premiumEntitlement != null) {
    final info = await _resolvePremiumPlanInfo(premiumEntitlement, packages);
    initialPremiumPlanName = info.displayName;
    initialBillingPeriodIso = info.billingPeriodIso;
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _SubscriptionDialog(
      messenger: ScaffoldMessenger.of(context),
      l10n: l10n,
      locale: locale,
      initialAccountId: accountId,
      initialPremiumEntitlement: premiumEntitlement,
      initialPremiumPlanDisplayName: initialPremiumPlanName,
      initialPremiumBillingPeriodIso: initialBillingPeriodIso,
      packages: packages,
      offeringsFailed: offeringsFailed,
    ),
  );
}

class _SubscriptionDialog extends StatefulWidget {
  const _SubscriptionDialog({
    required this.messenger,
    required this.l10n,
    required this.locale,
    required this.initialAccountId,
    required this.initialPremiumEntitlement,
    required this.initialPremiumPlanDisplayName,
    required this.initialPremiumBillingPeriodIso,
    required this.packages,
    required this.offeringsFailed,
  });

  final ScaffoldMessengerState messenger;
  final AppLocalizations l10n;
  final String locale;
  final String initialAccountId;
  final EntitlementInfo? initialPremiumEntitlement;

  /// ストアのローカライズ済み商品名（取得済みのとき）
  final String? initialPremiumPlanDisplayName;

  /// [StoreProduct.subscriptionPeriod]（例: P1M, P1Y）
  final String? initialPremiumBillingPeriodIso;
  final List<Package> packages;
  final bool offeringsFailed;

  @override
  State<_SubscriptionDialog> createState() => _SubscriptionDialogState();
}

class _SubscriptionDialogState extends State<_SubscriptionDialog> {
  /// 定期購入メニュー行の縦方向を詰める
  static const _menuTileStyle = VisualDensity(horizontal: 0, vertical: -3);

  late String _accountId;
  EntitlementInfo? _premiumEntitlement;
  String? _premiumPlanDisplayName;
  String? _premiumBillingPeriodIso;
  var _restoreBusy = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.initialAccountId;
    _premiumEntitlement = widget.initialPremiumEntitlement;
    _premiumPlanDisplayName = widget.initialPremiumPlanDisplayName;
    _premiumBillingPeriodIso = widget.initialPremiumBillingPeriodIso;
  }

  Future<void> _refreshCustomerInfo() async {
    try {
      final info = await Purchases.getCustomerInfo();
      if (!mounted) return;
      final ent = info.entitlements.active['premium'];
      String? planName;
      String? billingIso;
      if (ent != null) {
        final resolved = await _resolvePremiumPlanInfo(ent, widget.packages);
        planName = resolved.displayName;
        billingIso = resolved.billingPeriodIso;
      }
      setState(() {
        _accountId = info.originalAppUserId;
        _premiumEntitlement = ent;
        _premiumPlanDisplayName = planName;
        _premiumBillingPeriodIso = billingIso;
      });
    } catch (_) {}
  }

  Future<void> _onRestorePurchases() async {
    if (_restoreBusy) return;
    setState(() => _restoreBusy = true);
    try {
      await Purchases.restorePurchases();
      await _refreshCustomerInfo();
      if (!mounted) return;
      widget.messenger.showSnackBar(
        SnackBar(
          content: SafeArea(
            bottom: false,
            child: Text(
              widget.l10n.restorePurchasesSuccess,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          backgroundColor: const Color(0x99000000),
        ),
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _restoreBusy = false);
    }
  }

  Future<void> _onOpenPaywall() async {
    await RevenueCatUI.presentPaywall();
    if (!mounted) return;
    await _refreshCustomerInfo();
  }

  String _expiryLine(AppLocalizations l10n) {
    if (_premiumEntitlement != null) {
      final raw = _premiumEntitlement!.expirationDate;
      if (raw != null && raw.isNotEmpty) {
        final dt = DateTime.tryParse(raw);
        return dt != null
            ? l10n.subscriptionExpiry(
                DateFormat.yMMMd(widget.locale).format(dt.toLocal()),
              )
            : l10n.subscriptionExpiryNoDate;
      }
      return l10n.subscriptionExpiryNoDate;
    }
    return l10n.subscriptionNotActive;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final expiryLine = _expiryLine(l10n);
    final premiumBillingUnit =
        _billingUnitLabel(_premiumBillingPeriodIso, l10n);

    final planWidgets = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 5, 24, 8),
        child: Text(
          l10n.subscriptionAvailablePlans,
          style: AppTextStyles.bodySmall,
        ),
      ),
    ];

    if (widget.offeringsFailed) {
      planWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.subscriptionPlansLoadError,
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    } else if (widget.packages.isEmpty) {
      planWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.subscriptionPlansNotConfigured,
            style: AppTextStyles.bodySmall,
          ),
        ),
      );
    } else {
      for (final pkg in widget.packages) {
        final p = pkg.storeProduct;
        final periodLabel = _billingPeriodLabel(p.subscriptionPeriod, l10n);
        final suffix =
            periodLabel.isEmpty ? '' : l10n.subscriptionPeriodPart(periodLabel);
        planWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text(
              l10n.subscriptionPlanRow(
                storeProductTitleForDisplay(p.title),
                p.priceString,
                suffix,
              ),
              style: AppTextStyles.bodySmall.copyWith(height: 1.35),
            ),
          ),
        );
      }
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          title: Text(l10n.subscription, style: AppTextStyles.title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.subscriptionPremiumBlurb,
                    style: AppTextStyles.bodySmall.copyWith(height: 1.65),
                  ),
                  const SizedBox(height: 14),
                  if (_premiumEntitlement != null) ...[
                    Text(
                      l10n.subscriptionCurrentPlan(
                        (_premiumPlanDisplayName != null &&
                                _premiumPlanDisplayName!.isNotEmpty)
                            ? _premiumPlanDisplayName!
                            : _premiumEntitlement!.productIdentifier,
                      ),
                      style: AppTextStyles.bodySmall,
                    ),
                    if (premiumBillingUnit != null &&
                        premiumBillingUnit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.subscriptionPlanBillingUnit(premiumBillingUnit),
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 6),
                  ],
                  Text(expiryLine, style: AppTextStyles.bodySmall),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...planWidgets,
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.subscriptionAccountId(
                              _accountId.length > 14
                                  ? '${_accountId.substring(0, 14)}...'
                                  : _accountId,
                            ),
                            style: AppTextStyles.bodySmall,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Clipboard.setData(
                            ClipboardData(text: _accountId),
                          ),
                          child: const Icon(
                            Icons.copy,
                            size: 17,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(height: 1),
                  const SizedBox(height: 15),
                  ListTile(
                    dense: true,
                    visualDensity: _menuTileStyle,
                    minVerticalPadding: 0,
                    title: Text(
                      l10n.subscriptionOpenPaywall,
                      style: AppTextStyles.label,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onTap: _onOpenPaywall,
                  ),
                  ListTile(
                    dense: true,
                    visualDensity: _menuTileStyle,
                    minVerticalPadding: 0,
                    title:
                        Text(l10n.restorePurchases, style: AppTextStyles.label),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onTap: _restoreBusy ? null : _onRestorePurchases,
                  ),
                  ListTile(
                    dense: true,
                    visualDensity: _menuTileStyle,
                    minVerticalPadding: 0,
                    title: Text(l10n.linkPrivacyPolicy,
                        style: AppTextStyles.label),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onTap: () => _openUrl(kPrivacyPolicyUrl),
                  ),
                  ListTile(
                    dense: true,
                    visualDensity: _menuTileStyle,
                    minVerticalPadding: 0,
                    title:
                        Text(l10n.linkTermsOfUse, style: AppTextStyles.label),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onTap: () => _openUrl(kTermsOfUseUrl),
                  ),
                  ListTile(
                    dense: true,
                    visualDensity: _menuTileStyle,
                    minVerticalPadding: 0,
                    title: Text(l10n.manageSubscription,
                        style: AppTextStyles.label),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onTap: () {
                      final url = Platform.isIOS
                          ? kManageSubscriptionIosUrl
                          : kManageSubscriptionAndroidUrl;
                      _openUrl(url);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.trialInfoClose, style: AppTextStyles.button),
            ),
          ],
        ),
        if (_restoreBusy)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black26,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}

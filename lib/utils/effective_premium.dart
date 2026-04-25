import 'package:package_info_plus/package_info_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';

String _versionBuildId(String version, String buildNumber) =>
    '$version+$buildNumber';

/// 現在のバイナリが [kAppVersionsWithFullFeatureUnlock] に含まれるか
///（[package_info_plus] の `version` + `buildNumber` が [pubspec] の `+` 右左と一致すること）。
Future<bool> isFullFeatureUnlockByAppVersion() async {
  if (kAppVersionsWithFullFeatureUnlock.isEmpty) return false;
  try {
    final info = await PackageInfo.fromPlatform();
    return kAppVersionsWithFullFeatureUnlock
        .contains(_versionBuildId(info.version, info.buildNumber));
  } catch (_) {
    return false;
  }
}

/// 実効プレミアム: 上記全開放の対象ビルド **または** RevenueCat `premium` エンタイトルメント。
/// POI 編集制限など課金ゲートの判定に使う。
Future<bool> isEffectivePremium() async {
  if (await isFullFeatureUnlockByAppVersion()) {
    return true;
  }
  try {
    final customer = await Purchases.getCustomerInfo();
    return customer.entitlements.active.containsKey('premium');
  } catch (_) {
    return false;
  }
}

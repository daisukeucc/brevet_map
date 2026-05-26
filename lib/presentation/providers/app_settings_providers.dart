import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面スリープ設定。true=ON（端末スリープに従う）、false=OFF（WakeLockでスリープしない）
final screenSleepProvider = StateProvider<bool>((ref) => true);

/// 距離単位。0=km, 1=mile
final distanceUnitProvider = StateProvider<int>((ref) => 0);

/// ロケール。null=システム設定に従う
final localeProvider = StateProvider<Locale?>((ref) => null);

/// バッテリー残量表示。true=表示、false=非表示（デフォルト）
final batteryDisplayProvider = StateProvider<bool>((ref) => false);

/// チェックイン時に位置情報で距離を検証する。true=検証する（既定）、false=確認のみ
final checkInVerifyLocationProvider = StateProvider<bool>((ref) => true);

/// main() で事前ロードした初回起動フラグ。ProviderScope.overrides で上書きして使用する。
/// これにより initState() での非同期待ちを排除し、スプラッシュの固着を防ぐ。
final cachedFirstLaunchProvider = Provider<bool>((ref) => false);

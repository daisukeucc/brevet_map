import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面スリープ設定。true=ON（端末スリープに従う）、false=OFF（WakeLockでスリープしない）
final screenSleepProvider = StateProvider<bool>((ref) => true);

/// 距離単位。0=km, 1=mile
final distanceUnitProvider = StateProvider<int>((ref) => 0);

/// ロケール。null=システム設定に従う
final localeProvider = StateProvider<Locale?>((ref) => null);

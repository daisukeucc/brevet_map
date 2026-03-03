import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面スリープまでの時間（分）。0=OFF、1/5/10=N分後にスリープ
final sleepDurationProvider = StateProvider<int>((ref) => 0);

/// 距離単位。0=km, 1=mile
final distanceUnitProvider = StateProvider<int>((ref) => 0);

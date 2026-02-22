import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:battery_plus/battery_plus.dart';

/// 画面上部中央用。白背景・Font Awesome 5 のバッテリーアイコン＋「50%」テキスト。他アイコンと同じ blueGrey。
class BatteryIndicator extends StatefulWidget {
  const BatteryIndicator({super.key});

  @override
  State<BatteryIndicator> createState() => _BatteryIndicatorState();
}

class _BatteryIndicatorState extends State<BatteryIndicator> {
  final Battery _battery = Battery();
  int? _level;
  StreamSubscription<BatteryState>? _subscription;
  Timer? _timer;

  static IconData _iconForLevel(int level) {
    if (level >= 75) return FontAwesomeIcons.batteryFull;
    if (level >= 50) return FontAwesomeIcons.batteryThreeQuarters;
    if (level >= 25) return FontAwesomeIcons.batteryHalf;
    if (level >= 10) return FontAwesomeIcons.batteryQuarter;
    return FontAwesomeIcons.batteryEmpty;
  }

  Future<void> _refresh() async {
    try {
      final level = await _battery.batteryLevel;
      if (mounted) setState(() => _level = level);
    } catch (_) {
      if (mounted) setState(() => _level = null);
    }
  }

  @override
  void initState() {
    super.initState();
    _refresh();
    _subscription = _battery.onBatteryStateChanged.listen((_) => _refresh());
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const color = Colors.blueGrey;

    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              _level != null
                  ? _iconForLevel(_level!)
                  : FontAwesomeIcons.batteryEmpty,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 5),
            Text(
              _level != null ? '$_level%' : '--%',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

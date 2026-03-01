import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// 地図モード切替ボタン（左上の丸ボタン）。0=通常, 2=ダーク
class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    super.key,
    required this.mapStyleMode,
    required this.onTap,
  });

  final int mapStyleMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = mapStyleMode == 2;
    final message = isDark ? '地図を通常表示' : '地図をダーク表示';
    final backgroundColor = isDark ? Colors.blueGrey : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.blueGrey;
    final shadowColor = Colors.black26;

    return Tooltip(
      message: message,
      child: Material(
        color: backgroundColor,
        elevation: 5,
        shadowColor: shadowColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -2),
                child: FaIcon(
                  FontAwesomeIcons.mapMarkedAlt,
                  color: iconColor,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

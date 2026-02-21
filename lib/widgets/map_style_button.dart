import 'package:flutter/material.dart';

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
    final icon = isDark ? Icons.color_lens : Icons.dark_mode;

    return Tooltip(
      message: message,
      child: Material(
        color: Colors.white,
        elevation: 5,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 60,
            height: 60,
            child: Icon(icon, color: Colors.black87, size: 32),
          ),
        ),
      ),
    );
  }
}

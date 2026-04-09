import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final message = isDark ? l10n.mapStyleNormal : l10n.mapStyleDark;
    final backgroundColor = isDark ? Colors.blueGrey : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.blueGrey;
    const shadowColor = Colors.black26;

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
              child: Icon(
                Icons.map,
                color: iconColor,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

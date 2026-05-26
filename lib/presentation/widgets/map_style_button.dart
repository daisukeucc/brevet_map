import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// 地図モード切替ボタン（左上の丸ボタン）。0=通常, 2=ダーク
///
/// [debugCartoVoyagerActive] が true のとき（kDebugMode で CARTO プレビュー中）、
/// Voyager / light_all のトグル表示に切り替わる。
class MapStyleButton extends StatelessWidget {
  const MapStyleButton({
    super.key,
    required this.mapStyleMode,
    required this.onTap,
    this.debugCartoVoyagerActive = false,
    this.debugCartoLight = false,
  });

  final int mapStyleMode;
  final VoidCallback onTap;
  final bool debugCartoVoyagerActive;
  final bool debugCartoLight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool useAlternateChrome;
    final String message;
    if (debugCartoVoyagerActive) {
      useAlternateChrome = debugCartoLight;
      message = useAlternateChrome
          ? l10n.mapStyleDebugCartoVoyager
          : l10n.mapStyleDebugCartoLight;
    } else {
      useAlternateChrome = mapStyleMode == 2;
      message = useAlternateChrome ? l10n.mapStyleNormal : l10n.mapStyleDark;
    }
    final isDark = useAlternateChrome;
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

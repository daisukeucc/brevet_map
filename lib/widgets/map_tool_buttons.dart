import 'package:flutter/material.dart';

/// 地図上のツールボタン群
class MapToolButtons extends StatelessWidget {
  const MapToolButtons({
    super.key,
    required this.onRouteBoundsTap,
  });

  final VoidCallback onRouteBoundsTap;

  @override
  Widget build(BuildContext context) {
    return _CircleIconButton(
      tooltip: 'ルート全体を表示',
      icon: Icons.zoom_out_map,
      onTap: onRouteBoundsTap,
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
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
            child: Icon(icon, color: Colors.blueGrey, size: 32),
          ),
        ),
      ),
    );
  }
}

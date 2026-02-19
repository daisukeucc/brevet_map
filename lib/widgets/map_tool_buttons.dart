import 'package:flutter/material.dart';

/// 地図上のツールボタン群（右上）：ルート全体表示・現在地表示
class MapToolButtons extends StatelessWidget {
  const MapToolButtons({
    super.key,
    required this.onRouteBoundsTap,
    required this.onMyLocationTap,
    this.showMyLocationButton = true,
  });

  final VoidCallback onRouteBoundsTap;
  final VoidCallback onMyLocationTap;
  final bool showMyLocationButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleIconButton(
          tooltip: 'ルート全体を表示',
          icon: Icons.zoom_out_map,
          onTap: onRouteBoundsTap,
        ),
        if (showMyLocationButton) ...[
          const SizedBox(height: 12),
          _CircleIconButton(
            tooltip: '現在地を表示',
            icon: Icons.my_location,
            onTap: onMyLocationTap,
          ),
        ],
      ],
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
            width: 44,
            height: 44,
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
        ),
      ),
    );
  }
}

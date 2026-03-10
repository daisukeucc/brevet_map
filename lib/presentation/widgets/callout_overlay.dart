import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'location_callout.dart';

/// 吹き出しを画面上の適切な位置にオーバーレイ表示。端に隠れないよう配置を調整する。
class CalloutOverlay extends StatelessWidget {
  const CalloutOverlay({
    super.key,
    required this.position,
    required this.text,
  });

  final LatLng position;
  final String text;

  static const _padding = 12.0;
  static const _calloutWidth = 140.0;
  static const _calloutHeight = 90.0;
  static const _tailGap = 8.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Builder(
        builder: (context) {
          final camera = MapCamera.of(context);
          return LayoutBuilder(
            builder: (context, constraints) {
              final viewSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              final pointOffset =
                  camera.latLngToScreenOffset(position);

            // デフォルト: ポイントの上に表示（しっぽは下向き）
            var top = pointOffset.dy - _calloutHeight - _tailGap;
            var left = pointOffset.dx - _calloutWidth / 2;
            var tailAtTop = false;

            // 上端に近い場合はポイントの下に表示
            if (top < _padding) {
              top = pointOffset.dy + _tailGap;
              tailAtTop = true;
            }
            // 下端に近い場合はポイントの上に表示（デフォルトのまま）
            if (top + _calloutHeight > viewSize.height - _padding) {
              top = viewSize.height - _calloutHeight - _padding;
            }
            if (tailAtTop && top < pointOffset.dy) {
              tailAtTop = false;
              top = pointOffset.dy - _calloutHeight - _tailGap;
            }

            // 左右のクランプ
            left = left.clamp(
              _padding,
              viewSize.width - _calloutWidth - _padding,
            );

            // しっぽの先端を現在地に向ける（吹き出し左端からの相対 X）
            final tailCenterX = pointOffset.dx - left;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: left,
                  top: top.clamp(
                    _padding,
                    viewSize.height - _calloutHeight - _padding,
                  ),
                  child: LocationCallout(
                    mainText: text,
                    tailAtTop: tailAtTop,
                    tailCenterX: tailCenterX,
                  ),
                ),
              ],
            );
            },
          );
        },
      ),
    );
  }
}

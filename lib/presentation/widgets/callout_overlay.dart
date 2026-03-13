import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'location_callout.dart';

/// ルートから1km以上離れている場合
const String _readyToStartText = '@--km';

/// 吹き出しを画面上の適切な位置にオーバーレイ表示。端に隠れないよう配置を調整する。
class CalloutOverlay extends StatelessWidget {
  const CalloutOverlay({
    super.key,
    required this.position,
    required this.text,
    this.hp,
  });

  final LatLng position;
  final String text;

  /// 0.0〜1.0 のHP値。null のときゲージ非表示
  final double? hp;

  static const _padding = 12.0;
  static const _bottomPadding = 12.0;
  static const _calloutWidth = 140.0;
  static const _calloutHeight = 130.0;
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

              double left;
              double top;
              bool tailAtTop;
              double tailCenterX;

              if (text == _readyToStartText) {
                // ルートから1km以上離れている場合: 地図の中央に表示
                left = (viewSize.width - _calloutWidth) / 2;
                top = (viewSize.height - _calloutHeight) / 2;
                tailAtTop = false;
                tailCenterX = _calloutWidth / 2;
              } else {
                final pointOffset = camera.latLngToScreenOffset(position);

                // デフォルト: ポイントの上に表示（しっぽは下向き）
                top = pointOffset.dy - _calloutHeight - _tailGap;
                left = pointOffset.dx - _calloutWidth / 2;
                tailAtTop = false;

                // 上端に近い場合はポイントの下に表示
                if (top < _padding) {
                  top = pointOffset.dy + _tailGap;
                  tailAtTop = true;
                }
                // 下端に近い場合はポイントの上に表示（デフォルトのまま）
                if (top + _calloutHeight > viewSize.height - _bottomPadding) {
                  top = viewSize.height - _calloutHeight - _bottomPadding;
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
                tailCenterX = pointOffset.dx - left;
              }

              final callout = LocationCallout(
                mainText: text,
                tailAtTop: tailAtTop,
                tailCenterX: tailCenterX,
                hp: hp,
              );

              if (text == _readyToStartText) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: const Alignment(0.0, 0.05),
                        child: callout,
                      ),
                    ),
                  ],
                );
              }

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left,
                    top: top.clamp(
                      _padding,
                      viewSize.height - _calloutHeight - _bottomPadding,
                    ),
                    child: callout,
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

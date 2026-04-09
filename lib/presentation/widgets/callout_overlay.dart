import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'location_callout.dart';

/// ルートから1km以上離れている場合
const String _readyToStartText = '@--km';

/// 吹き出しを画面上の適切な位置にオーバーレイ表示。端に隠れないよう配置を調整する。
/// FlutterMap の外側の Stack に配置できるよう [mapController] を使って座標変換する。
class CalloutOverlay extends StatelessWidget {
  const CalloutOverlay({
    super.key,
    required this.mapController,
    required this.position,
    required this.text,
    this.hp,
  });

  final MapController mapController;
  final LatLng position;
  final String text;

  /// 0.0〜1.0 のHP値。null のときゲージ非表示
  final double? hp;

  static const _padding = 12.0;
  static const _bottomPadding = 12.0;
  static const _calloutWidth = 140.0;

  /// 吹き出しが画面上端に近いか判定するための推定高さ（正確な描画高さ不要）
  static const _calloutHeightEstimate = 100.0;

  /// しっぽ先端とアイコン中心の間隔
  static const _tailGap = 4.0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: StreamBuilder<MapEvent>(
        stream: mapController.mapEventStream,
        builder: (context, _) {
          MapCamera camera;
          try {
            camera = mapController.camera;
          } catch (_) {
            return const SizedBox.shrink();
          }
          return LayoutBuilder(
            builder: (context, constraints) {
              final viewSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              if (text == _readyToStartText) {
                // ルートから1km以上離れている場合: 地図の中央に表示
                final callout = LocationCallout(
                  mainText: text,
                  tailAtTop: false,
                  tailCenterX: _calloutWidth / 2,
                  hp: hp,
                );
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

              final pointOffset = camera.latLngToScreenOffset(position);

              // 上端に近い場合はポイントの下に表示（しっぽ上向き）
              final tailAtTop =
                  pointOffset.dy - _calloutHeightEstimate - _tailGap < _padding;

              // 左右のクランプ
              final left = (pointOffset.dx - _calloutWidth / 2).clamp(
                _padding,
                viewSize.width - _calloutWidth - _padding,
              );

              // しっぽの先端を現在地に向ける（吹き出し左端からの相対 X）
              final tailCenterX = pointOffset.dx - left;

              final callout = LocationCallout(
                mainText: text,
                tailAtTop: tailAtTop,
                tailCenterX: tailCenterX,
                hp: hp,
              );

              if (tailAtTop) {
                // アイコン下に配置: top 起点
                final top = (pointOffset.dy + _tailGap).clamp(
                  _padding,
                  viewSize.height - _calloutHeightEstimate - _bottomPadding,
                );
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: left,
                      top: top,
                      width: _calloutWidth,
                      child: callout,
                    ),
                  ],
                );
              }

              // アイコン上に配置: bottom 起点にすることで実際の描画高さに依存せずしっぽ先端がアイコンに合う
              final bottom = (viewSize.height - pointOffset.dy + _tailGap)
                  .clamp(_bottomPadding, viewSize.height - _padding);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left,
                    bottom: bottom,
                    width: _calloutWidth,
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


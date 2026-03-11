import 'package:flutter/material.dart';

/// HP（体力）ゲージ。吹き出し内・ダイアログで使用。
class HpGauge extends StatelessWidget {
  const HpGauge({
    super.key,
    required this.value,
    this.width = 100,
    this.height = 12,
    this.labelGap = 6,
    this.borderWidth = 1.5,
    this.labelFontSize,
    this.labelOnTop = false,
  });

  /// 0.0〜1.0 のHP値
  final double value;

  final double width;
  final double height;

  /// HPラベルとゲージの間隔（labelOnTop 時は縦方向、それ以外は横方向）
  final double labelGap;

  /// HPラベルをゲージの上に配置するか。false のとき左横（吹き出し用）
  final bool labelOnTop;

  /// 枠線の太さ
  final double borderWidth;

  /// HPラベルのフォントサイズ。null のとき 10
  final double? labelFontSize;

  static const _red = Color(0xFFEF5350);
  static const _yellow = Color(0xFFFDD835);
  static const _limeGreen = Color(0xFF8BC34A);
  static const _darkGray = Color(0xFF424242);
  static const _darkGrayBorder = Color(0xFF616161);

  Color _colorForValue(double v) {
    if (v <= 0.25) return _red;
    if (v <= 0.70) return _yellow;
    return _limeGreen;
  }

  static Widget _buildHpLabel(double? fontSize) => Text(
        'HP',
        style: TextStyle(
          fontSize: fontSize ?? 10,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fillWidth = (value.clamp(0.0, 1.0) * width).ceilToDouble();
    final labelW = labelFontSize != null ? labelFontSize! * 1.5 : 22.0;
    final gauge = Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _darkGray,
              border: Border.all(color: _darkGrayBorder, width: borderWidth),
              borderRadius: BorderRadius.zero,
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                if (fillWidth > 0)
                  Container(
                    width: fillWidth,
                    height: height,
                    color: _colorForValue(value),
                  ),
              ],
            ),
          );

    if (labelOnTop) {
      return SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHpLabel(labelFontSize),
            SizedBox(height: labelGap),
            gauge,
          ],
        ),
      );
    }

    return SizedBox(
      width: width + labelW + labelGap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHpLabel(labelFontSize),
          SizedBox(width: labelGap),
          gauge,
        ],
      ),
    );
  }
}

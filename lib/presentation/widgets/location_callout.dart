import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hp_gauge.dart';

String _formatDateTime(DateTime dateTime, String locale) {
  if (locale.startsWith('zh')) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
  if (locale.startsWith('de')) {
    return DateFormat('dd.MM.yyyy HH:mm').format(dateTime);
  }
  if (locale.startsWith('es')) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
  return DateFormat.yMd(locale).add_jm().format(dateTime);
}

/// 現在地に向かって表示する吹き出し。Nkm Now! と Powered by Brevet Map を表示。
class LocationCallout extends StatelessWidget {
  const LocationCallout({
    super.key,
    required this.mainText,
    this.tailAtTop = false,
    this.tailCenterX,
    this.hp,
  });

  /// メイン表示文言（Start!, Goal!, Nkm Now!, Ready to Start! 等）
  final String mainText;

  /// true のとき三角形のしっぽを上側に描画（吹き出しをポイントの下に表示する場合）
  final bool tailAtTop;

  /// しっぽの先端が指す X 位置（吹き出し左端からの相対）。null のとき中央
  final double? tailCenterX;

  /// 0.0〜1.0 のHP値。null のときゲージを非表示
  final double? hp;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CalloutBubblePainter(
        tailAtTop: tailAtTop,
        tailCenterX: tailCenterX,
      ),
      child: Padding(
        padding: tailAtTop
            ? const EdgeInsets.fromLTRB(20, 30, 20, 20)
            : const EdgeInsets.fromLTRB(20, 10, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _formatDateTime(DateTime.now(),
                  Localizations.localeOf(context).toString()),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mainText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (hp != null) ...[
              const SizedBox(height: 2),
              HpGauge(
                value: hp!,
                width: 80,
                height: 7,
                labelGap: 3,
                borderWidth: 1.0,
              ),
            ],
            const SizedBox(height: 4),
            const Text(
              'Powered by',
              style: TextStyle(
                fontSize: 10,
                color: Colors.black54,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -2),
              child: const Text(
                'Brevet Map',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 吹き出し（角丸四角＋三角形のしっぽ）を描画
class _CalloutBubblePainter extends CustomPainter {
  const _CalloutBubblePainter({
    this.tailAtTop = false,
    this.tailCenterX,
  });

  final bool tailAtTop;
  final double? tailCenterX;

  @override
  void paint(Canvas canvas, Size size) {
    const radius = 12.0;
    const tailWidth = 10.0;
    const tailHeight = 20.0;

    final cx = tailCenterX ?? size.width / 2;
    final centerX = cx.clamp(tailWidth / 2, size.width - tailWidth / 2);

    ui.Rect rect;
    Path tailPath;
    if (tailAtTop) {
      rect =
          ui.Rect.fromLTWH(0, tailHeight, size.width, size.height - tailHeight);
      tailPath = Path()
        ..moveTo(centerX - tailWidth / 2, tailHeight)
        ..lineTo(centerX, 0)
        ..lineTo(centerX + tailWidth / 2, tailHeight)
        ..close();
    } else {
      rect = ui.Rect.fromLTWH(0, 0, size.width, size.height - tailHeight);
      tailPath = Path()
        ..moveTo(centerX - tailWidth / 2, size.height - tailHeight)
        ..lineTo(centerX, size.height)
        ..lineTo(centerX + tailWidth / 2, size.height - tailHeight)
        ..close();
    }
    final rrect = ui.RRect.fromRectAndRadius(
      rect,
      const Radius.circular(radius),
    );

    // Union で統合し、しっぽと吹き出しの境界線を消す
    final rrectPath = Path()..addRRect(rrect);
    final path = Path.combine(ui.PathOperation.union, rrectPath, tailPath);

    canvas.drawShadow(path, Colors.black38, 4, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _CalloutBubblePainter oldDelegate) =>
      tailAtTop != oldDelegate.tailAtTop ||
      tailCenterX != oldDelegate.tailCenterX;
}

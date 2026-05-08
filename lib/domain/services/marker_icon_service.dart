import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/user_poi.dart';

/// 角丸の正方形マーカー（スタート・ゴール用）
Future<Widget> createRoundedSquareMarkerIcon({
  required Color backgroundColor,
  required bool isPlayIcon,
}) async {
  const size = 106.0;
  const radius = 31.0;
  const borderWidth = 6.0;
  const pixelRatio = 2.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..clipRect(const Rect.fromLTWH(0, 0, size, size));

  final outerRrect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(0, 0, size, size),
    const Radius.circular(radius),
  );
  final innerRadius = (radius - borderWidth).clamp(0.0, double.infinity);
  final innerRrect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(borderWidth, borderWidth, size - borderWidth * 2,
        size - borderWidth * 2),
    Radius.circular(innerRadius),
  );
  canvas.drawRRect(outerRrect, Paint()..color = Colors.white);
  canvas.drawRRect(innerRrect, Paint()..color = backgroundColor);

  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  const cx = size / 2;
  const cy = size / 2;

  if (isPlayIcon) {
    const halfH = 20.0;
    const rightExtent = 18.0;
    final path = Path()
      ..moveTo(cx - rightExtent, cy - halfH)
      ..lineTo(cx - rightExtent, cy + halfH)
      ..lineTo(cx + rightExtent, cy)
      ..close();
    canvas.drawPath(path, iconPaint);
  } else {
    const iconSize = 35.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(
            cx - iconSize / 2, cy - iconSize / 2, iconSize, iconSize),
        const Radius.circular(0),
      ),
      iconPaint,
    );
  }

  final picture = recorder.endRecording();
  final w = (size * pixelRatio).round();
  final h = (size * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode marker icon');
  }
  return _sizedIcon(byteData.buffer.asUint8List(), 72);
}

/// マーカー位置の微調整オフセット（ずれている方向に応じて調整可能）
/// 例: アイコンが右下にずれている場合 → Offset(-1, -1)
/// 例: アイコンが左上にずれている場合 → Offset(1, 1) を大きく
/// ズームアウト時にずれが目立つ場合は値を大きくする
const Offset _markerOffset = Offset(12, 15);

/// アイコンを指定サイズでラップ（flutter_map Marker 用）
/// マーカー領域いっぱいに広げて中央配置し、位置ずれを防ぐ
Widget _sizedIcon(Uint8List bytes, double size) {
  return Transform.translate(
    offset: _markerOffset,
    child: SizedBox.expand(
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.center,
            child: Image.memory(bytes),
          ),
        ),
      ),
    ),
  );
}

void _paintPoiMarkerDisk({
  required Canvas canvas,
  required double cx,
  required double cy,
  required double radius,
  required Color fillColor,
}) {
  final circlePaint = Paint()
    ..color = fillColor
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(Offset(cx, cy), radius, borderPaint);
}

/// Material のチェック形に近い太線のチェック（フォントの Icons.check より線幅を制御しやすい）
void _paintThickCheckMark(Canvas canvas, double cx, double cy) {
  const strokeWidth = 9.0;
  final checkPath = Path()
    ..moveTo(cx - 13, cy)
    ..lineTo(cx - 2, cy + 11)
    ..lineTo(cx + 15, cy - 13);
  canvas.drawPath(
    checkPath,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );
}

void _paintCircleMaterialIcon({
  required Canvas canvas,
  required double cx,
  required double cy,
  required double radius,
  required Color fillColor,
  required IconData icon,
  double iconFontSize = 44,
  double iconOffsetX = 0,
  double iconOffsetY = 0,
}) {
  _paintPoiMarkerDisk(
    canvas: canvas,
    cx: cx,
    cy: cy,
    radius: radius,
    fillColor: fillColor,
  );

  final textPainter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
        fontSize: iconFontSize,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      cx - textPainter.width / 2 + iconOffsetX,
      cy - textPainter.height / 2 + iconOffsetY,
    ),
  );
}

const double _kPoiMarkerCanvasSize = 102.0;
const double _kPoiMarkerRadius = 40.0;
const double _kPoiMarkerPixelRatio = 2.0;
const double _kPoiMarkerWidgetSize = 72.0;

Future<Widget> _encodePoiMarkerIcon(
  void Function(Canvas canvas, double cx, double cy) paintIcon,
) async {
  const size = _kPoiMarkerCanvasSize;
  const cx = size / 2;
  const cy = size / 2;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..clipRect(const Rect.fromLTWH(0, 0, size, size));

  paintIcon(canvas, cx, cy);

  final picture = recorder.endRecording();
  final w = (size * _kPoiMarkerPixelRatio).round();
  final h = (size * _kPoiMarkerPixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode marker icon');
  }
  return _sizedIcon(byteData.buffer.asUint8List(), _kPoiMarkerWidgetSize);
}

Future<Widget> createPoiTypeMarkerIcon(UserPoiType type) async {
  return _encodePoiMarkerIcon((canvas, cx, cy) {
    switch (type) {
      case UserPoiType.checkpoint:
        _paintPoiMarkerDisk(
          canvas: canvas,
          cx: cx,
          cy: cy,
          radius: _kPoiMarkerRadius,
          fillColor: type.markerFillColor,
        );
        _paintThickCheckMark(canvas, cx - 1, cy + 2);
        break;
      case UserPoiType.information:
        _paintPoiMarkerDisk(
          canvas: canvas,
          cx: cx,
          cy: cy,
          radius: _kPoiMarkerRadius,
          fillColor: type.markerFillColor,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: 'i',
            style: TextStyle(
              color: Colors.white,
              fontSize: type.markerIconFontSize,
              fontWeight: FontWeight.w800,
              fontFamily: 'sans-serif',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
        );
        break;
      case UserPoiType.photo:
      case UserPoiType.store:
      case UserPoiType.hotel:
      case UserPoiType.dining:
      case UserPoiType.station:
        final offset = type.markerIconOffset;
        _paintCircleMaterialIcon(
          canvas: canvas,
          cx: cx,
          cy: cy,
          radius: _kPoiMarkerRadius,
          fillColor: type.markerFillColor,
          icon: type.icon,
          iconFontSize: type.markerIconFontSize,
          iconOffsetX: offset.dx,
          iconOffsetY: offset.dy,
        );
        break;
    }
  });
}

/// インフォメーションPOI用（白文字の「i」）
Future<Widget> createPoiInfoMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.information);

/// フォトPOI用
Future<Widget> createPoiCheckpointPhotoMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.photo);

/// ストアPOI用
Future<Widget> createPoiStoreMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.store);

/// ホテルPOI用
Future<Widget> createPoiHotelMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.hotel);

/// 食事POI用
Future<Widget> createPoiDiningMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.dining);

/// 駅POI用
Future<Widget> createPoiStationMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.station);

/// 距離マーカー用の円アイコン（未使用・将来用）
Future<Widget> createSmallCircleMarkerIcon({
  Color color = Colors.blueGrey,
  double size = 32.0,
}) async {
  const pixelRatio = 2.0;
  final cx = size / 2;
  final cy = size / 2;
  final radius = size / 2 - 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

  final circlePaint = Paint()
    ..color = color
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

  final picture = recorder.endRecording();
  final w = (size * pixelRatio).round();
  final h = (size * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode marker icon');
  }
  return Image.memory(byteData.buffer.asUint8List());
}

/// 距離マーカー用アイコン（文字サイズ固定、マーカーサイズはラベル長に応じて可変）
/// 返り値: (アイコン Widget, マーカー幅, マーカー高さ)
Future<({Widget icon, double width, double height})> createDistanceMarkerIcon(
    String label) async {
  const pixelRatio = 2.0;
  const horizontalPadding = 6.0; // 左右の余白
  const verticalPadding = 3.0; // 上下の余白
  // 文字サイズを固定（桁数に依存しない）
  const fixedFontSize = 20.0;

  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: fixedFontSize,
        fontWeight: FontWeight.w500,
        fontFamily: 'sans-serif',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  final width = textPainter.width + horizontalPadding * 2;
  final height = textPainter.height + verticalPadding * 2;

  final rect = Rect.fromLTWH(0, 0, width, height);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(rect);

  final bgPaint = Paint()
    ..color = Colors.blueGrey
    ..style = PaintingStyle.fill;
  canvas.drawRect(rect, bgPaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0;
  canvas.drawRect(rect, borderPaint);

  textPainter.paint(
    canvas,
    const Offset(horizontalPadding, verticalPadding),
  );

  final picture = recorder.endRecording();
  final w = (width * pixelRatio).round();
  final h = (height * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode marker icon');
  }
  // 距離マーカーは左にずれやすいため右方向、下にずれやすいため上方向の補正を追加
  // _sizedIcon は使わず、画像をそのまま表示（スケールしない＝文字サイズ固定）
  const offsetX = 10.0;
  const offsetY = -12.0;
  final icon = Transform.translate(
    offset: const Offset(offsetX, offsetY),
    child: Image.memory(byteData.buffer.asUint8List()),
  );
  // オフセット分をマーカーサイズに加算してクリッピングを防ぐ
  return (
    icon: icon,
    width: width + offsetX,
    height: height + offsetY.abs(),
  );
}

/// 共有プレビュー用
Future<Widget> createSharePreviewMarkerIcon() async {
  const size = 102.0;
  const radius = 40.0;
  const pixelRatio = 2.0;
  const cx = size / 2;
  const cy = size / 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..clipRect(const Rect.fromLTWH(0, 0, size, size));

  final circlePaint = Paint()
    ..color = Colors.blue
    ..style = PaintingStyle.fill;
  canvas.drawCircle(const Offset(cx, cy), radius, circlePaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(const Offset(cx, cy), radius, borderPaint);

  // 下向き矢印（パスで描画・天地左右中央揃え、太め）
  const arrowTip = 14.0;
  const arrowBase = 18.0;
  // 三角形の重心が (cx, cy) に来るようオフセット（重心=(y1+y2+y3)/3）
  const arrowOffsetY = (2.0 * arrowBase - arrowTip) / 3.0;
  final arrowPath = Path()
    ..moveTo(cx, cy + arrowTip + arrowOffsetY)
    ..lineTo(cx - arrowBase, cy - arrowBase + arrowOffsetY)
    ..lineTo(cx + arrowBase, cy - arrowBase + arrowOffsetY)
    ..close();
  canvas.drawPath(
    arrowPath,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..strokeWidth = 0,
  );

  final picture = recorder.endRecording();
  final w = (size * pixelRatio).round();
  final h = (size * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Failed to encode marker icon');
  }
  return _sizedIcon(byteData.buffer.asUint8List(), 72);
}

/// チェックポイントPOI用（太線の Check マーク）
Future<Widget> createPoiCheckpointMarkerIcon() =>
    createPoiTypeMarkerIcon(UserPoiType.checkpoint);

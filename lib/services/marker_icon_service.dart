import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 角丸の正方形マーカー（スタート・ゴール用）
Future<BitmapDescriptor> createRoundedSquareMarkerIcon({
  required Color backgroundColor,
  required bool isPlayIcon,
}) async {
  const size = 106.0;
  const radius = 31.0;
  const borderWidth = 6.0;
  const pixelRatio = 2.0;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

  final outerRrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size, size),
    const Radius.circular(radius),
  );
  final innerRadius = (radius - borderWidth).clamp(0.0, double.infinity);
  final innerRrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(borderWidth, borderWidth, size - borderWidth * 2,
        size - borderWidth * 2),
    Radius.circular(innerRadius),
  );
  canvas.drawRRect(outerRrect, Paint()..color = Colors.white);
  canvas.drawRRect(innerRrect, Paint()..color = backgroundColor);

  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;
  final cx = size / 2;
  final cy = size / 2;

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
        Rect.fromLTWH(cx - iconSize / 2, cy - iconSize / 2, iconSize, iconSize),
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
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

/// インフォメーションPOI用
Future<BitmapDescriptor> createPoiInfoMarkerIcon() async {
  const size = 102.0;
  const radius = 40.0;
  const pixelRatio = 2.0;
  final cx = size / 2;
  final cy = size / 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

  final circlePaint = Paint()
    ..color = Colors.orange
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

  const text = 'i';
  final textPainter = TextPainter(
    text: const TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.white,
        fontSize: 48,
        fontWeight: FontWeight.w600,
        fontFamily: 'sans-serif',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
  );

  final picture = recorder.endRecording();
  final w = (size * pixelRatio).round();
  final h = (size * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

/// チェックポイントPOI用
Future<BitmapDescriptor> createPoiCheckpointMarkerIcon() async {
  const size = 102.0;
  const radius = 40.0;
  const pixelRatio = 2.0;
  final cx = size / 2;
  final cy = size / 2;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..clipRect(Rect.fromLTWH(0, 0, size, size));

  final circlePaint = Paint()
    ..color = Colors.lightBlue
    ..style = PaintingStyle.fill;
  canvas.drawCircle(Offset(cx, cy), radius, circlePaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;
  canvas.drawCircle(Offset(cx, cy), radius, borderPaint);

  final checkPath = Path()
    ..moveTo(cx - 13, cy)
    ..lineTo(cx - 2, cy + 11)
    ..lineTo(cx + 15, cy - 13);
  final checkPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  canvas.drawPath(checkPath, checkPaint);

  final picture = recorder.endRecording();
  final w = (size * pixelRatio).round();
  final h = (size * pixelRatio).round();
  final image = await picture.toImage(w, h);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
}

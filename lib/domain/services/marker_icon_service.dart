import 'package:flutter/material.dart';

/// 角丸の正方形マーカー（スタート・ゴール用）
Widget createRoundedSquareMarkerIcon({
  required Color backgroundColor,
  required bool isPlayIcon,
}) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: Icon(
      isPlayIcon ? Icons.play_arrow : Icons.stop,
      color: Colors.white,
      size: 22,
    ),
  );
}

/// インフォメーションPOI用
Widget createPoiInfoMarkerIcon() {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.orange,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: const Center(
      child: Text(
        'i',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

/// チェックポイントPOI用
Widget createPoiCheckpointMarkerIcon() {
  return Container(
    width: 36,
    height: 36,
    decoration: BoxDecoration(
      color: Colors.lightBlue,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
    ),
    child: const Icon(Icons.check, color: Colors.white, size: 18),
  );
}

/// 距離マーカー用アイコン（「50km」「100km」等のラベル）
Widget createDistanceMarkerIcon(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.blueGrey,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

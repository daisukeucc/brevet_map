import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/pulsing_location_marker.dart';

/// マップ上に表示するマーカーリストを組み立てる純粋関数。
///
/// [baseMarkers]       : ルートマーカー（POI など）の基底リスト
/// [pendingPosition]   : 共有リンクのプレビューマーカー位置（null なら追加しない）
/// [sharePreviewIcon]  : プレビューマーカーのアイコン（null なら デフォルトアイコン）
/// [streamPosition]    : 位置ストリームの最新位置（isStreamActive が true のとき使用）
/// [fallbackPosition]  : streamPosition が null のときのフォールバック位置
/// [isStreamActive]    : 位置ストリームが ON かどうか
/// [isDarkMode]        : ダークマップスタイルかどうか（現在地マーカーの色に影響）
List<Marker> buildMapMarkers({
  required List<Marker> baseMarkers,
  required LatLng? pendingPosition,
  required Widget? sharePreviewIcon,
  required Position? streamPosition,
  required LatLng fallbackPosition,
  required bool isStreamActive,
  required bool isDarkMode,
}) {
  var markers = baseMarkers;

  // 共有リンクのプレビューマーカー
  if (pendingPosition != null) {
    markers = [
      ...markers,
      Marker(
        point: pendingPosition,
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: sharePreviewIcon ??
            const Icon(Icons.place, color: Colors.orange, size: 48),
      ),
    ];
  }

  // 位置ストリームON時の現在地マーカー
  if (isStreamActive) {
    final posLatLng = streamPosition != null
        ? LatLng(streamPosition.latitude, streamPosition.longitude)
        : fallbackPosition;
    markers = [
      ...markers,
      Marker(
        point: posLatLng,
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: PulsingLocationMarker(size: 72, isDarkMode: isDarkMode),
      ),
    ];
  }

  return markers;
}

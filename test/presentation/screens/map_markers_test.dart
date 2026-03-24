import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:brevet_map/presentation/screens/map_markers.dart';
import 'package:brevet_map/presentation/widgets/pulsing_location_marker.dart';

/// テスト用のダミー [Position] を生成するヘルパー
Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2000),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

/// テスト用のダミー [Marker] を生成するヘルパー
Marker _dummyMarker(LatLng point) => Marker(
      point: point,
      child: const SizedBox.shrink(),
    );

const _fallback = LatLng(35.68, 139.77);

void main() {
  group('buildMapMarkers', () {
    test('baseMarkers のみのとき、そのまま返る', () {
      final base = [_dummyMarker(const LatLng(35.0, 139.0))];

      final result = buildMapMarkers(
        baseMarkers: base,
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: null,
        fallbackPosition: _fallback,
        isStreamActive: false,
        isDarkMode: false,
      );

      expect(result, equals(base));
    });

    test('pendingPosition が非 null のとき、プレビューマーカーが追加される', () {
      const pending = LatLng(35.1, 139.1);

      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: pending,
        sharePreviewIcon: null,
        streamPosition: null,
        fallbackPosition: _fallback,
        isStreamActive: false,
        isDarkMode: false,
      );

      expect(result.length, 1);
      expect(result.first.point, pending);
    });

    test('sharePreviewIcon が null のとき、デフォルトアイコン（Icons.place）が使われる', () {
      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: const LatLng(35.1, 139.1),
        sharePreviewIcon: null,
        streamPosition: null,
        fallbackPosition: _fallback,
        isStreamActive: false,
        isDarkMode: false,
      );

      final child = result.first.child;
      expect(child, isA<Icon>());
      expect((child as Icon).icon, Icons.place);
    });

    test('sharePreviewIcon が指定されているとき、そのウィジェットが使われる', () {
      const customIcon = Icon(Icons.star);

      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: const LatLng(35.1, 139.1),
        sharePreviewIcon: customIcon,
        streamPosition: null,
        fallbackPosition: _fallback,
        isStreamActive: false,
        isDarkMode: false,
      );

      expect(result.first.child, customIcon);
    });

    test('isStreamActive が true のとき、現在地マーカーが追加される', () {
      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: _pos(35.5, 139.5),
        fallbackPosition: _fallback,
        isStreamActive: true,
        isDarkMode: false,
      );

      expect(result.length, 1);
      expect(result.first.child, isA<PulsingLocationMarker>());
    });

    test('isStreamActive が true で streamPosition が null のとき、fallbackPosition が使われる', () {
      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: null,
        fallbackPosition: _fallback,
        isStreamActive: true,
        isDarkMode: false,
      );

      expect(result.length, 1);
      expect(result.first.point, _fallback);
    });

    test('isStreamActive が true のとき、streamPosition の座標がマーカー位置になる', () {
      final pos = _pos(35.5, 139.5);

      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: pos,
        fallbackPosition: _fallback,
        isStreamActive: true,
        isDarkMode: false,
      );

      expect(result.first.point.latitude, pos.latitude);
      expect(result.first.point.longitude, pos.longitude);
    });

    test('isDarkMode が渡される', () {
      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: _pos(35.5, 139.5),
        fallbackPosition: _fallback,
        isStreamActive: true,
        isDarkMode: true,
      );

      final marker = result.first.child as PulsingLocationMarker;
      expect(marker.isDarkMode, isTrue);
    });

    test('baseMarkers・pendingPosition・isStreamActive がすべて揃うとき、合計3件になる', () {
      final base = [
        _dummyMarker(const LatLng(35.0, 139.0)),
        _dummyMarker(const LatLng(35.1, 139.1)),
      ];

      final result = buildMapMarkers(
        baseMarkers: base,
        pendingPosition: const LatLng(35.2, 139.2),
        sharePreviewIcon: null,
        streamPosition: _pos(35.5, 139.5),
        fallbackPosition: _fallback,
        isStreamActive: true,
        isDarkMode: false,
      );

      expect(result.length, 4); // base(2) + pending(1) + stream(1)
    });

    test('isStreamActive が false のとき、現在地マーカーは追加されない', () {
      final result = buildMapMarkers(
        baseMarkers: [],
        pendingPosition: null,
        sharePreviewIcon: null,
        streamPosition: _pos(35.5, 139.5),
        fallbackPosition: _fallback,
        isStreamActive: false,
        isDarkMode: false,
      );

      expect(result, isEmpty);
    });
  });
}

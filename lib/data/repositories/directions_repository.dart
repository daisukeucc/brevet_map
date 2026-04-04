import 'dart:convert';
import 'dart:math';

import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// 緯度1度あたりの距離（km）
const double _kmPerDegreeLat = 111.32;

/// 現在地をスタート兼ゴールとした約100kmのルート用に経由地2つを返す
/// 北北東→北北西と経由することで、行きと帰りが一部異なる道を通る細長いループになる
/// 経路: 現在地 → 経由地1(北北東・約45km) → 経由地2(北北西・約45km) → 現在地
List<LatLng> computeWaypointsFor100kmLoop(double lat, double lng) {
  const northKm = 45.0;
  const eastWestKm = 8.0;
  final kmPerDegreeLng = _kmPerDegreeLat * cos(lat * pi / 180);

  final w1 = LatLng(
    lat + northKm / _kmPerDegreeLat,
    lng + eastWestKm / kmPerDegreeLng,
  );
  final w2 = LatLng(
    lat + northKm / _kmPerDegreeLat,
    lng - eastWestKm / kmPerDegreeLng,
  );
  return [w1, w2];
}

/// Directions API の取得成功時の戻り値。保存用の [encoded] と描画用の [points] を含む
typedef FetchDirectionsResult = ({List<LatLng> points, String encoded});

/// Directions API を呼び、ルートのポリラインをデコードして返す
/// [waypoints] を渡すと、origin → waypoints → destination の順で経路を取得する
/// 高速道路・自動車専用道路は avoid=highways で除外する
/// 失敗時は null。[encoded] はアプリ内保存用（Google のエンコード済みポリライン）
Future<FetchDirectionsResult?> fetchDirections({
  required LatLng origin,
  required LatLng destination,
  required String apiKey,
  List<LatLng>? waypoints,
}) async {
  var path = 'https://maps.googleapis.com/maps/api/directions/json'
      '?origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}';
  if (waypoints != null && waypoints.isNotEmpty) {
    path += '&waypoints=${waypoints.map((p) => '${p.latitude},${p.longitude}').join('|')}';
  }
  path += '&mode=driving&avoid=highways&key=$apiKey';
  final uri = Uri.parse(path);

  try {
    final response = await http
        .get(uri)
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final status = json['status'] as String?;
    if (status != 'OK') return null;

    final routes = json['routes'] as List<dynamic>?;
    if (routes == null || routes.isEmpty) return null;

    final route = routes.first as Map<String, dynamic>;
    final overview = route['overview_polyline'] as Map<String, dynamic>?;
    final encoded = overview?['points'] as String?;
    if (encoded == null || encoded.isEmpty) return null;

    final points = decodePolyline(encoded);
    return (points: points, encoded: encoded);
  } catch (_) {
    return null;
  }
}

/// Google のエンコード済みポリラインを [LatLng] にデコードする
List<LatLng> decodePolyline(String encoded) {
  final points = <LatLng>[];
  int index = 0;
  int lat = 0, lng = 0;

  while (index < encoded.length) {
    int shift = 0, result = 0;
    int b;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += dlng;

    points.add(LatLng(lat / 1e5, lng / 1e5));
  }
  return points;
}

/// [LatLng] のリストを Google のエンコード済みポリライン文字列に変換する（GPX保存用）
String encodePolyline(List<LatLng> points) {
  if (points.isEmpty) return '';
  final sb = StringBuffer();
  int lat = 0, lng = 0;
  for (final p in points) {
    final plat = (p.latitude * 1e5).round();
    final plng = (p.longitude * 1e5).round();
    _encodeValue(sb, plat - lat);
    _encodeValue(sb, plng - lng);
    lat = plat;
    lng = plng;
  }
  return sb.toString();
}

void _encodeValue(StringBuffer sb, int value) {
  int v = value << 1;
  if (value < 0) v = ~v;
  while (v >= 0x20) {
    sb.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  sb.writeCharCode(v + 63);
}

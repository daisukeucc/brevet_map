import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

/// GPXファイルのウェイポイント（POI）1件
class GpxPoi {
  const GpxPoi({
    required this.lat,
    required this.lng,
    this.name,
    this.description,
    this.symbol,
    this.cmt,
    this.type,
  });

  final double lat;
  final double lng;
  final String? name;
  final String? description;
  final String? symbol;

  /// GPXの <cmt>（コメント）
  final String? cmt;

  /// GPXの <type>（種別）。"control" / "checkpoint" 等でコントロールポイント判定に使用
  final String? type;

  LatLng get position => LatLng(lat, lng);

  /// コントロールポイントかどうか
  /// <type> が "control" または "checkpoint"、もしくは <cmt> が "control" のとき true
  bool get isControl {
    final t = type?.trim().toLowerCase();
    if (t == 'control' || t == 'checkpoint') return true;
    final c = cmt?.trim().toLowerCase();
    return c == 'control';
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'name': name,
        'desc': description,
        'sym': symbol,
        'cmt': cmt,
        'type': type,
      };

  static GpxPoi fromJson(Map<String, dynamic> json) {
    return GpxPoi(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      name: json['name'] as String?,
      description: json['desc'] as String?,
      symbol: json['sym'] as String?,
      cmt: json['cmt'] as String?,
      type: json['type'] as String?,
    );
  }
}

/// GPXパース結果：トラックポイントのリスト、ウェイポイント（POI）のリスト、metadataのname
typedef GpxParseResult = ({
  List<LatLng> trackPoints,
  List<GpxPoi> waypoints,
  String? metadataName,
});

/// GPX XML文字列をパースしてトラックとウェイポイントを返す。失敗時は null
GpxParseResult? parseGpx(String xmlContent) {
  try {
    final doc = XmlDocument.parse(xmlContent);
    final trackPoints = <LatLng>[];
    final waypoints = <GpxPoi>[];

    // <metadata><name>...</name></metadata>
    final metadataName = doc
        .findAllElements('metadata')
        .firstOrNull
        ?.findElements('name')
        .firstOrNull
        ?.innerText
        .trim();
    final name = metadataName?.isEmpty == true ? null : metadataName;

    // <trk><trkseg><trkpt lat="..." lon="..."> ...
    for (final trk in doc.findAllElements('trk')) {
      for (final seg in trk.findElements('trkseg')) {
        for (final pt in seg.findElements('trkpt')) {
          final lat = double.tryParse(pt.getAttribute('lat') ?? '');
          final lon = double.tryParse(pt.getAttribute('lon') ?? '');
          if (lat != null && lon != null) {
            trackPoints.add(LatLng(lat, lon));
          }
        }
      }
    }

    // <wpt>…<name/><desc/><sym/><cmt/><type/></wpt>
    for (final wpt in doc.findAllElements('wpt')) {
      final lat = double.tryParse(wpt.getAttribute('lat') ?? '');
      final lon = double.tryParse(wpt.getAttribute('lon') ?? '');
      if (lat != null && lon != null) {
        final name = wpt.findElements('name').firstOrNull?.innerText.trim();
        final desc = wpt.findElements('desc').firstOrNull?.innerText.trim();
        final sym = wpt.findElements('sym').firstOrNull?.innerText.trim();
        final cmt = wpt.findElements('cmt').firstOrNull?.innerText.trim();
        final type = wpt.findElements('type').firstOrNull?.innerText.trim();
        waypoints.add(GpxPoi(
          lat: lat,
          lng: lon,
          name: name?.isEmpty == true ? null : name,
          description: desc?.isEmpty == true ? null : desc,
          symbol: sym?.isEmpty == true ? null : sym,
          cmt: cmt?.isEmpty == true ? null : cmt,
          type: type?.isEmpty == true ? null : type,
        ));
      }
    }

    return (
      trackPoints: trackPoints,
      waypoints: waypoints,
      metadataName: name,
    );
  } catch (_) {
    return null;
  }
}

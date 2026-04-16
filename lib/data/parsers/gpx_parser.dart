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

  /// GPX の `<type>`（種別）。インポート時はそのまま保持してエクスポートに使う
  final String? type;

  LatLng get position => LatLng(lat, lng);

  /// チェックポイントとして扱うか（`UserPoi.type` 0 用）
  /// `<cmt>` が `control`（前後空白を除き大文字小文字は無視）のときだけ true。
  /// `<cmt>` が無い・空・それ以外はインフォメーション。
  bool get isControl {
    final c = cmt?.trim().toLowerCase();
    return c == 'control';
  }

  /// `<type>Dot</type>`（大文字小文字無視）。アプリ表示では無視し、エクスポート用に別保持する。
  bool get isGpxDotType {
    final t = type?.trim().toLowerCase();
    return t == 'dot';
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
/// [trackElevations] は [trackPoints] と同じ長さ。`<ele>` が無い点は null
typedef GpxParseResult = ({
  List<LatLng> trackPoints,
  List<double?> trackElevations,
  List<GpxPoi> waypoints,
  String? metadataName,
});

/// GPX XML文字列をパースしてトラックとウェイポイントを返す。失敗時は null
GpxParseResult? parseGpx(String xmlContent) {
  try {
    final doc = XmlDocument.parse(xmlContent);
    final trackPoints = <LatLng>[];
    final trackElevations = <double?>[];
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
            final eleText = pt.findElements('ele').firstOrNull?.innerText.trim();
            final ele = eleText == null || eleText.isEmpty
                ? null
                : double.tryParse(eleText);
            trackElevations.add(ele);
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
      trackElevations: trackElevations,
      waypoints: waypoints,
      metadataName: name,
    );
  } catch (_) {
    return null;
  }
}

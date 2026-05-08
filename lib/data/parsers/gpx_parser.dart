import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../domain/models/bm_extension.dart';

/// GPXファイルのウェイポイント（POI）1件
class GpxPoi {
  const GpxPoi({
    required this.lat,
    required this.lng,
    this.name,
    this.description,
    this.linkHref,
    this.symbol,
    this.cmt,
    this.type,
    this.bmPoiExt,
  });

  final double lat;
  final double lng;
  final String? name;
  final String? description;
  final String? linkHref;
  final String? symbol;

  /// GPXの <cmt>（コメント）
  final String? cmt;

  /// GPX の `<type>`（種別）。インポート時はそのまま保持してエクスポートに使う
  final String? type;

  /// `<extensions><bm:poi>` があれば保持する
  final BmPoiExtension? bmPoiExt;

  LatLng get position => LatLng(lat, lng);

  /// チェックポイントとして扱うか（`UserPoi.type` 0 用）
  /// `<type>checkpoint</type>`（前後空白を除き大文字小文字は無視）のときだけ true。
  bool get isCheckpoint {
    final t = type?.trim().toLowerCase();
    return t == 'checkpoint';
  }

  /// `<cmt>photo</cmt>` のチェックポイント（撮影系）→ 地図ではカメラマーカー
  bool get isPhotoCheckpointMarker =>
      isCheckpoint && cmt?.trim().toLowerCase() == 'photo';

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
        'linkHref': linkHref,
        'sym': symbol,
        'cmt': cmt,
        'type': type,
        if (bmPoiExt != null) 'bmPoiExt': bmPoiExt!.toJson(),
      };

  static GpxPoi fromJson(Map<String, dynamic> json) {
    return GpxPoi(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      name: json['name'] as String?,
      description: json['desc'] as String?,
      linkHref: json['linkHref'] as String?,
      symbol: json['sym'] as String?,
      cmt: json['cmt'] as String?,
      type: json['type'] as String?,
      bmPoiExt: json['bmPoiExt'] != null
          ? BmPoiExtension.fromJson(json['bmPoiExt'] as Map<String, dynamic>)
          : null,
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
  BmBrevetMeta? brevetMeta,
});

/// GPX XML文字列をパースしてトラックとウェイポイントを返す。失敗時は null
GpxParseResult? parseGpx(String xmlContent) {
  try {
    final doc = XmlDocument.parse(xmlContent);
    final trackPoints = <LatLng>[];
    final trackElevations = <double?>[];
    final waypoints = <GpxPoi>[];

    // <metadata>
    final metadataEl = doc.findAllElements('metadata').firstOrNull;
    final metadataName =
        metadataEl?.findElements('name').firstOrNull?.innerText.trim();
    final name = metadataName?.isEmpty == true ? null : metadataName;

    // <metadata><extensions><bm:brevet>
    final brevetMeta = _parseBrevetMeta(metadataEl);

    // <trk><trkseg><trkpt lat="..." lon="..."> ...
    for (final trk in doc.findAllElements('trk')) {
      for (final seg in trk.findElements('trkseg')) {
        for (final pt in seg.findElements('trkpt')) {
          final lat = double.tryParse(pt.getAttribute('lat') ?? '');
          final lon = double.tryParse(pt.getAttribute('lon') ?? '');
          if (lat != null && lon != null) {
            trackPoints.add(LatLng(lat, lon));
            final eleText =
                pt.findElements('ele').firstOrNull?.innerText.trim();
            final ele = eleText == null || eleText.isEmpty
                ? null
                : double.tryParse(eleText);
            trackElevations.add(ele);
          }
        }
      }
    }

    // <wpt>…<name/><desc/><link href="..."/><sym/><cmt/><type/><extensions/>
    for (final wpt in doc.findAllElements('wpt')) {
      final lat = double.tryParse(wpt.getAttribute('lat') ?? '');
      final lon = double.tryParse(wpt.getAttribute('lon') ?? '');
      if (lat != null && lon != null) {
        final wptName = wpt.findElements('name').firstOrNull?.innerText.trim();
        final desc = wpt.findElements('desc').firstOrNull?.innerText.trim();
        final linkHref =
            wpt.findElements('link').firstOrNull?.getAttribute('href')?.trim();
        final sym = wpt.findElements('sym').firstOrNull?.innerText.trim();
        final cmt = wpt.findElements('cmt').firstOrNull?.innerText.trim();
        final type = wpt.findElements('type').firstOrNull?.innerText.trim();
        final bmPoiExt = _parseBmPoiExtension(wpt);
        waypoints.add(GpxPoi(
          lat: lat,
          lng: lon,
          name: wptName?.isEmpty == true ? null : wptName,
          description: desc?.isEmpty == true ? null : desc,
          linkHref: linkHref?.isEmpty == true ? null : linkHref,
          symbol: sym?.isEmpty == true ? null : sym,
          cmt: cmt?.isEmpty == true ? null : cmt,
          type: type?.isEmpty == true ? null : type,
          bmPoiExt: bmPoiExt,
        ));
      }
    }

    return (
      trackPoints: trackPoints,
      trackElevations: trackElevations,
      waypoints: waypoints,
      metadataName: name,
      brevetMeta: brevetMeta,
    );
  } catch (_) {
    return null;
  }
}

/// `<metadata><extensions><bm:brevet>` をパースする。なければ null。
BmBrevetMeta? _parseBrevetMeta(XmlElement? metadata) {
  if (metadata == null) return null;
  final extensions = metadata.findElements('extensions').firstOrNull;
  if (extensions == null) return null;
  final brevet = extensions.findElements('bm:brevet').firstOrNull;
  if (brevet == null) return null;

  final distanceKm = double.tryParse(
        brevet.findElements('bm:distanceKm').firstOrNull?.innerText.trim() ??
            '',
      ) ??
      0;
  final startTimeStr =
      brevet.findElements('bm:startTime').firstOrNull?.innerText.trim() ?? '';
  final startTime =
      startTimeStr.isNotEmpty ? DateTime.tryParse(startTimeStr) : null;
  final timeLimitHours = double.tryParse(
        brevet
                .findElements('bm:timeLimitHours')
                .firstOrNull
                ?.innerText
                .trim() ??
            '',
      ) ??
      0;

  return BmBrevetMeta(
    distanceKm: distanceKm,
    startTime: startTime,
    timeLimitHours: timeLimitHours,
  );
}

/// `<wpt><extensions><bm:poi>` をパースする。なければ null。
BmPoiExtension? _parseBmPoiExtension(XmlElement wpt) {
  final extensions = wpt.findElements('extensions').firstOrNull;
  if (extensions == null) return null;
  final bmPoi = extensions.findElements('bm:poi').firstOrNull;
  if (bmPoi == null) return null;

  final type =
      bmPoi.findElements('bm:type').firstOrNull?.innerText.trim() ?? 'generic';

  final schedEl = bmPoi.findElements('bm:schedule').firstOrNull;
  DateTime? arrival, departure, close, result;
  if (schedEl != null) {
    arrival = _parseDateTime(
        schedEl.findElements('bm:arrival').firstOrNull?.innerText.trim());
    departure = _parseDateTime(
        schedEl.findElements('bm:departure').firstOrNull?.innerText.trim());
    close = _parseDateTime(
        schedEl.findElements('bm:close').firstOrNull?.innerText.trim());
    result = _parseDateTime(
        schedEl.findElements('bm:result').firstOrNull?.innerText.trim());
  }

  final routeInfoEl = bmPoi.findElements('bm:routeInfo').firstOrNull;
  final distanceKm = double.tryParse(
        routeInfoEl
                ?.findElements('bm:distanceKm')
                .firstOrNull
                ?.innerText
                .trim() ??
            '',
      ) ??
      0;

  return BmPoiExtension(
    type: type,
    schedule: BmSchedule(
        arrival: arrival, departure: departure, close: close, result: result),
    distanceKm: distanceKm,
  );
}

DateTime? _parseDateTime(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

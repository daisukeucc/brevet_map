import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../domain/models/user_poi.dart';

/// GPX XML を生成する。
///
/// [trackPoints] トラック（ルート）の座標リスト
/// [trackElevations] 各 trkpt の `<ele>`。[trackPoints] と同じ長さ。null または長さ不一致のときは出力しない
/// [gpxDotWaypoints] `<type>Dot</type>` のみ別保持（インポート内容をそのまま出力）
/// [gpxPois] レガシー保存の GPX ウェイポイント
/// [userPois] 表示・編集対象の POI
/// [filename] metadata と trk の name に使用するファイル名（任意）
String buildGpxXml({
  required List<LatLng> trackPoints,
  List<double?>? trackElevations,
  List<GpxPoi> gpxDotWaypoints = const [],
  List<GpxPoi> gpxPois = const [],
  List<UserPoi> userPois = const [],
  String? filename,
}) {
  final builder = XmlBuilder();
  builder.declaration(version: '1.0', encoding: 'UTF-8');
  builder.element('gpx', attributes: {
    'xmlns:gpxdata': 'http://www.cluetrust.com/XML/GPXDATA/1/0',
    'xmlns:xsi': 'http://www.w3.org/2001/XMLSchema-instance',
    'xmlns': 'http://www.topografix.com/GPX/1/1',
    'version': '1.1',
    'creator': 'http://brevetmap.com/',
    'xsi:schemaLocation':
        'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd '
        'http://www.cluetrust.com/XML/GPXDATA/1/0 http://www.cluetrust.com/Schemas/gpxdata10.xsd',
  }, nest: () {
    // metadata
    builder.element('metadata', nest: () {
      if (filename != null && filename.isNotEmpty) {
        builder.element('name', nest: () {
          builder.text(filename);
        });
      }
      builder.element('time', nest: () {
        builder.text(_toIso8601(DateTime.now()));
      });
    });

    // wpt: Dot（インポート復元）→ レガシー gpxPois → UserPoi
    for (final poi in gpxDotWaypoints) {
      _addWpt(builder, poi.lat, poi.lng,
          name: poi.name?.isNotEmpty == true ? poi.name : filename,
          desc: poi.description,
          sym: poi.symbol,
          cmt: poi.cmt,
          type: poi.type);
    }
    for (final poi in gpxPois) {
      _addWpt(builder, poi.lat, poi.lng,
          name: poi.name?.isNotEmpty == true ? poi.name : filename,
          desc: poi.description,
          sym: poi.symbol,
          cmt: poi.cmt,
          type: poi.type);
    }
    // UserPoi（手動追加・編集後含む）: 追加 POI と同一形式で出力（インポート時の cmt/type は引き継がない）
    for (final poi in userPois) {
      final body = poi.body.isEmpty ? null : poi.body;
      final name = poi.title.isEmpty ? null : poi.title;
      final cmtOut = poi.km != null
          ? _formatKmValue(poi.km!)
          : (poi.isCheckpoint ? 'control' : 'generic');
      final typeOut = poi.isCheckpoint ? 'checkpoint' : 'generic';
      _addWpt(builder, poi.lat, poi.lng,
          name: name,
          desc: body,
          sym: 'Dot',
          cmt: cmtOut,
          type: typeOut);
    }

    // trk
    if (trackPoints.isNotEmpty) {
      builder.element('trk', nest: () {
        if (filename != null && filename.isNotEmpty) {
          builder.element('name', nest: () {
            builder.text(filename);
          });
        }
        builder.element('trkseg', nest: () {
          final useEle = trackElevations != null &&
              trackElevations.length == trackPoints.length;
          for (var i = 0; i < trackPoints.length; i++) {
            final pt = trackPoints[i];
            final ele = useEle ? trackElevations[i] : null;
            if (ele != null) {
              builder.element('trkpt', attributes: {
                'lat': pt.latitude.toString(),
                'lon': pt.longitude.toString(),
              }, nest: () {
                builder.element('ele', nest: () {
                  builder.text(ele.toString());
                });
              });
            } else {
              builder.element('trkpt', attributes: {
                'lat': pt.latitude.toString(),
                'lon': pt.longitude.toString(),
              });
            }
          }
        });
      });
    }
  });

  return builder.buildDocument().toXmlString(pretty: true);
}

void _addWpt(
  XmlBuilder builder,
  double lat,
  double lng, {
  String? name,
  String? desc,
  String? sym,
  String? cmt,
  String? type,
}) {
  builder.element('wpt', attributes: {
    'lat': lat.toString(),
    'lon': lng.toString(),
  }, nest: () {
    if (name != null && name.isNotEmpty) {
      builder.element('name', nest: () {
        builder.text(name);
      });
    }
    if (desc != null && desc.isNotEmpty) {
      builder.element('desc', nest: () {
        builder.text(desc);
      });
    }
    if (sym != null && sym.isNotEmpty) {
      builder.element('sym', nest: () {
        builder.text(sym);
      });
    }
    if (cmt != null && cmt.isNotEmpty) {
      builder.element('cmt', nest: () {
        builder.text(cmt);
      });
    }
    if (type != null && type.isNotEmpty) {
      builder.element('type', nest: () {
        builder.text(type);
      });
    }
  });
}

String _formatKmValue(double km) {
  final s = km.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _toIso8601(DateTime dt) {
  return '${dt.toUtc().toIso8601String().replaceAll(' ', 'T').split('.')[0]}Z';
}

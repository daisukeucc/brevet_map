import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../domain/models/user_poi.dart';
import '../../utils/map_utils.dart';

/// GPX XML を生成する。
///
/// [trackPoints] トラック（ルート）の座標リスト
/// [gpxPois] GPXからインポートしたウェイポイント
/// [userPois] ユーザーが追加したPOI
/// [filename] metadata と trk の name に使用するファイル名（任意）
String buildGpxXml({
  required List<LatLng> trackPoints,
  List<GpxPoi> gpxPois = const [],
  List<UserPoi> userPois = const [],
  String? filename,
}) {
  final builder = XmlBuilder();
  builder.declaration(version: '1.0', encoding: 'UTF-8');
  builder.element('gpx', attributes: {
    'xmlns': 'http://www.topografix.com/GPX/1/1',
    'version': '1.1',
    'creator': 'Brevet Map',
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

    // wpt: gpxPois + userPois
    for (final poi in gpxPois) {
      _addWpt(builder, poi.lat, poi.lng,
          name: poi.name?.isNotEmpty == true ? poi.name : filename,
          desc: poi.description,
          sym: poi.symbol,
          cmt: poi.cmt,
          type: poi.type);
    }
    for (final poi in userPois) {
      final body = poi.body.isEmpty ? null : poi.body;
      final name = poi.km != null
          ? '${formatDistance(poi.km!, 0)}：${poi.title}'
          : (poi.title.isEmpty ? null : poi.title);
      // GPX から保持した <cmt>/<type> があればそのまま。手動追加・編集のみの POI は下記既定値
      // チェックポイント: cmt=control, type=checkpoint / インフォ: cmt=generic, type=generic
      final cmtOut = (poi.gpxCmt != null && poi.gpxCmt!.isNotEmpty)
          ? poi.gpxCmt!
          : (poi.isCheckpoint ? 'control' : 'generic');
      final typeOut = (poi.gpxType != null && poi.gpxType!.isNotEmpty)
          ? poi.gpxType!
          : (poi.isCheckpoint ? 'checkpoint' : 'generic');
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
          for (final pt in trackPoints) {
            builder.element('trkpt', attributes: {
              'lat': pt.latitude.toString(),
              'lon': pt.longitude.toString(),
            });
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

String _toIso8601(DateTime dt) {
  return '${dt.toUtc().toIso8601String().replaceAll(' ', 'T').split('.')[0]}Z';
}

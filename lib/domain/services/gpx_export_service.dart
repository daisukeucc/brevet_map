import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

import '../../data/parsers/gpx_parser.dart';
import '../../domain/models/bm_extension.dart';
import '../../domain/models/user_poi.dart';

/// GPX XML を生成する。
///
/// [trackPoints] トラック（ルート）の座標リスト
/// [trackElevations] 各 trkpt の `<ele>`。[trackPoints] と同じ長さ。null または長さ不一致のときは出力しない
/// [gpxDotWaypoints] `<type>Dot</type>` のみ別保持（インポート内容をそのまま出力）
/// [gpxPois] レガシー保存の GPX ウェイポイント
/// [userPois] 表示・編集対象の POI
/// [filename] metadata と trk の name に使用するファイル名（任意）
/// [brevetMeta] ブルベメタデータ。あれば `<metadata><extensions>` に出力する
String buildGpxXml({
  required List<LatLng> trackPoints,
  List<double?>? trackElevations,
  List<GpxPoi> gpxDotWaypoints = const [],
  List<GpxPoi> gpxPois = const [],
  List<UserPoi> userPois = const [],
  String? filename,
  BmBrevetMeta? brevetMeta,
}) {
  final builder = XmlBuilder();
  builder.declaration(version: '1.0', encoding: 'UTF-8');
  builder.element('gpx', attributes: {
    'version': '1.1',
    'creator': 'BrevetMap',
    'xmlns': 'http://www.topografix.com/GPX/1/1',
    'xmlns:bm': 'https://brevetmap.app/schema',
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
      if (brevetMeta != null) {
        builder.element('extensions', nest: () {
          builder.element('bm:brevet', attributes: {'version': '1.0'}, nest: () {
            builder.element('bm:distanceKm', nest: () {
              builder.text(_formatNumber(brevetMeta.distanceKm));
            });
            builder.element('bm:startTime', nest: () {
              builder.text(_toIso8601(brevetMeta.startTime));
            });
            builder.element('bm:timeLimitHours', nest: () {
              builder.text(_formatNumber(brevetMeta.timeLimitHours));
            });
          });
        });
      }
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
    for (final poi in userPois) {
      _addUserPoiWpt(builder, poi);
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

/// UserPoi を `<wpt>` として出力する。
/// bmExt がある場合は `<extensions><bm:poi>` を付加し、種別に応じた sym/type/cmt を設定する。
void _addUserPoiWpt(XmlBuilder builder, UserPoi poi) {
  final bmExt = poi.bmExt;
  final poiType = bmExt?.type ?? (poi.isCheckpoint ? 'checkpoint' : 'generic');
  final isStartOrFinish = poiType == 'start' || poiType == 'finish';

  final String? name;
  if (poiType == 'start') {
    name = poi.title.isEmpty ? 'Start' : poi.title;
  } else if (poiType == 'finish') {
    name = poi.title.isEmpty ? 'Goal' : poi.title;
  } else {
    name = poi.title.isEmpty ? null : poi.title;
  }
  final desc = poi.body.isEmpty ? null : poi.body;
  final sym = isStartOrFinish ? 'Flag' : 'Dot';
  final typeOut = poiType;
  final cmtOut = isStartOrFinish
      ? null
      : (poiType == 'checkpoint' ? 'control' : 'generic');

  _addWpt(
    builder,
    poi.lat,
    poi.lng,
    name: name,
    desc: isStartOrFinish ? null : desc,
    sym: sym,
    cmt: cmtOut,
    type: typeOut,
    bmPoiExt: bmExt,
  );
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
  BmPoiExtension? bmPoiExt,
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
    if (type != null && type.isNotEmpty) {
      builder.element('type', nest: () {
        builder.text(type);
      });
    }
    if (cmt != null && cmt.isNotEmpty) {
      builder.element('cmt', nest: () {
        builder.text(cmt);
      });
    }
    if (bmPoiExt != null) {
      builder.element('extensions', nest: () {
        builder.element('bm:poi', attributes: {'version': '1.0'}, nest: () {
          builder.element('bm:type', nest: () {
            builder.text(bmPoiExt.type);
          });
          if (!bmPoiExt.schedule.isEmpty) {
            builder.element('bm:schedule', nest: () {
              if (bmPoiExt.schedule.arrival != null) {
                builder.element('bm:arrival', nest: () {
                  builder.text(_toIso8601(bmPoiExt.schedule.arrival!));
                });
              }
              if (bmPoiExt.schedule.departure != null) {
                builder.element('bm:departure', nest: () {
                  builder.text(_toIso8601(bmPoiExt.schedule.departure!));
                });
              }
              if (bmPoiExt.schedule.close != null) {
                builder.element('bm:close', nest: () {
                  builder.text(_toIso8601(bmPoiExt.schedule.close!));
                });
              }
              if (bmPoiExt.schedule.result != null) {
                builder.element('bm:result', nest: () {
                  builder.text(_toIso8601(bmPoiExt.schedule.result!));
                });
              }
            });
          }
          builder.element('bm:routeInfo', nest: () {
            builder.element('bm:distanceKm', nest: () {
              builder.text(_formatNumber(bmPoiExt.distanceKm));
            });
          });
        });
      });
    }
  });
}

/// 整数なら小数点なし、小数点以下がある場合は最小桁数で出力する。
String _formatNumber(double value) {
  if (value == value.truncateToDouble()) {
    return value.truncate().toString();
  }
  final s = value.toString();
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s;
}

String _toIso8601(DateTime dt) {
  return '${dt.toUtc().toIso8601String().replaceAll(' ', 'T').split('.')[0]}Z';
}

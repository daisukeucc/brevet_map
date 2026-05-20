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
/// [filename] metadata と trk の name に使用するベース名（通常はインポート／エクスポート時のファイル名）
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
          builder.element('bm:brevet', attributes: {'version': '1.0'},
              nest: () {
            builder.element('bm:distanceKm', nest: () {
              builder.text(_formatNumber(brevetMeta.distanceKm));
            });
            if (brevetMeta.startTime != null) {
              builder.element('bm:startTime', nest: () {
                builder.text(_toIso8601(brevetMeta.startTime!));
              });
            }
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
          linkHref: poi.linkHref,
          sym: poi.symbol,
          cmt: poi.cmt,
          type: poi.type);
    }
    for (final poi in gpxPois) {
      _addWpt(builder, poi.lat, poi.lng,
          name: poi.name?.isNotEmpty == true ? poi.name : filename,
          desc: poi.description,
          linkHref: poi.linkHref,
          sym: poi.symbol,
          cmt: poi.cmt,
          type: poi.type);
    }
    for (var i = 0; i < userPois.length; i++) {
      _addUserPoiWpt(builder, userPois[i], displayOrder: i);
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

/// [UserPoi] に対応する GPX / `bm:type` 用の種別文字列（手動追加で [UserPoi.bmExt] が null でも正しい値）
String _bmPoiTypeForExport(UserPoi poi) {
  final fromExt = poi.bmExt?.type;
  if (fromExt != null && fromExt.isNotEmpty) return fromExt;
  final gt = poi.gpxType?.trim().toLowerCase();
  if (gt == GpxPoiTag.typeStart) return GpxPoiTag.typeStart;
  if (gt == GpxPoiTag.typeFinish) return GpxPoiTag.typeFinish;
  return poi.poiType.defaultBmPoiType;
}

/// UserPoi を `<wpt>` として出力する。
/// [UserPoi.bmExt] が無くても `<extensions><bm:poi><bm:type>` は出す（距離・時刻なし POI 用）。
/// [displayOrder] は [userPois] リスト上の位置（往復インポートで順序を復元する）。
void _addUserPoiWpt(XmlBuilder builder, UserPoi poi,
    {required int displayOrder}) {
  final bmExt = poi.bmExt;
  final poiType = _bmPoiTypeForExport(poi);
  final isStartOrFinish = GpxPoiTag.isStartOrFinishType(poiType);

  final String? name;
  if (GpxPoiTag.isStartType(poiType)) {
    name = poi.title.isEmpty ? GpxPoiTag.nameStart : poi.title;
  } else if (GpxPoiTag.isFinishType(poiType)) {
    name = poi.title.isEmpty ? GpxPoiTag.nameGoal : poi.title;
  } else {
    name = poi.title.isEmpty ? null : poi.title;
  }
  final desc = poi.body.isEmpty ? null : poi.body;
  final sym = isStartOrFinish ? GpxPoiTag.symFlag : GpxPoiTag.symDot;
  final gpxTag = poi.poiType.gpxTag;
  // スタート／ゴール以外は [UserPoiType.gpxTag] を GPX `<type>`/`<cmt>` と `bm:type` の正とする
  //（例: フォト CP は `<type>checkpoint</type>` `<cmt>photo</cmt>`）。
  final typeOut = isStartOrFinish ? poiType : gpxTag.type;
  final cmtOut = isStartOrFinish ? null : gpxTag.cmt;

  final src = bmExt ??
      BmPoiExtension(
        type: typeOut,
        schedule: const BmSchedule(),
        distanceKm: 0,
      );
  final bmPoiExtForExport = BmPoiExtension(
    type: typeOut,
    schedule: src.schedule,
    distanceKm: src.distanceKm,
    displayOrder: displayOrder,
    isNote: poi.isNote,
  );

  _addWpt(
    builder,
    poi.lat,
    poi.lng,
    name: name,
    desc: desc,
    linkHref: poi.url?.trim().isNotEmpty == true ? poi.url!.trim() : null,
    sym: sym,
    cmt: cmtOut,
    type: typeOut,
    bmPoiExt: bmPoiExtForExport,
    userPoiKm: poi.km,
  );
}

void _addWpt(
  XmlBuilder builder,
  double lat,
  double lng, {
  String? name,
  String? desc,
  String? linkHref,
  String? sym,
  String? cmt,
  String? type,
  BmPoiExtension? bmPoiExt,
  /// [UserPoi] のときルート距離（km）。null のとき `<bm:routeInfo>` は出さない。
  double? userPoiKm,
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
        _writeWptDesc(builder, desc);
      });
    }
    if (linkHref != null && linkHref.isNotEmpty) {
      builder.element('link', attributes: {'href': linkHref});
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
          if (bmPoiExt.displayOrder != null) {
            builder.element('bm:displayOrder', nest: () {
              builder.text(bmPoiExt.displayOrder.toString());
            });
          }
          if (bmPoiExt.isNote) {
            builder.element('bm:isNote', nest: () {
              builder.text('true');
            });
          }
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
              if (bmPoiExt.schedule.rest != null) {
                builder.element('bm:rest', nest: () {
                  builder.text(_toIso8601(bmPoiExt.schedule.rest!));
                });
              }
            });
          }
          if (userPoiKm != null) {
            builder.element('bm:routeInfo', nest: () {
              builder.element('bm:distanceKm', nest: () {
                builder.text(_formatNumber(userPoiKm));
              });
            });
          }
        });
      });
    }
  });
}

/// `<desc>` を書く。`toXmlString(pretty: true)` は通常のテキストノード内の改行を空白に潰すため、
/// 改行を含むときは CDATA を使う。CDATA 内に `]]>` を含む場合は複数ノードに分割する。
void _writeWptDesc(XmlBuilder builder, String desc) {
  final useCdata = desc.contains('\n') || desc.contains('\r');
  if (!useCdata) {
    builder.text(desc);
    return;
  }
  var remaining = desc;
  while (remaining.contains(']]>')) {
    final i = remaining.indexOf(']]>');
    builder.cdata(remaining.substring(0, i + 2));
    remaining = remaining.substring(i + 2);
  }
  if (remaining.isNotEmpty) {
    builder.cdata(remaining);
  }
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

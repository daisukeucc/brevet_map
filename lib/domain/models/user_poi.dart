import 'package:latlong2/latlong.dart';

import 'bm_extension.dart';

/// ユーザーが手動で登録した POI。SharedPreferences に JSON で保存する。
class UserPoi {
  const UserPoi({
    required this.type,
    required this.km,
    required this.title,
    required this.body,
    required this.lat,
    required this.lng,

    /// GPX インポート時の `cmt` 要素の値（手動追加 POI では null）
    this.gpxCmt,

    /// GPX インポート時の `type` 要素の値（手動追加 POI では null）
    this.gpxType,

    /// BrevetMap 独自拡張データ（`<bm:poi>`）
    this.bmExt,
  });

  /// 0=チェックポイント（GPX の `<type>checkpoint</type>` に相当）, 1=インフォメーション
  final int type;

  final double? km;

  final String title;
  final String body;
  final double lat;
  final double lng;

  /// GPX インポート時の `<cmt>` の値（参照用）
  final String? gpxCmt;

  /// GPX インポート時の `<type>` の元文字列（参照用）
  final String? gpxType;

  /// BrevetMap 独自拡張データ。インポート / 新規追加時に設定される。
  final BmPoiExtension? bmExt;

  LatLng get position => LatLng(lat, lng);

  /// [list] 内での [target] のインデックス。
  ///
  /// 同一座標・[km] の行が複数ある場合は、[identical] で一致する要素を優先する（GPX の重複 wpt など）。
  static int indexInList(List<UserPoi> list, UserPoi target) {
    final byRef = list.indexWhere((p) => identical(p, target));
    if (byRef >= 0) return byRef;
    return list.indexWhere(
      (p) =>
          p.lat == target.lat && p.lng == target.lng && p.km == target.km,
    );
  }

  /// チェックポイントか（インポート時は `<type>checkpoint</type>` 由来）
  bool get isCheckpoint => type == 0;

  /// `<cmt>photo</cmt>` 由来など、GPX 上でフォト用 CP として扱うとき true
  bool get isPhotoCheckpointMarker =>
      isCheckpoint && gpxCmt?.trim().toLowerCase() == 'photo';

  static bool _isBmTypeFinish(UserPoi p) => p.bmExt?.type == 'finish';

  /// 詳細ボトムシートなどの表示順。
  ///
  /// - [bmExt.type] が `finish` の POI（ゴール）… **常に最後**（複数件ある場合は同じ下記ルールで相互に整列）
  /// - それ以外
  ///   - [km] がある POI … [km] 昇順（同値は [pois] の登録順）
  ///   - [km] がない POI … チェックポイント → インフォメーション、各グループは [pois] の登録順
  /// - 上記 2 グループは、まず非 finish ブロック、続けて finish ブロックを返す
  static List<UserPoi> orderedForDetailSheet(List<UserPoi> pois) {
    if (pois.isEmpty) return pois;
    final nonFinish = <UserPoi>[];
    final finish = <UserPoi>[];
    for (final p in pois) {
      if (_isBmTypeFinish(p)) {
        finish.add(p);
      } else {
        nonFinish.add(p);
      }
    }
    return [
      ..._orderedForDetailSheetCore(nonFinish),
      ..._orderedForDetailSheetCore(finish),
    ];
  }

  /// [orderedForDetailSheet] の、finish 分離前の区間用の整列（km ・CP/Info）。
  static List<UserPoi> _orderedForDetailSheetCore(List<UserPoi> pois) {
    if (pois.isEmpty) return pois;
    final indexed = pois.asMap().entries.toList();

    final withKm = indexed.where((e) => e.value.km != null).toList()
      ..sort((a, b) {
        final byKm = a.value.km!.compareTo(b.value.km!);
        if (byKm != 0) return byKm;
        return a.key.compareTo(b.key);
      });

    final withoutKmCp = <UserPoi>[];
    final withoutKmInfo = <UserPoi>[];
    for (final e in indexed) {
      final p = e.value;
      if (p.km != null) continue;
      if (p.isCheckpoint) {
        withoutKmCp.add(p);
      } else {
        withoutKmInfo.add(p);
      }
    }

    return [
      for (final e in withKm) e.value,
      ...withoutKmCp,
      ...withoutKmInfo,
    ];
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'km': km,
        'title': title,
        'body': body,
        'lat': lat,
        'lng': lng,
        if (gpxCmt != null) 'gpxCmt': gpxCmt,
        if (gpxType != null) 'gpxType': gpxType,
        if (bmExt != null) 'bmExt': bmExt!.toJson(),
      };

  static UserPoi fromJson(Map<String, dynamic> json) => UserPoi(
        type: json['type'] as int,
        km: json['km'] != null ? (json['km'] as num).toDouble() : null,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        gpxCmt: json['gpxCmt'] as String?,
        gpxType: json['gpxType'] as String?,
        bmExt: json['bmExt'] != null
            ? BmPoiExtension.fromJson(json['bmExt'] as Map<String, dynamic>)
            : null,
      );
}

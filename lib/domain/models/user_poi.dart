import 'package:latlong2/latlong.dart';

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

  LatLng get position => LatLng(lat, lng);

  /// チェックポイントか（インポート時は `<type>checkpoint</type>` 由来）
  bool get isCheckpoint => type == 0;

  Map<String, dynamic> toJson() => {
        'type': type,
        'km': km,
        'title': title,
        'body': body,
        'lat': lat,
        'lng': lng,
        if (gpxCmt != null) 'gpxCmt': gpxCmt,
        if (gpxType != null) 'gpxType': gpxType,
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
      );
}

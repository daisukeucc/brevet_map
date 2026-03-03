import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ユーザーが手動で登録した POI。SharedPreferences に JSON で保存する。
class UserPoi {
  const UserPoi({
    required this.type,
    this.km,
    required this.title,
    required this.body,
    required this.lat,
    required this.lng,
  });

  /// 0=チェックポイント, 1=インフォメーション
  final int type;

  final double? km;

  final String title;
  final String body;
  final double lat;
  final double lng;

  LatLng get position => LatLng(lat, lng);

  bool get isCheckpoint => type == 0;

  Map<String, dynamic> toJson() => {
        'type': type,
        'km': km,
        'title': title,
        'body': body,
        'lat': lat,
        'lng': lng,
      };

  static UserPoi fromJson(Map<String, dynamic> json) => UserPoi(
        type: json['type'] as int,
        km: json['km'] != null ? (json['km'] as num).toDouble() : null,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}

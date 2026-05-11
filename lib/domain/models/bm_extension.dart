/// BrevetMap 独自拡張データ（`<bm:…>` 名前空間）のモデル。
///
/// GPX の `<metadata><extensions><bm:brevet>` および
/// `<wpt><extensions><bm:poi>` を Dart オブジェクトとして表現する。

library bm_extension;

/// `<metadata><extensions><bm:brevet>` — ルート全体のブルベ情報。
class BmBrevetMeta {
  const BmBrevetMeta({
    required this.distanceKm,
    this.startTime,
    required this.timeLimitHours,
  });

  /// ブルベ公認距離（km）。判定できない場合は 0。
  final double distanceKm;

  /// スタート日時（UTC）。ユーザーが日付ピッカーで設定するまで null。
  final DateTime? startTime;

  /// 制限時間（時間）。判定できない場合は 0。
  final double timeLimitHours;

  Map<String, dynamic> toJson() => {
        'distanceKm': distanceKm,
        if (startTime != null)
          'startTime': startTime!.toUtc().toIso8601String(),
        'timeLimitHours': timeLimitHours,
      };

  static BmBrevetMeta fromJson(Map<String, dynamic> json) => BmBrevetMeta(
        distanceKm: (json['distanceKm'] as num).toDouble(),
        startTime: json['startTime'] != null
            ? DateTime.parse(json['startTime'] as String)
            : null,
        timeLimitHours: (json['timeLimitHours'] as num).toDouble(),
      );
}

/// `<bm:schedule>` — POI の通過予定時刻。
class BmSchedule {
  const BmSchedule({
    this.arrival,
    this.departure,
    this.close,
    this.result,
  });

  final DateTime? arrival;
  final DateTime? departure;
  final DateTime? close;
  final DateTime? result;

  bool get isEmpty =>
      arrival == null && departure == null && close == null && result == null;

  Map<String, dynamic> toJson() => {
        if (arrival != null) 'arrival': arrival!.toUtc().toIso8601String(),
        if (departure != null)
          'departure': departure!.toUtc().toIso8601String(),
        if (close != null) 'close': close!.toUtc().toIso8601String(),
        if (result != null) 'result': result!.toUtc().toIso8601String(),
      };

  static BmSchedule fromJson(Map<String, dynamic> json) => BmSchedule(
        arrival: json['arrival'] != null
            ? DateTime.parse(json['arrival'] as String)
            : null,
        departure: json['departure'] != null
            ? DateTime.parse(json['departure'] as String)
            : null,
        close: json['close'] != null
            ? DateTime.parse(json['close'] as String)
            : null,
        result: json['result'] != null
            ? DateTime.parse(json['result'] as String)
            : null,
      );
}

/// `<wpt><extensions><bm:poi>` — POI 1件分の拡張情報。
class BmPoiExtension {
  const BmPoiExtension({
    required this.type,
    required this.schedule,
    required this.distanceKm,
    this.displayOrder,
    this.isNote = false,
  });

  /// POI の種別。'start' / 'finish' / 'checkpoint' / 'generic'
  final String type;

  final BmSchedule schedule;

  /// スタートからこの POI までのルート沿い距離（km）。
  final double distanceKm;

  /// アプリの POI 一覧順（0 始まり）。GPX エクスポート時に `<bm:displayOrder>` へ書き、インポートで復元する。
  final int? displayOrder;

  /// `<bm:isNote>` — 区間距離・獲得標高の集計から除外するメモ POI。
  final bool isNote;

  Map<String, dynamic> toJson() => {
        'type': type,
        'schedule': schedule.toJson(),
        'distanceKm': distanceKm,
        if (displayOrder != null) 'displayOrder': displayOrder,
        if (isNote) 'isNote': true,
      };

  static BmPoiExtension fromJson(Map<String, dynamic> json) => BmPoiExtension(
        type: json['type'] as String? ?? 'generic',
        schedule: json['schedule'] != null
            ? BmSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
            : const BmSchedule(),
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        displayOrder: (json['displayOrder'] as num?)?.toInt(),
        isNote: json['isNote'] == true,
      );
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';

/// POI 詳細1件（ボトムシート用）
class PoiSheetEntry {
  const PoiSheetEntry({
    required this.name,
    required this.description,
    required this.position,
    this.distance,
    this.elevationGain,
    this.arrival,
    this.departure,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final LatLng position;

  /// スケジュール：到着時刻（UTC）
  final DateTime? arrival;

  /// スケジュール：出発時刻（UTC）
  final DateTime? departure;
}

/// POI タップ時に表示するボトムシート。名前と説明を表示。
/// [entries] が2件以上のときは同一カテゴリ（GPX / ユーザー）内のシート内移動（＞）を表示する。
void showPoiDetailSheet(
  BuildContext context, {
  required List<PoiSheetEntry> entries,
  int initialIndex = 0,
  void Function(LatLng position)? onCenterOnPoi,
}) {
  assert(entries.isNotEmpty, 'entries must not be empty');
  final safeInitial = initialIndex.clamp(0, entries.length - 1);

  showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.zero,
    ),
    builder: (context) {
      if (entries.length >= 2) {
        return _PoiDetailSheetNavigate(
          entries: entries,
          initialIndex: safeInitial,
          onCenterOnPoi: onCenterOnPoi,
        );
      }
      return _PoiDetailSheetBody(
        name: entries.first.name,
        distance: entries.first.distance,
        elevationGain: entries.first.elevationGain,
        description: entries.first.description,
        arrival: entries.first.arrival,
        departure: entries.first.departure,
      );
    },
  );
}

class _PoiDetailSheetBody extends StatelessWidget {
  const _PoiDetailSheetBody({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.arrival,
    this.departure,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final DateTime? arrival;
  final DateTime? departure;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 20, 25),
          child: _PoiContentBlock(
            name: name,
            distance: distance,
            elevationGain: elevationGain,
            description: description,
            arrival: arrival,
            departure: departure,
            distanceLeft: 20,
            contentLeft: 24,
          ),
        ),
      ),
    );
  }
}

class _PoiDetailSheetNavigate extends StatefulWidget {
  const _PoiDetailSheetNavigate({
    required this.entries,
    required this.initialIndex,
    this.onCenterOnPoi,
  });

  final List<PoiSheetEntry> entries;
  final int initialIndex;
  final void Function(LatLng position)? onCenterOnPoi;

  @override
  State<_PoiDetailSheetNavigate> createState() =>
      _PoiDetailSheetNavigateState();
}

class _PoiDetailSheetNavigateState extends State<_PoiDetailSheetNavigate> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.entries.length - 1);
  }

  void _goNext() {
    setState(() {
      _index = (_index + 1) % widget.entries.length;
    });
    widget.onCenterOnPoi?.call(widget.entries[_index].position);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entries[_index];
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 15, 25),
                  child: _PoiContentBlock(
                    name: e.name,
                    distance: e.distance,
                    elevationGain: e.elevationGain,
                    description: e.description,
                    arrival: e.arrival,
                    departure: e.departure,
                    distanceLeft: 20,
                    contentLeft: 24,
                  ),
                ),
              ),
              InkWell(
                onTap: _goNext,
                splashColor: Colors.grey.withValues(alpha: 0.3),
                highlightColor: Colors.grey.withValues(alpha: 0.2),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 36,
                    color: Colors.black38,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// タイトル・距離・標高・スケジュール・本文を縦に並べるコンテンツブロック
class _PoiContentBlock extends StatelessWidget {
  const _PoiContentBlock({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.arrival,
    this.departure,
    this.distanceLeft = 0,
    this.contentLeft = 0,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final DateTime? arrival;
  final DateTime? departure;
  final double distanceLeft;
  final double contentLeft;

  String _formatTime(DateTime dt) => DateFormat.Hm().format(dt);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasDistance = distance != null && distance!.isNotEmpty;
    final hasElevationGain = elevationGain != null && elevationGain!.isNotEmpty;
    final hasStats = hasDistance || hasElevationGain;
    final hasName = name != null && name!.isNotEmpty;
    final hasDescription = description != null && description!.isNotEmpty;
    final hasArrival = arrival != null;
    final hasDeparture = departure != null;
    final hasSchedule = hasArrival || hasDeparture;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 距離 + 獲得標高（1行）
        if (hasStats)
          Padding(
            padding: EdgeInsets.only(left: distanceLeft),
            child: Row(
              children: [
                if (hasDistance) ...[
                  const Icon(Icons.location_on,
                      size: 23, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(distance!, style: AppTextStyles.poiLarge),
                ],
                if (hasDistance && hasElevationGain) const SizedBox(width: 12),
                if (hasElevationGain) ...[
                  const Icon(Icons.trending_up,
                      size: 23, color: AppColors.muted),
                  const SizedBox(width: 3),
                  Text(elevationGain!, style: AppTextStyles.poiLarge),
                ],
              ],
            ),
          ),
        // スケジュール（arrival / departure）
        if (hasSchedule) ...[
          if (hasStats) const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 23),
            child: Row(
              children: [
                if (hasArrival) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    color: Colors.blueGrey,
                    child: Text(l10n.plannedArrival,
                        style: AppTextStyles.poiScheduleLabel),
                  ),
                  const SizedBox(width: 7),
                  Text(_formatTime(arrival!), style: AppTextStyles.poiSchedule),
                ],
                if (hasArrival && hasDeparture) const SizedBox(width: 12),
                if (hasDeparture) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    color: Colors.blueGrey,
                    child: Text(l10n.plannedDeparture,
                        style: AppTextStyles.poiScheduleLabel),
                  ),
                  const SizedBox(width: 7),
                  Text(_formatTime(departure!),
                      style: AppTextStyles.poiSchedule),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.only(left: distanceLeft),
          child: const Divider(height: 1, thickness: 1, color: Colors.black26),
        ),
        const SizedBox(height: 12),
        // タイトル
        if (hasName)
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text(
              name!.replaceAll('　', ' '),
              style: AppTextStyles.poiTitle.copyWith(height: 1.6),
            ),
          ),
        // 説明
        if (hasDescription) ...[
          const SizedBox(height: 3),
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text(
              description!.replaceAll('　', ' '),
              style: AppTextStyles.poiDetail.copyWith(height: 1.6),
            ),
          ),
        ],
      ],
    );
  }
}

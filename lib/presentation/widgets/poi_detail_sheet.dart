import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_text_styles.dart';

/// POI 詳細1件（ボトムシート用）
class PoiSheetEntry {
  const PoiSheetEntry({
    required this.name,
    required this.description,
    required this.position,
    this.distance,
    this.elevationGain,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final LatLng position;
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
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;

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
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 25, 20, 27),
                    child: _PoiContentBlock(
                      name: e.name,
                      distance: e.distance,
                      elevationGain: e.elevationGain,
                      description: e.description,
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
                      color: Colors.blueGrey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// タイトル・距離・本文を縦に並べるコンテンツブロック
class _PoiContentBlock extends StatelessWidget {
  const _PoiContentBlock({
    required this.name,
    required this.distance,
    required this.elevationGain,
    required this.description,
    this.distanceLeft = 0,
    this.contentLeft = 0,
  });

  final String? name;
  final String? distance;
  final String? elevationGain;
  final String? description;
  final double distanceLeft;
  final double contentLeft;

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.isNotEmpty;
    final hasDistance = distance != null && distance!.isNotEmpty;
    final hasElevationGain =
        elevationGain != null && elevationGain!.isNotEmpty;
    final hasDescription = description != null && description!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDistance) ...[
          Padding(
            padding: EdgeInsets.only(left: distanceLeft),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 25, color: Colors.blueGrey),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(distance!, style: AppTextStyles.distanceLarge),
                ),
              ],
            ),
          ),
        ],
        if (hasElevationGain) ...[
          const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.only(left: distanceLeft),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.trending_up, size: 20, color: Colors.blueGrey),
                const SizedBox(width: 3),
                Text(
                  elevationGain!,
                  style: AppTextStyles.body.copyWith(color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ],
        if (hasName) ...[
          if (hasDistance || hasElevationGain) const SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text(
              name!.replaceAll('　', ' '),
              style: AppTextStyles.headlineMedium
                  .copyWith(height: 1.6, color: Colors.blueGrey.shade600),
            ),
          ),
        ],
        if (hasDescription) ...[
          if (hasName || hasDistance || hasElevationGain)
            const SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.only(left: contentLeft),
            child: Text(
              description!,
              style: AppTextStyles.body
                  .copyWith(height: 1.6, color: Colors.blueGrey.shade600),
            ),
          ),
        ],
      ],
    );
  }
}

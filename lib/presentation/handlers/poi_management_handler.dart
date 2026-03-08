import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/models/user_poi.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/map_utils.dart';
import '../providers/providers.dart';
import '../theme/app_text_styles.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/text_menu_dialog.dart';

// ---------------------------------------------------------------------------
// POI管理のハンドラとダイアログ
// ---------------------------------------------------------------------------

/// POIフォームの入力データ
class AddPoiFormData {
  const AddPoiFormData({
    this.km,
    required this.type,
    required this.title,
    required this.body,
  });
  final double? km;
  final int type;
  final String title;
  final String body;
}

/// 地図タップでPOI追加を選択した場合のリクエスト
class MapTapAddRequest {
  const MapTapAddRequest();
}

/// 距離入力でPOI追加を選択した場合のリクエスト
class DistanceInputRequest {
  const DistanceInputRequest();
}

/// POIテキスト編集を選択した場合のリクエスト
class PoiEditTextRequest {
  const PoiEditTextRequest(this.poi);
  final UserPoi poi;
}

/// POI位置編集を選択した場合のリクエスト
class PoiEditPositionRequest {
  const PoiEditPositionRequest(this.poi);
  final UserPoi poi;
}

/// POI追加メニューがタップされたときのエントリポイント。
/// 戻り値で何が選択されたかを返す（null = キャンセル）。
Future<Object?> showPoiManagementDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  return showDialog<Object>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => const PoiManagementDialog(),
  );
}

/// 距離入力でPOI追加のフロー（ダイアログ表示→登録）
Future<void> handleDistanceInputPoiAdd(
  BuildContext context,
  WidgetRef ref,
) async {
  if (!context.mounted) return;
  final distanceUnit = ref.read(distanceUnitProvider);
  final data = await showDialog<AddPoiFormData>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) =>
        DistanceInputPoiDialog(distanceUnit: distanceUnit),
  );
  if (data == null || !context.mounted) return;
  if (data.km == null) return;

  final routePoints = ref.read(mapStateProvider).savedRoutePoints;
  if (routePoints == null || routePoints.isEmpty) {
    if (!context.mounted) return;
    showAppSnackBar(
        context, AppLocalizations.of(context)!.routeNotLoaded);
    return;
  }
  final coord = coordAtKm(routePoints, data.km!);
  if (coord == null) {
    if (!context.mounted) return;
    showAppSnackBar(
        context, AppLocalizations.of(context)!.kmPointNotFound);
    return;
  }
  final poi = UserPoi(
    type: data.type,
    km: data.km,
    title: data.title,
    body: data.body,
    lat: coord.latitude,
    lng: coord.longitude,
  );
  await ref.read(mapStateProvider.notifier).addUserPoi(poi);
  if (!context.mounted) return;
  showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
}

/// 地図ロングプレスでPOI追加（地図タップモード時）
Future<void> handleMapLongPressPoiAdd(
  BuildContext context,
  WidgetRef ref,
  LatLng position, {
  String? initialTitle,
  required VoidCallback onComplete,
}) async {
  if (!context.mounted) return;
  final data = await showDialog<AddPoiFormData>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) => MapTapPoiAddDialog(initialTitle: initialTitle),
  );
  onComplete();
  if (data == null || !context.mounted) return;

  final poi = UserPoi(
    type: data.type,
    km: null,
    title: data.title,
    body: data.body,
    lat: position.latitude,
    lng: position.longitude,
  );
  await ref.read(mapStateProvider.notifier).addUserPoi(poi);
  if (!context.mounted) return;
  showAppSnackBar(context, AppLocalizations.of(context)!.poiRegistered);
}

/// POIテキスト編集フロー
Future<void> handleEditPoiText(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi,
) async {
  if (!context.mounted) return;
  final distanceUnit = ref.read(distanceUnitProvider);
  final data = await showDialog<AddPoiFormData>(
    context: context,
    barrierColor: Colors.black54,
    builder: (context) =>
        EditPoiTextDialog(poi: poi, distanceUnit: distanceUnit),
  );
  if (data == null || !context.mounted) return;

  LatLng? coord;
  final kmChanged = data.km != poi.km;
  if (kmChanged && data.km != null) {
    final routePoints = ref.read(mapStateProvider).savedRoutePoints;
    if (routePoints != null && routePoints.isNotEmpty) {
      coord = coordAtKm(routePoints, data.km!);
    }
  }

  final updatedPoi = UserPoi(
    type: data.type,
    km: data.km,
    title: data.title,
    body: data.body,
    lat: coord?.latitude ?? poi.lat,
    lng: coord?.longitude ?? poi.lng,
  );
  await ref.read(mapStateProvider.notifier).updateUserPoi(poi, updatedPoi);
  if (!context.mounted) return;
  showAppSnackBar(context, AppLocalizations.of(context)!.poiUpdated);
}

/// POI位置編集（ドラッグ）の開始
Future<void> handleStartEditPoiPosition(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi, {
  required VoidCallback onStartDragMode,
  required void Function(UserPoi poi, LatLng newLatLng) onDragEnd,
}) async {
  if (!context.mounted) return;
  onStartDragMode();
  await ref.read(cameraControllerProvider.notifier).animateTo(
        poi.position,
        zoom: 16.0,
      );
  if (!context.mounted) return;
  await ref.read(mapStateProvider.notifier).startPoiDrag(poi, (newLatLng) {
    onDragEnd(poi, newLatLng);
  });
}

/// POIドラッグ終了時の処理
Future<void> handlePoiDragEnd(
  BuildContext context,
  WidgetRef ref,
  UserPoi poi,
  LatLng newLatLng, {
  required VoidCallback onStopDragMode,
}) async {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showConfirmDialog(
    context,
    message: l10n.changePoiPosition,
    cancelText: l10n.cancel,
    confirmText: l10n.change,
  );

  await ref.read(mapStateProvider.notifier).stopPoiDrag();
  if (!context.mounted) return;
  onStopDragMode();
  if (confirmed != true) return;

  final updatedPoi = UserPoi(
    type: poi.type,
    km: poi.km,
    title: poi.title,
    body: poi.body,
    lat: newLatLng.latitude,
    lng: newLatLng.longitude,
  );
  await ref.read(mapStateProvider.notifier).updateUserPoi(poi, updatedPoi);
  if (!context.mounted) return;
  showAppSnackBar(
      context, AppLocalizations.of(context)!.poiPositionChanged);
}

// ---------------------------------------------------------------------------
// 距離入力でPOI登録ダイアログ
// ---------------------------------------------------------------------------

class DistanceInputPoiDialog extends StatefulWidget {
  const DistanceInputPoiDialog({super.key, required this.distanceUnit});
  final int distanceUnit;

  @override
  State<DistanceInputPoiDialog> createState() => _DistanceInputPoiDialogState();
}

class _DistanceInputPoiDialogState extends State<DistanceInputPoiDialog> {
  int _poiType = 0;
  final _kmController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String? _kmError;
  late final FocusNode _kmFocusNode;

  @override
  void initState() {
    super.initState();
    _kmFocusNode = FocusNode();
    _kmFocusNode.addListener(_onKmFocusChange);
  }

  void _onKmFocusChange() {
    if (_kmFocusNode.hasFocus && _kmError != null && mounted) {
      setState(() => _kmError = null);
    }
  }

  @override
  void dispose() {
    _kmFocusNode.removeListener(_onKmFocusChange);
    _kmFocusNode.dispose();
    _kmController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final value = double.tryParse(_kmController.text.trim());
    if (value == null || value < 0) {
      setState(() => _kmError = AppLocalizations.of(context)!.kmRequired);
      return;
    }
    final km = widget.distanceUnit == 1 ? value * kmPerMile : value;
    setState(() => _kmError = null);
    Navigator.pop(
      context,
      AddPoiFormData(
        km: km,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _kmController,
                      focusNode: _kmFocusNode,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        isDense: true,
                        errorText: _kmError != null ? ' ' : null,
                        errorStyle: const TextStyle(height: 0, fontSize: 0),
                      ),
                      textAlign: TextAlign.end,
                      style: const TextStyle(fontSize: 17),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _kmError != null
                          ? Text(
                              _kmError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            )
                          : Text(
                              widget.distanceUnit == 1 ? 'mi' : 'km',
                              style: AppTextStyles.title,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.register,
                        style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POI管理ダイアログ（タブ：追加 / 編集）
// ---------------------------------------------------------------------------

class PoiManagementDialog extends ConsumerStatefulWidget {
  const PoiManagementDialog({super.key});

  @override
  ConsumerState<PoiManagementDialog> createState() =>
      _PoiManagementDialogState();
}

class _PoiManagementDialogState extends ConsumerState<PoiManagementDialog>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildAddTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text(AppLocalizations.of(context)!.poiAddByDistance,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(context, const DistanceInputRequest()),
          ),
          ListTile(
            title: Text(AppLocalizations.of(context)!.poiAddByMapTap,
                style: AppTextStyles.label),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            onTap: () => Navigator.pop(context, const MapTapAddRequest()),
          ),
        ],
      ),
    );
  }

  Future<void> _onEditTap(UserPoi poi) async {
    final l10n = AppLocalizations.of(context)!;
    final action = await showTextMenuDialog(
      context,
      items: [
        l10n.changePoiTextTitle,
        l10n.changePoiPositionTitle,
      ],
    );
    if (action == null || !mounted) return;
    if (action == 0) {
      Navigator.pop(context, PoiEditTextRequest(poi));
    } else {
      Navigator.pop(context, PoiEditPositionRequest(poi));
    }
  }

  Future<void> _onDeleteTap(UserPoi poi) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(
      context,
      message: l10n.deletePoiConfirm,
      cancelText: l10n.cancel,
      confirmText: l10n.delete,
    );
    if (confirmed != true || !mounted) return;

    await ref.read(mapStateProvider.notifier).deleteUserPoi(poi);
    if (!mounted) return;

    showAppSnackBar(context, AppLocalizations.of(context)!.poiDeleted);

    if (ref.read(mapStateProvider).userPois.isEmpty) {
      Navigator.pop(context);
    }
  }

  Widget _buildEditTab() {
    final userPois = ref.watch(mapStateProvider).userPois;
    final distanceUnit = ref.watch(distanceUnitProvider);
    if (userPois.isEmpty) {
      return Align(
        alignment: const Alignment(0, -0.2),
        child: Text(
          AppLocalizations.of(context)!.noPoiRegistered,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }
    final sorted = [...userPois]..sort(
        (a, b) => (a.km ?? double.infinity).compareTo(b.km ?? double.infinity));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, i) {
        final poi = sorted[i];
        final distStr =
            poi.km != null ? formatDistance(poi.km!, distanceUnit) : null;
        return DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    distStr != null
                        ? '$distStr：${poi.title.isEmpty ? AppLocalizations.of(context)!.titleNone : poi.title}'
                        : (poi.title.isEmpty
                            ? AppLocalizations.of(context)!.titleNone
                            : poi.title),
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _onEditTap(poi),
                  child: Text(AppLocalizations.of(context)!.edit,
                      style: AppTextStyles.buttonSmall),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _onDeleteTap(poi),
                  child: Text(AppLocalizations.of(context)!.delete,
                      style: AppTextStyles.buttonSmall),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: AppTextStyles.bodySmall,
              tabs: [
                Tab(text: AppLocalizations.of(context)!.poiTabAdd),
                Tab(text: AppLocalizations.of(context)!.poiTabEdit),
              ],
            ),
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAddTab(),
                  _buildEditTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 地図タップでPOI登録ダイアログ（km入力なし）
// ---------------------------------------------------------------------------

class MapTapPoiAddDialog extends StatefulWidget {
  const MapTapPoiAddDialog({super.key, this.initialTitle});

  final String? initialTitle;

  @override
  State<MapTapPoiAddDialog> createState() => _MapTapPoiAddDialogState();
}

class _MapTapPoiAddDialogState extends State<MapTapPoiAddDialog> {
  int _poiType = 0;
  late final TextEditingController _titleController;
  final _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    Navigator.pop(
      context,
      AddPoiFormData(
        km: null,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.register,
                        style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// POIテキスト編集ダイアログ
// ---------------------------------------------------------------------------

class EditPoiTextDialog extends StatefulWidget {
  const EditPoiTextDialog({
    super.key,
    required this.poi,
    required this.distanceUnit,
  });

  final UserPoi poi;
  final int distanceUnit;

  @override
  State<EditPoiTextDialog> createState() => _EditPoiTextDialogState();
}

class _EditPoiTextDialogState extends State<EditPoiTextDialog> {
  late int _poiType;
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _poiType = widget.poi.type;
    _titleController = TextEditingController(text: widget.poi.title);
    _bodyController = TextEditingController(text: widget.poi.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    Navigator.pop(
      context,
      AddPoiFormData(
        km: widget.poi.km,
        type: _poiType,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnRoute = widget.poi.km != null;
    final kmLabel = isOnRoute
        ? formatDistance(widget.poi.km!, widget.distanceUnit)
        : l10n.offRoute;
    final titleText =
        isOnRoute ? l10n.poiAtKmPoint(kmLabel) : l10n.poiOffRoutePoi;
    return Dialog(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    titleText,
                    style: AppTextStyles.headline,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(AppLocalizations.of(context)!.poiType,
                  style: AppTextStyles.body),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 0);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 0,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.checkpoint,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() => _poiType = 1);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: 1,
                      groupValue: _poiType,
                      onChanged: (v) {
                        FocusScope.of(context).unfocus();
                        setState(() => _poiType = v!);
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Text(AppLocalizations.of(context)!.information,
                        style: AppTextStyles.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.title,
                  isDense: true,
                ),
                style: AppTextStyles.title,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.body,
                  isDense: true,
                ),
                style: AppTextStyles.title,
                maxLines: 3,
                minLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context)!.cancel,
                        style: AppTextStyles.button),
                  ),
                  TextButton(
                    onPressed: _onSubmit,
                    child: Text(AppLocalizations.of(context)!.change,
                        style: AppTextStyles.button),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

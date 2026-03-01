import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_controller_notifier.dart';
import 'location_stream_notifier.dart';
import 'map_state_notifier.dart';
import 'offline_map_notifier.dart';

export 'camera_controller_notifier.dart';
export 'location_stream_notifier.dart';
export 'map_state_notifier.dart';
export 'offline_map_notifier.dart';

/// MapController への参照を保持し、カメラ操作APIを提供する
final cameraControllerProvider =
    NotifierProvider<CameraControllerNotifier, MapController>(
        CameraControllerNotifier.new);

/// 位置ストリームの状態を管理する（ON/OFF、精度、LOWモード）
final locationStreamProvider =
    NotifierProvider<LocationStreamNotifier, LocationStreamState>(
        LocationStreamNotifier.new);

/// ルート・マーカー・マップスタイルの状態を管理する
final mapStateProvider =
    NotifierProvider<MapStateNotifier, MapState>(MapStateNotifier.new);

/// オフラインマップのダウンロード状態・使用状態を管理する
final offlineMapProvider =
    NotifierProvider<OfflineMapNotifier, OfflineMapState>(OfflineMapNotifier.new);

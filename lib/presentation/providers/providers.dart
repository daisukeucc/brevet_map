import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import 'camera_controller_notifier.dart';
import 'location_stream_notifier.dart';
import 'map_state_notifier.dart';

export 'app_settings_providers.dart';
export 'camera_controller_notifier.dart';
export 'location_stream_notifier.dart';
export 'map_state_notifier.dart';

/// MapController への参照を保持し、カメラ操作APIを提供する
final cameraControllerProvider =
    NotifierProvider<CameraControllerNotifier, MapController?>(
        CameraControllerNotifier.new);

/// 位置ストリームの状態を管理する（ON/OFF、精度、LOWモード）
final locationStreamProvider =
    NotifierProvider<LocationStreamNotifier, LocationStreamState>(
        LocationStreamNotifier.new);

/// ルート・マーカー・マップスタイルの状態を管理する
final mapStateProvider =
    NotifierProvider<MapStateNotifier, MapState>(MapStateNotifier.new);

/// キャッシュ削除時にインクリメントし、地図のタイルプロバイダを再生成するためのキー
final mapTileProviderKeyProvider = StateProvider<int>((ref) => 0);

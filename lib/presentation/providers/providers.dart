import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'camera_controller_notifier.dart';
import 'location_stream_notifier.dart';
import 'map_state_notifier.dart';

export 'camera_controller_notifier.dart';
export 'location_stream_notifier.dart';
export 'map_state_notifier.dart';

/// GoogleMapController への参照を保持し、カメラ操作APIを提供する
final cameraControllerProvider =
    NotifierProvider<CameraControllerNotifier, GoogleMapController?>(
        CameraControllerNotifier.new);

/// 位置ストリームの状態を管理する（ON/OFF、精度、LOWモード）
final locationStreamProvider =
    NotifierProvider<LocationStreamNotifier, LocationStreamState>(
        LocationStreamNotifier.new);

/// ルート・マーカー・マップスタイルの状態を管理する
final mapStateProvider =
    NotifierProvider<MapStateNotifier, MapState>(MapStateNotifier.new);

/// 画面スリープまでの時間（分）。0=OFF、1/5/10=N分後にスリープ
final sleepDurationProvider = StateProvider<int>((ref) => 0);

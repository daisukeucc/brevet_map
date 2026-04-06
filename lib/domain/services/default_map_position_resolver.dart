import 'dart:ui' show PlatformDispatcher;

import '../../config/default_map_install_coordinates.dart';
import '../../data/repositories/first_launch_repository.dart';
import 'route_fetch_service.dart' show loadSavedRoute;

Future<({double lat, double lng})> _resolveInstallCoordinatesForApp() async {
  final code = await loadLocale();
  if (code != null && code.isNotEmpty) {
    return defaultInstallCoordinatesForLocaleCode(code);
  }
  return defaultInstallCoordinatesForSystemLocale(
      PlatformDispatcher.instance.locale);
}

/// プリファレンスまたは初回／保存ルートからフォールバック用の既定座標を解決する。
/// サンプルルート・GPX 読み込み後は保存済みルートのスタートが優先。
Future<({double lat, double lng})> resolveDefaultMapCoordinates() async {
  final existing = await loadDefaultMapCoordinatesOptional();
  if (existing != null) return existing;

  if (await isFirstLaunch()) {
    final c = await _resolveInstallCoordinatesForApp();
    await saveDefaultMapCoordinates(c.lat, c.lng);
    return c;
  }

  final route = await loadSavedRoute();
  if (route != null && route.isNotEmpty) {
    final p = route.first;
    await saveDefaultMapCoordinates(p.latitude, p.longitude);
    return (lat: p.latitude, lng: p.longitude);
  }

  final fallback = await _resolveInstallCoordinatesForApp();
  await saveDefaultMapCoordinates(fallback.lat, fallback.lng);
  return fallback;
}

import '../../data/repositories/first_launch_repository.dart';
import 'route_fetch_service.dart' show loadSavedRoute;

/// プリファレンスまたは初回／保存ルートからフォールバック用の既定座標を解決する。
Future<({double lat, double lng})> resolveDefaultMapCoordinates() async {
  final existing = await loadDefaultMapCoordinatesOptional();
  if (existing != null) return existing;

  if (await isFirstLaunch()) {
    await saveDefaultMapCoordinates(kDefaultInstallMapLat, kDefaultInstallMapLng);
    return (lat: kDefaultInstallMapLat, lng: kDefaultInstallMapLng);
  }

  final route = await loadSavedRoute();
  if (route != null && route.isNotEmpty) {
    final p = route.first;
    await saveDefaultMapCoordinates(p.latitude, p.longitude);
    return (lat: p.latitude, lng: p.longitude);
  }

  await saveDefaultMapCoordinates(kDefaultInstallMapLat, kDefaultInstallMapLng);
  return (lat: kDefaultInstallMapLat, lng: kDefaultInstallMapLng);
}

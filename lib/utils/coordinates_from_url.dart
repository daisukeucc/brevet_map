/// URL文字列から座標を抽出する。HTTPリクエストは行わず文字列のパースのみ。
/// 審査対応: 短縮URL展開やHTML取得は行わない。
({double lat, double lng})? extractCoordinatesFromUrlString(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  // !3dlat!4dlng 形式（例: !8m2!3d39.2743743!4d141.8827302）
  // Google Maps place URLでは、!3d!4d が実際の場所の座標、@ はビューポート中心。
  // !3d!4d を優先してピン位置のずれ（西寄り等）を防ぐ。
  var match = RegExp(r'!3d(-?\d+\.?\d*)!4d(-?\d+\.?\d*)').firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // @lat,lng 形式（例: .../@39.2824219,141.1208073,17z）
  match = RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)').firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // q=lat,lng 形式（例: q=39.2824219,141.1208073）
  match = RegExp(r'[?&]q=(-?\d+\.?\d*)[%2C,](-?\d+\.?\d*)').firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // center=lat,lng 形式（例: center=39.2824219,141.1208073）
  match =
      RegExp(r'[?&]center=(-?\d+\.?\d*)[%2C,](-?\d+\.?\d*)').firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // ll=lat,lng 形式（例: ll=39.2824219,141.1208073 / Apple Maps等）
  match = RegExp(r'[?&]ll=(-?\d+\.?\d*)[%2C,](-?\d+\.?\d*)').firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // 生の座標形式（例: 39.2824219,141.1208073）
  match = RegExp(r'^(-?\d+\.?\d*),(-?\d+\.?\d*)(?:,[0-9.]+[z]?)?$')
      .firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  return null;
}

bool _isValidCoord(double lat, double lng) {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
}

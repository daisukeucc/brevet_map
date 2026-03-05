/// URL文字列から座標を抽出
({double lat, double lng})? extractCoordinatesFromUrlString(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  // !3dlat!4dlng 形式（例: !8m2!3d39.2743743!4d141.8827302）
  // !3d!4d を優先してピン位置のずれを防ぐ
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
  match = RegExp(r'[?&]center=(-?\d+\.?\d*)[%2C,](-?\d+\.?\d*)')
      .firstMatch(trimmed);
  if (match != null) {
    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    if (lat != null && lng != null && _isValidCoord(lat, lng)) {
      return (lat: lat, lng: lng);
    }
  }

  // ll=lat,lng 形式（例: ll=39.2824219,141.1208073 / Apple Maps等）
  match =
      RegExp(r'[?&]ll=(-?\d+\.?\d*)[%2C,](-?\d+\.?\d*)').firstMatch(trimmed);
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

/// Google Maps place URL から施設名を抽出する。
/// 日本語住所形式（〒、丁目等）の場合は住所を除去して施設名のみを返す。
/// それ以外のロケールは切り分けせず全文を返す（ユーザーが編集可能）。
String? extractPlaceNameFromUrlString(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return null;

  final match = RegExp(r'google\.com/maps/place/([^/]+)').firstMatch(trimmed);
  if (match == null) return null;

  try {
    var decoded = Uri.decodeComponent(match.group(1)!);
    decoded = decoded.replaceAll('+', ' ');
    return _extractFacilityNameOnly(decoded);
  } catch (_) {
    return null;
  }
}

/// 日本語住所形式の場合のみ住所を除去し施設名を抽出。それ以外は全文を返す。
/// 施設名は建物名・会社名・支店名など複数になる場合がある
String _extractFacilityNameOnly(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;

  // 日本語住所形式の判定（〒、丁目、都道府県などの有無）
  final isJapaneseAddress =
      s.contains('〒') ||
      s.contains('丁目') ||
      s.contains('県') ||
      s.contains('都') ||
      s.contains('府') ||
      (s.contains('市') && RegExp(r'\d{3}-?\d{4}').hasMatch(s));

  if (isJapaneseAddress) {
    final parts =
        s.split(RegExp(r'[\s+]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return s;

    int facilityStart = 0;
    for (var i = 0; i < parts.length; i++) {
      final p = parts[i];
      if (_isAddressPart(p)) {
        facilityStart = i + 1;
      }
    }
    if (facilityStart < parts.length) {
      return parts.sublist(facilityStart).join(' ');
    }
  }

  // 日本語以外など：切り分けせず全文をタイトルとして返す
  return s;
}

bool _isAddressPart(String part) {
  if (part.isEmpty) return true;
  if (RegExp(r'^〒?\d{3}-?\d{4}$').hasMatch(part)) return true;
  if (RegExp(r'^[\d〇一二三四五六七八九十百千０-９0-9\-−‐‑–—―−]+$').hasMatch(part))
    return true;
  if (RegExp(r'[丁目番号\d０-９\-−]$').hasMatch(part)) return true;
  if (part.contains('県') &&
      (part.contains('市') || part.contains('町') || part.contains('村')) &&
      RegExp(r'[丁目\d０-９\-−]$').hasMatch(part)) return true;
  return false;
}

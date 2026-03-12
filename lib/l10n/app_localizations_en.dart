// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get change => 'Change';

  @override
  String get register => 'Register';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get shareFailed => 'Share failed';

  @override
  String get showMyLocation => 'Show my location';

  @override
  String get sleepSettings => 'Screen sleep settings';

  @override
  String get switchGpsLevel => 'Switch location level';

  @override
  String get gpxImport => 'Import GPX file';

  @override
  String get gpxExport => 'Export GPX file';

  @override
  String get gpxExportDialogTitle => 'File name';

  @override
  String get gpxExportFilenameHint => 'Enter filename (use date/time if empty)';

  @override
  String gpxExportComplete(String filename) {
    return 'Saved $filename';
  }

  @override
  String get gpxExportFailed => 'Export failed';

  @override
  String get gpxExportPermissionDenied => 'File save permission denied';

  @override
  String get poiAdd => 'Add POI';

  @override
  String get poiAddEdit => 'Add / Edit POI';

  @override
  String get poiAddByDistance => 'Add POI by distance';

  @override
  String get poiAddByMapTap => 'Add POI by map tap';

  @override
  String get poiTabAdd => 'Add POI';

  @override
  String get poiTabEdit => 'Edit / Delete POI';

  @override
  String get poiType => 'POI type';

  @override
  String get checkpoint => 'Checkpoint';

  @override
  String get information => 'Information';

  @override
  String get title => 'Title';

  @override
  String get body => 'Body';

  @override
  String get distance => 'Distance';

  @override
  String get titleNone => '(No title)';

  @override
  String get kmRequired => 'Distance is required';

  @override
  String get offRoute => 'Off route';

  @override
  String kmPoint(String km) {
    return '${km}km point';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI at $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'Edit POI';

  @override
  String get changePoiPosition => 'Change to this position';

  @override
  String get dragMarkerHint => 'Drag the marker to change position';

  @override
  String get longPressPoiHint =>
      'Long press the point where you want to add a POI';

  @override
  String get poiRegistered => 'POI registered';

  @override
  String get poiAddedFromShare => 'POI added from shared link';

  @override
  String get shareUrlInvalid =>
      'Could not extract coordinates from shared link';

  @override
  String get registerThisPlaceAsPoi => 'Register this location as POI?';

  @override
  String get poiUpdated => 'POI updated';

  @override
  String get poiDeleted => 'POI deleted';

  @override
  String get poiPositionChanged => 'POI position changed';

  @override
  String get changePoiText => 'Change POI title and body';

  @override
  String get changePoiPositionTitle => 'Change POI position';

  @override
  String get deletePoiConfirm => 'Delete this POI?';

  @override
  String get noPoiRegistered => 'No POI registered';

  @override
  String get changePoiTextTitle => 'Change POI content';

  @override
  String get routeOverwrite => 'Overwrite current route';

  @override
  String get selectGpxFile => 'Please select a GPX file';

  @override
  String get routeNotLoaded => 'Route is not loaded';

  @override
  String get kmPointNotFound => 'Specified km point not found';

  @override
  String get gpxInvalidFormat => 'This file is not in GPX format';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX does not contain route or waypoints';

  @override
  String get locationFailed => 'Failed to get location';

  @override
  String get mapStyleNormal => 'Show map in normal mode';

  @override
  String get mapStyleDark => 'Show map in dark mode';

  @override
  String get showFullRoute => 'Show full route';

  @override
  String get locationUnavailable => 'Location unavailable';

  @override
  String get locationUnavailableWithRetry =>
      'Location unavailable. Tap \"Show my location\" to retry, or allow location access in settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get locationInvalid => 'Location is invalid';

  @override
  String get locationServiceOff =>
      'Location service is off. Please turn it on in device settings.';

  @override
  String get locationPermissionRequired => 'Location permission required';

  @override
  String get locationPermissionDenied =>
      'Location permission was denied. You cannot show your location without permission.';

  @override
  String get locationPermissionDeniedForever =>
      'Location permission is set to \"Don\'t ask again\". Please enable it in app settings.';

  @override
  String get sleepOffMessage => 'Screen sleep turned off';

  @override
  String sleepSetMessage(int minutes) {
    return 'Screen sleep set to $minutes minutes';
  }

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleep1min => '1min';

  @override
  String get sleep5min => '5min';

  @override
  String get sleep10min => '10min';

  @override
  String get distanceUnit => 'Distance unit settings';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'mile';

  @override
  String get distanceUnitSetToKm => 'Distance unit set to km';

  @override
  String get distanceUnitSetToMile => 'Distance unit set to mile';

  @override
  String get checkingConnectivity => 'Checking connection...';

  @override
  String get fetchingLocation => 'Getting location...';

  @override
  String get offline => 'Offline';

  @override
  String get retryConnectivity => 'Retry';

  @override
  String get offlineMap => 'Offline Map';

  @override
  String get offlineMapMinimalMap => 'Minimal map';

  @override
  String get offlineMapStandardMap => 'Standard map';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Minimal map ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Standard map ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'Zoom: Limited';

  @override
  String get offlineMapZoomMedium => 'Zoom: Standard';

  @override
  String get offlineMapZoomLarge => 'Zoom: Extended';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'Zoom: Limited ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'Zoom: Standard ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'Zoom: Extended ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'Network connection is required to download offline maps';

  @override
  String get offlineMapNoRoute =>
      'Route is not loaded. Please import a GPX file first.';

  @override
  String get offlineMapDownloading => 'Downloading ... ';

  @override
  String get offlineMapCancel => 'Cancel';

  @override
  String get offlineMapDownloadComplete => 'Offline map download complete';

  @override
  String get offlineMapDownloadFailed => 'Download failed';

  @override
  String get offlineMapDownloadCancelled => 'Download cancelled';

  @override
  String get offlineMapWifiRecommendation =>
      'We recommend downloading over Wi-Fi due to the large data size';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'We recommend downloading over Wi-Fi due to the large data size.\n\nEstimated size: ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'Stored: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'Clear cache ($size)';
  }

  @override
  String get offlineMapCacheClear => 'Clear cache';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'When cache data (including offline maps) grows, map display can become slower.\n\nMap display flow:\n\n1. Cache lookup\n2-1. If cached:\nno network access\n2-2. If not cached:\nnetwork access and save to cache\n3. Map display\n\nStep 1 cache lookup takes more time when data is larger. So if the map becomes slow or you have saved a large offline map for brevet, we recommend deleting the cache.';

  @override
  String get offlineMapCacheClearConfirmButton => 'Delete';

  @override
  String get offlineMapCacheCleared => 'Cache cleared';
}

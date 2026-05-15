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
  String get appTitleBrand => 'Brevet Map';

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
  String get add => 'Add';

  @override
  String get next => 'Next';

  @override
  String get settings => 'Settings';

  @override
  String get share => 'Share';

  @override
  String get shareFailed => 'Share failed';

  @override
  String get showMyLocation => 'Show my location';

  @override
  String get sleepSettings => 'Screen Sleep';

  @override
  String get sleepInfoMessage1 =>
      'GPS turns off when the screen sleeps, so we recommend enabling screen sleep if you want to reduce battery usage';

  @override
  String get sleepInfoDontShowAgain => 'Don\'t show again';

  @override
  String get switchGpsLevel => 'Location accuracy';

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
  String get gpxExportSaveLocationMessage =>
      'By default, exported files are saved in the following locations:\n\niOS:\n[On My iPhone] > [Brevet MAP]\n\nAndroid:\n[Files] > [Downloads]';

  @override
  String get poiAdd => 'Add POI';

  @override
  String get poiAddEdit => 'Add or Edit POI';

  @override
  String get poiAddByDistance => 'Add POI at distance';

  @override
  String get poiAddByMapTap => 'Add POI from map tap';

  @override
  String get poiTabAdd => 'Add POI';

  @override
  String get poiTabEdit => 'Edit POI';

  @override
  String get poiType => 'POI type';

  @override
  String get checkpoint => 'Checkpoint';

  @override
  String get information => 'Info';

  @override
  String get poiTypePhotoCheck => 'Photo';

  @override
  String get poiTypeStore => 'Store';

  @override
  String get poiTypeHotel => 'Hotel';

  @override
  String get poiTypeDining => 'Restaurant';

  @override
  String get poiTypeStation => 'Station';

  @override
  String get title => 'Title';

  @override
  String get body => 'Body';

  @override
  String get plannedArrival => 'Arrival';

  @override
  String get plannedDeparture => 'Departure';

  @override
  String get plannedClose => 'Cutoff';

  @override
  String get arrivalShort => 'Arrival';

  @override
  String get departureShort => 'Departure';

  @override
  String get distance => 'Distance';

  @override
  String get titleNone => '(No title)';

  @override
  String get kmRequired => 'Distance is required';

  @override
  String get routeLegOutboundShort => 'Outbound';

  @override
  String get routeLegReturnShort => 'Return';

  @override
  String get routeLegAmbiguousShort => 'Undetermined';

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
  String get changePoiPosition => 'Set this position';

  @override
  String get poiRegistered => 'POI added';

  @override
  String get poiAddedFromShare => 'POI added from shared link';

  @override
  String get shareUrlInvalid =>
      'Could not extract coordinates from shared link';

  @override
  String get registerThisPlaceAsPoi => 'Add POI at this location';

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
  String get kmExceedsRoute => 'Exceeds the total route distance';

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
  String get debugMapTilesMenu => 'Map tiles (debug)';

  @override
  String get debugMapTilesDialogTitle => 'Debug map tiles';

  @override
  String get debugMapTilesOptionDefaultOsm => 'Default (OSM)';

  @override
  String get debugMapTilesOptionCartoVoyager => 'CARTO Voyager raster';

  @override
  String get debugMapTilesDialogCancel => 'Cancel';

  @override
  String get mapStyleDebugCartoVoyager => 'Switch to Voyager raster tile';

  @override
  String get mapStyleDebugCartoLight => 'Switch to light_all raster tile';

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
  String get sleepOffMessage => 'Screen sleep disabled';

  @override
  String get sleepOnMessage => 'Screen sleep enabled';

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleepOn => 'ON';

  @override
  String get sleepSettingsNote =>
      'Check the screen sleep duration in your device\'s Settings app';

  @override
  String get openSettingsApp => 'Open Settings app';

  @override
  String get distanceUnit => 'Distance Unit';

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
  String get offlineMapMinimalMap => 'Max zoom: 15';

  @override
  String get offlineMapStandardMap => 'Max zoom: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Max zoom: 15 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Max zoom: 16 ($size)';
  }

  @override
  String get offlineMapHighResMap => 'Max zoom: 17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return 'Max zoom: 17 ($size)';
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
  String get offlineMapDownloading => 'Downloading... ';

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

  @override
  String get offlineMapInfoMessage1 =>
      'Offline maps reduce network access and save battery even when online';

  @override
  String get offlineMapInfoMessage2 =>
      'To keep the app running smoothly, we recommend deleting downloaded maps when you no longer need them';

  @override
  String get offlineMapInfoButton => 'Download';

  @override
  String get registerAtPosition => 'Add here';

  @override
  String get locationSharing => 'Location Sharing';

  @override
  String get aboutApp => 'About this app';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get rateApp => 'Rate this app';

  @override
  String get contactUs => 'Contact';

  @override
  String get language => 'Language';

  @override
  String get useSystemLanguage => 'System default';

  @override
  String get appSettingsTitle => 'Settings & More';

  @override
  String get contactFormMailError => 'Could not open mail app';

  @override
  String get batteryLevelDisplay => 'Show battery level';

  @override
  String get batteryLevelDisplayOn => 'On';

  @override
  String get batteryLevelDisplayOff => 'Off';

  @override
  String get batteryLevelDisplayIosNote =>
      'On iOS, values are shown in 5% increments due to OS limitations';

  @override
  String get trialInfoClose => 'Close';

  @override
  String get trialInfoSubscribe => 'Subscription';

  @override
  String get trialInfoMessage =>
      'Try POI adding and GPX export features free for 30 days.';

  @override
  String trialInfoRemainingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days remaining',
      one: '1 day remaining',
    );
    return '$_temp0';
  }

  @override
  String get poiPremiumMessage =>
      'Subscribe to Brevet MAP Premium to edit and delete POIs!';

  @override
  String get poiPremiumViewPlans => 'View Plans';

  @override
  String get subscription => 'Subscription';

  @override
  String get restorePurchases => 'Restore Purchases';

  @override
  String get restorePurchasesSuccess => 'Purchases restored';

  @override
  String subscriptionAccountId(String id) {
    return 'Account ID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return 'Expires: $date';
  }

  @override
  String get subscriptionNotActive => 'Not subscribed';

  @override
  String get subscriptionTerms => 'Subscription Terms';

  @override
  String get manageSubscription => 'Manage Subscription';

  @override
  String get subscriptionPremiumBlurb =>
      'Brevet Map Premium unlocks POI editing and deletion on the map for each subscription period you purchase.';

  @override
  String subscriptionCurrentPlan(String name) {
    return 'Current plan: $name';
  }

  @override
  String subscriptionPlanBillingUnit(String unit) {
    return 'Billing: $unit';
  }

  @override
  String get subscriptionUnitMonthly => 'Monthly';

  @override
  String get subscriptionUnitYearly => 'Yearly';

  @override
  String get subscriptionUnitWeekly => 'Weekly';

  @override
  String get subscriptionExpiryNoDate =>
      'Premium is active; the renewal date could not be loaded.';

  @override
  String get subscriptionAvailablePlans => 'Plans & pricing';

  @override
  String get subscriptionPlansLoadError =>
      'Could not load subscription plans. Check your connection and try again.';

  @override
  String get subscriptionPlansNotConfigured =>
      'No subscription plans are available from the store right now.';

  @override
  String subscriptionPlanRow(String title, String price, String periodSuffix) {
    return '$title\n$price$periodSuffix';
  }

  @override
  String subscriptionPeriodPart(String period) {
    return ' · $period';
  }

  @override
  String get subscriptionBillingPeriodWeek => 'per week';

  @override
  String get subscriptionBillingPeriodMonth => 'per month';

  @override
  String get subscriptionBillingPeriodThreeMonths => 'per 3 months';

  @override
  String get subscriptionBillingPeriodSixMonths => 'per 6 months';

  @override
  String get subscriptionBillingPeriodYear => 'per year';

  @override
  String subscriptionBillingPeriodUnknown(String code) {
    return 'Period: $code';
  }

  @override
  String get linkPrivacyPolicy => 'Privacy Policy';

  @override
  String get linkTermsOfUse => 'Terms of Use';

  @override
  String get subscriptionOpenPaywall => 'Subscribe or change plan';

  @override
  String get sampleRouteDialogMessage =>
      'The route shown on the map is a sample route. For actual use, please import and use a GPX file exported from a cycling app or provided by an event.';

  @override
  String get volumeButtonTutorial =>
      'You can adjust the map zoom level using the device\'s volume buttons';

  @override
  String get save => 'Save';

  @override
  String get saveChangesConfirm => 'Save changes?';

  @override
  String get setStartDate => 'Set start date';

  @override
  String get changeRideDate => 'Change ride date';

  @override
  String get releaseNotesDialogTitle => 'Release notes';

  @override
  String get releaseNotesV11018Message =>
      'In version 1.1, we\'ve added more POI details so you can plan your brevet rides more effectively!\nAll features are unlocked in this version, so feel free to give it a try!';

  @override
  String get releaseNotesV12019Message =>
      'In version 1.2, POI information has been significantly enhanced!\nAll features are unlocked in this version, so feel free to give it a try!\n\n- Added new POI types such as photo checks and stores\n- Added URL link support to POI information\n- Added elevation graph display between PCs\n- Added automatic estimated arrival times for PCs';

  @override
  String get poiSaveAsNote => 'Save as note';

  @override
  String get brevetTimeLimitLabel => 'Time limit';

  @override
  String get poiCheckInConfirmMessage => 'Check in?';

  @override
  String poiCheckInTooFarFromPoi(String thresholdKm) {
    return 'To check in, you must be within $thresholdKm km of this POI.';
  }

  @override
  String get poiCheckInFetchingLocation => 'Getting location…';

  @override
  String get poiCheckInNotAvailableTitle => 'Cannot check in';

  @override
  String get poiCheckInLocationAcquireFailedTitle => 'Could not get location';

  @override
  String get poiCheckInLocationUnavailableDetail =>
      'Your current location could not be obtained. Try again outdoors if you can, or check GPS, Location in your device settings, and app permissions.';
}

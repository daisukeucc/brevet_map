import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('th'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Do not translate. Use "Brevet Map" in all non-Japanese locales.
  ///
  /// In en, this message translates to:
  /// **'Brevet Map'**
  String get appTitle;

  /// Brand name. Do not translate. Always Brevet Map in all locales.
  ///
  /// In en, this message translates to:
  /// **'Brevet Map'**
  String get appTitleBrand;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @ng.
  ///
  /// In en, this message translates to:
  /// **'NG'**
  String get ng;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed'**
  String get shareFailed;

  /// No description provided for @showMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get showMyLocation;

  /// No description provided for @sleepSettings.
  ///
  /// In en, this message translates to:
  /// **'Screen Sleep'**
  String get sleepSettings;

  /// No description provided for @sleepInfoMessage1.
  ///
  /// In en, this message translates to:
  /// **'GPS turns off when the screen sleeps, so we recommend enabling screen sleep if you want to reduce battery usage'**
  String get sleepInfoMessage1;

  /// No description provided for @sleepInfoDontShowAgain.
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get sleepInfoDontShowAgain;

  /// No description provided for @switchGpsLevel.
  ///
  /// In en, this message translates to:
  /// **'Location accuracy'**
  String get switchGpsLevel;

  /// No description provided for @gpxImport.
  ///
  /// In en, this message translates to:
  /// **'Import GPX file'**
  String get gpxImport;

  /// No description provided for @gpxExport.
  ///
  /// In en, this message translates to:
  /// **'Export GPX file'**
  String get gpxExport;

  /// No description provided for @gpxExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'File name'**
  String get gpxExportDialogTitle;

  /// No description provided for @gpxExportFilenameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter filename (use date/time if empty)'**
  String get gpxExportFilenameHint;

  /// No description provided for @gpxExportComplete.
  ///
  /// In en, this message translates to:
  /// **'Saved {filename}'**
  String gpxExportComplete(String filename);

  /// No description provided for @gpxExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed'**
  String get gpxExportFailed;

  /// No description provided for @gpxExportPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'File save permission denied'**
  String get gpxExportPermissionDenied;

  /// No description provided for @gpxExportSaveLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'By default, exported files are saved in the following locations:\n\niOS:\n[On My iPhone] > [Brevet MAP]\n\nAndroid:\n[Files] > [Downloads]'**
  String get gpxExportSaveLocationMessage;

  /// No description provided for @poiAdd.
  ///
  /// In en, this message translates to:
  /// **'Add POI'**
  String get poiAdd;

  /// No description provided for @poiAddEdit.
  ///
  /// In en, this message translates to:
  /// **'Add or Edit POI'**
  String get poiAddEdit;

  /// No description provided for @poiAddByDistance.
  ///
  /// In en, this message translates to:
  /// **'Add POI at distance'**
  String get poiAddByDistance;

  /// No description provided for @poiAddByMapTap.
  ///
  /// In en, this message translates to:
  /// **'Add POI from map tap'**
  String get poiAddByMapTap;

  /// No description provided for @poiTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add POI'**
  String get poiTabAdd;

  /// No description provided for @poiTabEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit POI'**
  String get poiTabEdit;

  /// No description provided for @poiType.
  ///
  /// In en, this message translates to:
  /// **'POI type'**
  String get poiType;

  /// No description provided for @checkpoint.
  ///
  /// In en, this message translates to:
  /// **'Checkpoint'**
  String get checkpoint;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get information;

  /// No description provided for @poiTypePhotoCheck.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get poiTypePhotoCheck;

  /// No description provided for @poiTypeStore.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get poiTypeStore;

  /// No description provided for @poiTypeHotel.
  ///
  /// In en, this message translates to:
  /// **'Hotel'**
  String get poiTypeHotel;

  /// No description provided for @poiTypeDining.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get poiTypeDining;

  /// No description provided for @poiTypeStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get poiTypeStation;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @body.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get body;

  /// No description provided for @plannedArrival.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get plannedArrival;

  /// No description provided for @plannedDeparture.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get plannedDeparture;

  /// No description provided for @plannedClose.
  ///
  /// In en, this message translates to:
  /// **'Cutoff'**
  String get plannedClose;

  /// No description provided for @poiArrivalActual.
  ///
  /// In en, this message translates to:
  /// **'Actual arrival'**
  String get poiArrivalActual;

  /// No description provided for @arrivalShort.
  ///
  /// In en, this message translates to:
  /// **'Arrival'**
  String get arrivalShort;

  /// No description provided for @departureShort.
  ///
  /// In en, this message translates to:
  /// **'Departure'**
  String get departureShort;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @titleNone.
  ///
  /// In en, this message translates to:
  /// **'(No title)'**
  String get titleNone;

  /// No description provided for @kmRequired.
  ///
  /// In en, this message translates to:
  /// **'Distance is required'**
  String get kmRequired;

  /// No description provided for @routeLegOutboundShort.
  ///
  /// In en, this message translates to:
  /// **'Outbound'**
  String get routeLegOutboundShort;

  /// No description provided for @routeLegReturnShort.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get routeLegReturnShort;

  /// No description provided for @routeLegAmbiguousShort.
  ///
  /// In en, this message translates to:
  /// **'Undetermined'**
  String get routeLegAmbiguousShort;

  /// No description provided for @offRoute.
  ///
  /// In en, this message translates to:
  /// **'Off route'**
  String get offRoute;

  /// No description provided for @kmPoint.
  ///
  /// In en, this message translates to:
  /// **'{km}km point'**
  String kmPoint(String km);

  /// No description provided for @poiAtKmPoint.
  ///
  /// In en, this message translates to:
  /// **'POI at {kmLabel}'**
  String poiAtKmPoint(String kmLabel);

  /// No description provided for @poiOffRoutePoi.
  ///
  /// In en, this message translates to:
  /// **'Edit POI'**
  String get poiOffRoutePoi;

  /// No description provided for @changePoiPosition.
  ///
  /// In en, this message translates to:
  /// **'Set this position'**
  String get changePoiPosition;

  /// No description provided for @poiRegistered.
  ///
  /// In en, this message translates to:
  /// **'POI added'**
  String get poiRegistered;

  /// No description provided for @poiAddedFromShare.
  ///
  /// In en, this message translates to:
  /// **'POI added from shared link'**
  String get poiAddedFromShare;

  /// No description provided for @shareUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Could not extract coordinates from shared link'**
  String get shareUrlInvalid;

  /// No description provided for @registerThisPlaceAsPoi.
  ///
  /// In en, this message translates to:
  /// **'Add POI at this location'**
  String get registerThisPlaceAsPoi;

  /// No description provided for @poiUpdated.
  ///
  /// In en, this message translates to:
  /// **'POI updated'**
  String get poiUpdated;

  /// No description provided for @poiDeleted.
  ///
  /// In en, this message translates to:
  /// **'POI deleted'**
  String get poiDeleted;

  /// No description provided for @poiPositionChanged.
  ///
  /// In en, this message translates to:
  /// **'POI position changed'**
  String get poiPositionChanged;

  /// No description provided for @changePoiText.
  ///
  /// In en, this message translates to:
  /// **'Change POI title and body'**
  String get changePoiText;

  /// No description provided for @changePoiPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'Change POI position'**
  String get changePoiPositionTitle;

  /// No description provided for @deletePoiConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this POI?'**
  String get deletePoiConfirm;

  /// No description provided for @noPoiRegistered.
  ///
  /// In en, this message translates to:
  /// **'No POI registered'**
  String get noPoiRegistered;

  /// No description provided for @changePoiTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Change POI content'**
  String get changePoiTextTitle;

  /// No description provided for @routeOverwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite current route'**
  String get routeOverwrite;

  /// No description provided for @selectGpxFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a GPX file'**
  String get selectGpxFile;

  /// No description provided for @routeNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Route is not loaded'**
  String get routeNotLoaded;

  /// No description provided for @kmPointNotFound.
  ///
  /// In en, this message translates to:
  /// **'Specified km point not found'**
  String get kmPointNotFound;

  /// No description provided for @kmExceedsRoute.
  ///
  /// In en, this message translates to:
  /// **'Exceeds the total route distance'**
  String get kmExceedsRoute;

  /// No description provided for @gpxInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'This file is not in GPX format'**
  String get gpxInvalidFormat;

  /// No description provided for @gpxNoRouteOrWaypoint.
  ///
  /// In en, this message translates to:
  /// **'GPX does not contain route or waypoints'**
  String get gpxNoRouteOrWaypoint;

  /// No description provided for @locationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location'**
  String get locationFailed;

  /// No description provided for @mapStyleNormal.
  ///
  /// In en, this message translates to:
  /// **'Show map in normal mode'**
  String get mapStyleNormal;

  /// No description provided for @mapStyleDark.
  ///
  /// In en, this message translates to:
  /// **'Show map in dark mode'**
  String get mapStyleDark;

  /// No description provided for @debugMapTilesMenu.
  ///
  /// In en, this message translates to:
  /// **'Map tiles (debug)'**
  String get debugMapTilesMenu;

  /// No description provided for @debugMapTilesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Debug map tiles'**
  String get debugMapTilesDialogTitle;

  /// No description provided for @debugMapTilesOptionDefaultOsm.
  ///
  /// In en, this message translates to:
  /// **'Default (OSM)'**
  String get debugMapTilesOptionDefaultOsm;

  /// No description provided for @debugMapTilesOptionCartoVoyager.
  ///
  /// In en, this message translates to:
  /// **'CARTO Voyager raster'**
  String get debugMapTilesOptionCartoVoyager;

  /// No description provided for @debugMapTilesDialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get debugMapTilesDialogCancel;

  /// No description provided for @mapStyleDebugCartoVoyager.
  ///
  /// In en, this message translates to:
  /// **'Switch to Voyager raster tile'**
  String get mapStyleDebugCartoVoyager;

  /// No description provided for @mapStyleDebugCartoLight.
  ///
  /// In en, this message translates to:
  /// **'Switch to light_all raster tile'**
  String get mapStyleDebugCartoLight;

  /// No description provided for @showFullRoute.
  ///
  /// In en, this message translates to:
  /// **'Show full route'**
  String get showFullRoute;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable'**
  String get locationUnavailable;

  /// No description provided for @locationUnavailableWithRetry.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable. Tap \"Show my location\" to retry, or allow location access in settings.'**
  String get locationUnavailableWithRetry;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @locationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Location is invalid'**
  String get locationInvalid;

  /// No description provided for @locationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location service is off. Please turn it on in device settings.'**
  String get locationServiceOff;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied. You cannot show your location without permission.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location permission is set to \"Don\'t ask again\". Please enable it in app settings.'**
  String get locationPermissionDeniedForever;

  /// No description provided for @sleepOffMessage.
  ///
  /// In en, this message translates to:
  /// **'Screen sleep disabled'**
  String get sleepOffMessage;

  /// No description provided for @sleepOnMessage.
  ///
  /// In en, this message translates to:
  /// **'Screen sleep enabled'**
  String get sleepOnMessage;

  /// No description provided for @sleepOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get sleepOff;

  /// No description provided for @sleepOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get sleepOn;

  /// No description provided for @sleepSettingsNote.
  ///
  /// In en, this message translates to:
  /// **'Check the screen sleep duration in your device\'s Settings app'**
  String get sleepSettingsNote;

  /// No description provided for @openSettingsApp.
  ///
  /// In en, this message translates to:
  /// **'Open Settings app'**
  String get openSettingsApp;

  /// No description provided for @distanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance Unit'**
  String get distanceUnit;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @unitMile.
  ///
  /// In en, this message translates to:
  /// **'mile'**
  String get unitMile;

  /// No description provided for @distanceUnitSetToKm.
  ///
  /// In en, this message translates to:
  /// **'Distance unit set to km'**
  String get distanceUnitSetToKm;

  /// No description provided for @distanceUnitSetToMile.
  ///
  /// In en, this message translates to:
  /// **'Distance unit set to mile'**
  String get distanceUnitSetToMile;

  /// No description provided for @checkingConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Checking connection...'**
  String get checkingConnectivity;

  /// No description provided for @fetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get fetchingLocation;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @retryConnectivity.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryConnectivity;

  /// No description provided for @offlineMap.
  ///
  /// In en, this message translates to:
  /// **'Offline Map'**
  String get offlineMap;

  /// No description provided for @offlineMapMinimalMap.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 15'**
  String get offlineMapMinimalMap;

  /// No description provided for @offlineMapStandardMap.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 16'**
  String get offlineMapStandardMap;

  /// No description provided for @offlineMapMinimalMapWithSize.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 15 ({size})'**
  String offlineMapMinimalMapWithSize(String size);

  /// No description provided for @offlineMapStandardMapWithSize.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 16 ({size})'**
  String offlineMapStandardMapWithSize(String size);

  /// No description provided for @offlineMapHighResMap.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 17'**
  String get offlineMapHighResMap;

  /// No description provided for @offlineMapHighResMapWithSize.
  ///
  /// In en, this message translates to:
  /// **'Max zoom: 17 ({size})'**
  String offlineMapHighResMapWithSize(String size);

  /// No description provided for @offlineMapZoomSmall.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Limited'**
  String get offlineMapZoomSmall;

  /// No description provided for @offlineMapZoomMedium.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Standard'**
  String get offlineMapZoomMedium;

  /// No description provided for @offlineMapZoomLarge.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Extended'**
  String get offlineMapZoomLarge;

  /// No description provided for @offlineMapZoomSmallWithSize.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Limited ({size})'**
  String offlineMapZoomSmallWithSize(String size);

  /// No description provided for @offlineMapZoomMediumWithSize.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Standard ({size})'**
  String offlineMapZoomMediumWithSize(String size);

  /// No description provided for @offlineMapZoomLargeWithSize.
  ///
  /// In en, this message translates to:
  /// **'Zoom: Extended ({size})'**
  String offlineMapZoomLargeWithSize(String size);

  /// No description provided for @offlineMapRequiresNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network connection is required to download offline maps'**
  String get offlineMapRequiresNetwork;

  /// No description provided for @offlineMapNoRoute.
  ///
  /// In en, this message translates to:
  /// **'Route is not loaded. Please import a GPX file first.'**
  String get offlineMapNoRoute;

  /// No description provided for @offlineMapDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... '**
  String get offlineMapDownloading;

  /// No description provided for @offlineMapCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get offlineMapCancel;

  /// No description provided for @offlineMapDownloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Offline map download complete'**
  String get offlineMapDownloadComplete;

  /// No description provided for @offlineMapDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get offlineMapDownloadFailed;

  /// No description provided for @offlineMapDownloadCancelled.
  ///
  /// In en, this message translates to:
  /// **'Download cancelled'**
  String get offlineMapDownloadCancelled;

  /// No description provided for @offlineMapWifiRecommendation.
  ///
  /// In en, this message translates to:
  /// **'We recommend downloading over Wi-Fi due to the large data size'**
  String get offlineMapWifiRecommendation;

  /// No description provided for @offlineMapWifiRecommendationWithSize.
  ///
  /// In en, this message translates to:
  /// **'We recommend downloading over Wi-Fi due to the large data size.\n\nEstimated size: ~{size}'**
  String offlineMapWifiRecommendationWithSize(String size);

  /// No description provided for @offlineMapCurrentStorage.
  ///
  /// In en, this message translates to:
  /// **'Stored: {size}'**
  String offlineMapCurrentStorage(String size);

  /// No description provided for @offlineMapCacheClearWithSize.
  ///
  /// In en, this message translates to:
  /// **'Clear cache ({size})'**
  String offlineMapCacheClearWithSize(String size);

  /// No description provided for @offlineMapCacheClear.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get offlineMapCacheClear;

  /// No description provided for @offlineMapCacheClearConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'When cache data (including offline maps) grows, map display can become slower.\n\nMap display flow:\n\n1. Cache lookup\n2-1. If cached:\nno network access\n2-2. If not cached:\nnetwork access and save to cache\n3. Map display\n\nStep 1 cache lookup takes more time when data is larger. So if the map becomes slow or you have saved a large offline map for brevet, we recommend deleting the cache.'**
  String get offlineMapCacheClearConfirmMessage;

  /// No description provided for @offlineMapCacheClearConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get offlineMapCacheClearConfirmButton;

  /// No description provided for @offlineMapCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get offlineMapCacheCleared;

  /// No description provided for @offlineMapInfoMessage1.
  ///
  /// In en, this message translates to:
  /// **'Offline maps reduce network access and save battery even when online'**
  String get offlineMapInfoMessage1;

  /// No description provided for @offlineMapInfoMessage2.
  ///
  /// In en, this message translates to:
  /// **'To keep the app running smoothly, we recommend deleting downloaded maps when you no longer need them'**
  String get offlineMapInfoMessage2;

  /// No description provided for @offlineMapInfoButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get offlineMapInfoButton;

  /// No description provided for @registerAtPosition.
  ///
  /// In en, this message translates to:
  /// **'Add here'**
  String get registerAtPosition;

  /// No description provided for @locationSharing.
  ///
  /// In en, this message translates to:
  /// **'Location Sharing'**
  String get locationSharing;

  /// No description provided for @checkInSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get checkInSettingsTitle;

  /// No description provided for @checkInVerifyLocationRadioOn.
  ///
  /// In en, this message translates to:
  /// **'Verify location'**
  String get checkInVerifyLocationRadioOn;

  /// No description provided for @checkInVerifyLocationRadioOff.
  ///
  /// In en, this message translates to:
  /// **'Don\'t verify location'**
  String get checkInVerifyLocationRadioOff;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About this app'**
  String get aboutApp;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate this app'**
  String get rateApp;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactUs;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @useSystemLanguage.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get useSystemLanguage;

  /// No description provided for @appSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings & More'**
  String get appSettingsTitle;

  /// No description provided for @contactFormMailError.
  ///
  /// In en, this message translates to:
  /// **'Could not open mail app'**
  String get contactFormMailError;

  /// No description provided for @batteryLevelDisplay.
  ///
  /// In en, this message translates to:
  /// **'Show battery level'**
  String get batteryLevelDisplay;

  /// No description provided for @batteryLevelDisplayOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get batteryLevelDisplayOn;

  /// No description provided for @batteryLevelDisplayOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get batteryLevelDisplayOff;

  /// No description provided for @batteryLevelDisplayIosNote.
  ///
  /// In en, this message translates to:
  /// **'On iOS, values are shown in 5% increments due to OS limitations'**
  String get batteryLevelDisplayIosNote;

  /// No description provided for @trialInfoClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get trialInfoClose;

  /// No description provided for @trialInfoSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get trialInfoSubscribe;

  /// No description provided for @trialInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Try POI adding and GPX export features free for 30 days.'**
  String get trialInfoMessage;

  /// No description provided for @trialInfoRemainingDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day remaining} other{{days} days remaining}}'**
  String trialInfoRemainingDays(int days);

  /// No description provided for @poiPremiumMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Brevet MAP Premium to edit and delete POIs!'**
  String get poiPremiumMessage;

  /// No description provided for @poiPremiumViewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get poiPremiumViewPlans;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @restorePurchases.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get restorePurchases;

  /// No description provided for @restorePurchasesSuccess.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get restorePurchasesSuccess;

  /// No description provided for @subscriptionAccountId.
  ///
  /// In en, this message translates to:
  /// **'Account ID: {id}'**
  String subscriptionAccountId(String id);

  /// No description provided for @subscriptionExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expires: {date}'**
  String subscriptionExpiry(String date);

  /// No description provided for @subscriptionNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not subscribed'**
  String get subscriptionNotActive;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscription Terms'**
  String get subscriptionTerms;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscription;

  /// No description provided for @subscriptionPremiumBlurb.
  ///
  /// In en, this message translates to:
  /// **'Brevet Map Premium unlocks POI editing and deletion on the map for each subscription period you purchase.'**
  String get subscriptionPremiumBlurb;

  /// No description provided for @subscriptionCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan: {name}'**
  String subscriptionCurrentPlan(String name);

  /// No description provided for @subscriptionPlanBillingUnit.
  ///
  /// In en, this message translates to:
  /// **'Billing: {unit}'**
  String subscriptionPlanBillingUnit(String unit);

  /// No description provided for @subscriptionUnitMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionUnitMonthly;

  /// No description provided for @subscriptionUnitYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionUnitYearly;

  /// No description provided for @subscriptionUnitWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get subscriptionUnitWeekly;

  /// No description provided for @subscriptionExpiryNoDate.
  ///
  /// In en, this message translates to:
  /// **'Premium is active; the renewal date could not be loaded.'**
  String get subscriptionExpiryNoDate;

  /// No description provided for @subscriptionAvailablePlans.
  ///
  /// In en, this message translates to:
  /// **'Plans & pricing'**
  String get subscriptionAvailablePlans;

  /// No description provided for @subscriptionPlansLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load subscription plans. Check your connection and try again.'**
  String get subscriptionPlansLoadError;

  /// No description provided for @subscriptionPlansNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'No subscription plans are available from the store right now.'**
  String get subscriptionPlansNotConfigured;

  /// No description provided for @subscriptionPlanRow.
  ///
  /// In en, this message translates to:
  /// **'{title}\n{price}{periodSuffix}'**
  String subscriptionPlanRow(String title, String price, String periodSuffix);

  /// No description provided for @subscriptionPeriodPart.
  ///
  /// In en, this message translates to:
  /// **' · {period}'**
  String subscriptionPeriodPart(String period);

  /// No description provided for @subscriptionBillingPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'per week'**
  String get subscriptionBillingPeriodWeek;

  /// No description provided for @subscriptionBillingPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subscriptionBillingPeriodMonth;

  /// No description provided for @subscriptionBillingPeriodThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'per 3 months'**
  String get subscriptionBillingPeriodThreeMonths;

  /// No description provided for @subscriptionBillingPeriodSixMonths.
  ///
  /// In en, this message translates to:
  /// **'per 6 months'**
  String get subscriptionBillingPeriodSixMonths;

  /// No description provided for @subscriptionBillingPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get subscriptionBillingPeriodYear;

  /// No description provided for @subscriptionBillingPeriodUnknown.
  ///
  /// In en, this message translates to:
  /// **'Period: {code}'**
  String subscriptionBillingPeriodUnknown(String code);

  /// No description provided for @linkPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get linkPrivacyPolicy;

  /// No description provided for @linkTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get linkTermsOfUse;

  /// No description provided for @subscriptionOpenPaywall.
  ///
  /// In en, this message translates to:
  /// **'Subscribe or change plan'**
  String get subscriptionOpenPaywall;

  /// No description provided for @sampleRouteDialogMessage.
  ///
  /// In en, this message translates to:
  /// **'The route shown on the map is a sample route. For actual use, please import and use a GPX file exported from a cycling app or provided by an event.'**
  String get sampleRouteDialogMessage;

  /// No description provided for @volumeButtonTutorial.
  ///
  /// In en, this message translates to:
  /// **'You can adjust the map zoom level using the device\'s volume buttons'**
  String get volumeButtonTutorial;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saveChangesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save changes?'**
  String get saveChangesConfirm;

  /// No description provided for @setStartDate.
  ///
  /// In en, this message translates to:
  /// **'Set start date'**
  String get setStartDate;

  /// No description provided for @changeRideDate.
  ///
  /// In en, this message translates to:
  /// **'Change ride date'**
  String get changeRideDate;

  /// No description provided for @releaseNotesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Release notes'**
  String get releaseNotesDialogTitle;

  /// No description provided for @releaseNotesV11018Message.
  ///
  /// In en, this message translates to:
  /// **'In version 1.1, we\'ve added more POI details so you can plan your brevet rides more effectively!\nAll features are unlocked in this version, so feel free to give it a try!'**
  String get releaseNotesV11018Message;

  /// No description provided for @releaseNotesV12019Message.
  ///
  /// In en, this message translates to:
  /// **'In version 1.2, POI information has been significantly enhanced!\nAll features are unlocked in this version, so feel free to give it a try!\n\n- Added new POI types such as photo checks and stores\n- Added URL link support to POI information\n- Added elevation graph display between PCs\n- Added automatic estimated arrival times for PCs'**
  String get releaseNotesV12019Message;

  /// No description provided for @poiSaveAsNote.
  ///
  /// In en, this message translates to:
  /// **'Save as note'**
  String get poiSaveAsNote;

  /// Label for brevet time limit hours on the start POI elevation dialog (shown before a colon and the hours value).
  ///
  /// In en, this message translates to:
  /// **'Time limit'**
  String get brevetTimeLimitLabel;

  /// No description provided for @poiCheckInConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Check in?'**
  String get poiCheckInConfirmMessage;

  /// Body text when GPS shows the device is farther than the allowed radius ({thresholdKm} km) from the POI.
  ///
  /// In en, this message translates to:
  /// **'To check in, you must be within {thresholdKm} km of this POI.'**
  String poiCheckInTooFarFromPoi(String thresholdKm);

  /// No description provided for @poiCheckInFetchingLocation.
  ///
  /// In en, this message translates to:
  /// **'Getting location…'**
  String get poiCheckInFetchingLocation;

  /// No description provided for @poiCheckInNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot check in'**
  String get poiCheckInNotAvailableTitle;

  /// No description provided for @poiCheckInLocationAcquireFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not get location'**
  String get poiCheckInLocationAcquireFailedTitle;

  /// No description provided for @poiCheckInLocationUnavailableDetail.
  ///
  /// In en, this message translates to:
  /// **'Your current location could not be obtained. Try again outdoors if you can, or check GPS, Location in your device settings, and app permissions.'**
  String get poiCheckInLocationUnavailableDetail;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'th',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

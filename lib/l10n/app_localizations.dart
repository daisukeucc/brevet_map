import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('en'),
    Locale('ja')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Brevet Map'**
  String get appTitle;

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

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @showMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Show my location'**
  String get showMyLocation;

  /// No description provided for @sleepSettings.
  ///
  /// In en, this message translates to:
  /// **'Screen sleep settings'**
  String get sleepSettings;

  /// No description provided for @switchGpsLevel.
  ///
  /// In en, this message translates to:
  /// **'Switch location level'**
  String get switchGpsLevel;

  /// No description provided for @gpxImport.
  ///
  /// In en, this message translates to:
  /// **'Import GPX file'**
  String get gpxImport;

  /// No description provided for @poiAdd.
  ///
  /// In en, this message translates to:
  /// **'Add POI'**
  String get poiAdd;

  /// No description provided for @poiAddEdit.
  ///
  /// In en, this message translates to:
  /// **'Add / Edit POI'**
  String get poiAddEdit;

  /// No description provided for @poiAddByDistance.
  ///
  /// In en, this message translates to:
  /// **'Add POI by distance'**
  String get poiAddByDistance;

  /// No description provided for @poiAddByMapTap.
  ///
  /// In en, this message translates to:
  /// **'Add POI by map tap'**
  String get poiAddByMapTap;

  /// No description provided for @poiTabAdd.
  ///
  /// In en, this message translates to:
  /// **'Add POI'**
  String get poiTabAdd;

  /// No description provided for @poiTabEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit / Delete POI'**
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
  /// **'Information'**
  String get information;

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
  /// **'Manually set POI'**
  String get poiOffRoutePoi;

  /// No description provided for @changePoiPosition.
  ///
  /// In en, this message translates to:
  /// **'Change to this position'**
  String get changePoiPosition;

  /// No description provided for @dragMarkerHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the marker to change position'**
  String get dragMarkerHint;

  /// No description provided for @longPressPoiHint.
  ///
  /// In en, this message translates to:
  /// **'Long press the point where you want to add a POI'**
  String get longPressPoiHint;

  /// No description provided for @poiRegistered.
  ///
  /// In en, this message translates to:
  /// **'POI registered'**
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
  /// **'Register this location as POI?'**
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
  /// **'Change POI title and body'**
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
  /// **'Screen sleep turned off'**
  String get sleepOffMessage;

  /// No description provided for @sleepSetMessage.
  ///
  /// In en, this message translates to:
  /// **'Screen sleep set to {minutes} minutes'**
  String sleepSetMessage(int minutes);

  /// No description provided for @sleepOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get sleepOff;

  /// No description provided for @sleep1min.
  ///
  /// In en, this message translates to:
  /// **'1min'**
  String get sleep1min;

  /// No description provided for @sleep5min.
  ///
  /// In en, this message translates to:
  /// **'5min'**
  String get sleep5min;

  /// No description provided for @sleep10min.
  ///
  /// In en, this message translates to:
  /// **'10min'**
  String get sleep10min;

  /// No description provided for @distanceUnit.
  ///
  /// In en, this message translates to:
  /// **'Distance unit settings'**
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

  /// No description provided for @offlineMapNoRoute.
  ///
  /// In en, this message translates to:
  /// **'Route is not loaded. Please import a GPX file first.'**
  String get offlineMapNoRoute;

  /// No description provided for @offlineMapDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading ... '**
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
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

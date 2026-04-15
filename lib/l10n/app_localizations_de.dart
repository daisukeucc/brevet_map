// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Löschen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get change => 'Ändern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get share => 'Teilen';

  @override
  String get shareFailed => 'Teilen fehlgeschlagen';

  @override
  String get showMyLocation => 'Meinen Standort anzeigen';

  @override
  String get sleepSettings => 'Bildschirmschlaf';

  @override
  String get sleepInfoMessage1 =>
      'Das GPS schaltet sich beim Bildschirmschlaf aus. Wir empfehlen daher, den Bildschirmschlaf zu aktivieren, wenn Sie den Akkuverbrauch reduzieren möchten.';

  @override
  String get sleepInfoDontShowAgain => 'Nicht mehr anzeigen';

  @override
  String get switchGpsLevel => 'Standortgenauigkeit';

  @override
  String get gpxImport => 'GPX-Datei importieren';

  @override
  String get gpxExport => 'GPX-Datei exportieren';

  @override
  String get gpxExportDialogTitle => 'Dateiname';

  @override
  String get gpxExportFilenameHint =>
      'Dateiname eingeben (Datum/Uhrzeit bei leerem Feld)';

  @override
  String gpxExportComplete(String filename) {
    return 'Gespeichert $filename';
  }

  @override
  String get gpxExportFailed => 'Export fehlgeschlagen';

  @override
  String get gpxExportPermissionDenied => 'Dateispeicherung verweigert';

  @override
  String get gpxExportSaveLocationMessage =>
      'Standardmäßig werden exportierte Dateien an folgenden Orten gespeichert:\n\niOS:\n[Auf meinem iPhone] > [Brevet MAP]\n\nAndroid:\n[Files] > [Downloads]';

  @override
  String get poiAdd => 'POI hinzufügen';

  @override
  String get poiAddEdit => 'POI hinzufügen oder bearbeiten';

  @override
  String get poiAddByDistance => 'POI bei Distanz hinzufügen';

  @override
  String get poiAddByMapTap => 'POI durch Tippen auf die Karte hinzufügen';

  @override
  String get poiTabAdd => 'POI hinzufügen';

  @override
  String get poiTabEdit => 'POI bearbeiten oder löschen';

  @override
  String get poiType => 'POI-Typ';

  @override
  String get checkpoint => 'Kontrollpunkt';

  @override
  String get information => 'Information';

  @override
  String get title => 'Titel';

  @override
  String get body => 'Text';

  @override
  String get distance => 'Distanz';

  @override
  String get titleNone => '(Kein Titel)';

  @override
  String get kmRequired => 'Distanz ist erforderlich';

  @override
  String get offRoute => 'Außerhalb der Strecke';

  @override
  String kmPoint(String km) {
    return 'Punkt $km km';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI bei Punkt $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'POI bearbeiten';

  @override
  String get changePoiPosition => 'Diese Position festlegen';

  @override
  String get poiRegistered => 'POI hinzugefügt';

  @override
  String get poiAddedFromShare => 'POI von geteiltem Link hinzugefügt';

  @override
  String get shareUrlInvalid =>
      'Koordinaten konnten nicht aus dem geteilten Link extrahiert werden';

  @override
  String get registerThisPlaceAsPoi => 'POI hier hinzufügen';

  @override
  String get poiUpdated => 'POI aktualisiert';

  @override
  String get poiDeleted => 'POI gelöscht';

  @override
  String get poiPositionChanged => 'POI-Position geändert';

  @override
  String get changePoiText => 'POI-Titel und -Text ändern';

  @override
  String get changePoiPositionTitle => 'POI-Position ändern';

  @override
  String get deletePoiConfirm => 'Diesen POI löschen?';

  @override
  String get noPoiRegistered => 'Kein POI hinzugefügt';

  @override
  String get changePoiTextTitle => 'POI-Inhalt ändern';

  @override
  String get routeOverwrite => 'Aktuelle Strecke überschreiben';

  @override
  String get selectGpxFile => 'Bitte wählen Sie eine GPX-Datei';

  @override
  String get routeNotLoaded => 'Strecke ist nicht geladen';

  @override
  String get kmPointNotFound => 'Angegebener km-Punkt nicht gefunden';

  @override
  String get kmExceedsRoute => 'Überschreitet die Gesamtstreckenlänge';

  @override
  String get gpxInvalidFormat => 'Diese Datei ist kein GPX-Format';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX enthält keine Strecke oder Wegpunkte';

  @override
  String get locationFailed => 'Standort konnte nicht ermittelt werden';

  @override
  String get mapStyleNormal => 'Karte im Normalmodus anzeigen';

  @override
  String get mapStyleDark => 'Karte im Dunkelmodus anzeigen';

  @override
  String get showFullRoute => 'Vollständige Strecke anzeigen';

  @override
  String get locationUnavailable => 'Standort nicht verfügbar';

  @override
  String get locationUnavailableWithRetry =>
      'Standort nicht verfügbar. Tippen Sie auf \"Meinen Standort anzeigen\" zum Wiederholen oder erlauben Sie den Standortzugriff in den Einstellungen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get locationInvalid => 'Standort ungültig';

  @override
  String get locationServiceOff =>
      'Standortdienst ist ausgeschaltet. Bitte aktivieren Sie ihn in den Geräteeinstellungen.';

  @override
  String get locationPermissionRequired => 'Standortberechtigung erforderlich';

  @override
  String get locationPermissionDenied =>
      'Standortberechtigung wurde verweigert. Ohne Berechtigung kann Ihr Standort nicht angezeigt werden.';

  @override
  String get locationPermissionDeniedForever =>
      'Standortberechtigung ist auf \"Nicht erneut fragen\" gesetzt. Bitte aktivieren Sie sie in den App-Einstellungen.';

  @override
  String get sleepOffMessage => 'Bildschirmschlaf deaktiviert';

  @override
  String get sleepOnMessage => 'Bildschirmschlaf aktiviert';

  @override
  String get sleepOff => 'AUS';

  @override
  String get sleepOn => 'EIN';

  @override
  String get sleepSettingsNote =>
      'Die Dauer des Bildschirmschlafs finden Sie in der Einstellungs-App Ihres Geräts';

  @override
  String get openSettingsApp => 'Einstellungs-App öffnen';

  @override
  String get distanceUnit => 'Distanzeinheit';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'Meilen';

  @override
  String get distanceUnitSetToKm => 'Distanzeinheit auf km gesetzt';

  @override
  String get distanceUnitSetToMile => 'Distanzeinheit auf Meilen gesetzt';

  @override
  String get checkingConnectivity => 'Verbindung wird geprüft...';

  @override
  String get fetchingLocation => 'Standort wird ermittelt...';

  @override
  String get offline => 'Offline';

  @override
  String get retryConnectivity => 'Wiederholen';

  @override
  String get offlineMap => 'Offline-Karte';

  @override
  String get offlineMapMinimalMap => 'Max. Zoom: 15';

  @override
  String get offlineMapStandardMap => 'Max. Zoom: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Max. Zoom: 15 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Max. Zoom: 16 ($size)';
  }

  @override
  String get offlineMapHighResMap => 'Max. Zoom: 17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return 'Max. Zoom: 17 ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'Zoom: Begrenzt';

  @override
  String get offlineMapZoomMedium => 'Zoom: Standard';

  @override
  String get offlineMapZoomLarge => 'Zoom: Erweitert';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'Zoom: Begrenzt ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'Zoom: Standard ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'Zoom: Erweitert ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'Netzwerkverbindung erforderlich zum Herunterladen von Offline-Karten';

  @override
  String get offlineMapNoRoute =>
      'Strecke ist nicht geladen. Bitte importieren Sie zuerst eine GPX-Datei.';

  @override
  String get offlineMapDownloading => 'Wird heruntergeladen... ';

  @override
  String get offlineMapCancel => 'Abbrechen';

  @override
  String get offlineMapDownloadComplete =>
      'Offline-Karten-Download abgeschlossen';

  @override
  String get offlineMapDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get offlineMapDownloadCancelled => 'Download abgebrochen';

  @override
  String get offlineMapWifiRecommendation =>
      'Wir empfehlen das Herunterladen über WLAN wegen der großen Datenmenge';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'Wir empfehlen das Herunterladen über WLAN wegen der großen Datenmenge.\n\nGeschätzte Größe: ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'Gespeichert: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'Cache leeren ($size)';
  }

  @override
  String get offlineMapCacheClear => 'Cache leeren';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'Wenn Cache-Daten (einschließlich Offline-Karten) zunehmen, kann die Kartenanzeige langsamer werden.\n\nAblauf der Kartenanzeige:\n\n1. Cache-Abfrage\n2-1. Im Cache:\nKein Netzwerkzugriff\n2-2. Nicht im Cache:\nNetzwerkzugriff und Speicherung im Cache\n3. Kartenanzeige\n\nSchritt 1 Cache-Abfrage dauert bei größeren Daten länger. Bei langsamer Kartenanzeige oder großen Offline-Karten für Brevet wird die Löschung des Caches empfohlen.';

  @override
  String get offlineMapCacheClearConfirmButton => 'Löschen';

  @override
  String get offlineMapCacheCleared => 'Cache geleert';

  @override
  String get offlineMapInfoMessage1 =>
      'Offline-Karten reduzieren den Netzwerkzugriff und sparen Akku, auch wenn Sie online sind';

  @override
  String get offlineMapInfoMessage2 =>
      'Für eine reibungslose App-Nutzung empfehlen wir, heruntergeladene Karten zu löschen, wenn Sie sie nicht mehr benötigen';

  @override
  String get offlineMapInfoButton => 'Herunterladen';

  @override
  String get registerAtPosition => 'Hier hinzufügen';

  @override
  String get locationSharing => 'Standort teilen';

  @override
  String get aboutApp => 'Über diese App';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get rateApp => 'App bewerten';

  @override
  String get contactUs => 'Kontakt';

  @override
  String get language => 'Sprache';

  @override
  String get useSystemLanguage => 'Systemsprache';

  @override
  String get appSettingsTitle => 'Einstellungen & mehr';

  @override
  String get contactFormMailError => 'Mail-App konnte nicht geöffnet werden';

  @override
  String get batteryLevelDisplay => 'Akkustand anzeigen';

  @override
  String get batteryLevelDisplayOn => 'Anzeigen';

  @override
  String get batteryLevelDisplayOff => 'Ausblenden';

  @override
  String get batteryLevelDisplayIosNote =>
      'Auf iOS werden die Werte aufgrund von Betriebssystemeinschränkungen in 5%-Schritten angezeigt';

  @override
  String get trialInfoClose => 'Schließen';

  @override
  String get trialInfoSubscribe => 'Abonnement';

  @override
  String get trialInfoMessage =>
      'Testen Sie das Hinzufügen von POIs und den GPX-Export 30 Tage lang kostenlos.';

  @override
  String trialInfoRemainingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Noch $days Tage',
      one: 'Noch 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get poiPremiumMessage =>
      'Mit Brevet MAP Premium können Sie POIs bearbeiten und löschen!';

  @override
  String get poiPremiumViewPlans => 'Pläne anzeigen';

  @override
  String get subscription => 'Abonnement';

  @override
  String get restorePurchases => 'Käufe wiederherstellen';

  @override
  String get restorePurchasesSuccess => 'Käufe wurden wiederhergestellt';

  @override
  String subscriptionAccountId(String id) {
    return 'Konto-ID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return 'Ablaufdatum: $date';
  }

  @override
  String get subscriptionNotActive => 'Nicht abonniert';

  @override
  String get subscriptionTerms => 'Abonnementbedingungen';

  @override
  String get manageSubscription => 'Abonnement verwalten';

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
      'Die auf der Karte angezeigte Route ist eine Beispielroute. Zur tatsächlichen Nutzung importieren Sie bitte eine GPX-Datei aus einer Radsport-App oder von einer Veranstaltung.';

  @override
  String get volumeButtonTutorial =>
      'Sie können den Kartenzoom mit den Lautstärketasten des Geräts anpassen';
}

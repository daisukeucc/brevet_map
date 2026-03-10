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
  String get register => 'Registrieren';

  @override
  String get settings => 'Einstellungen';

  @override
  String get share => 'Teilen';

  @override
  String get shareFailed => 'Teilen fehlgeschlagen';

  @override
  String get showMyLocation => 'Meinen Standort anzeigen';

  @override
  String get sleepSettings => 'Bildschirmschlaf-Einstellungen';

  @override
  String get switchGpsLevel => 'Standortebene wechseln';

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
  String get poiAdd => 'POI hinzufügen';

  @override
  String get poiAddEdit => 'POI hinzufügen / bearbeiten';

  @override
  String get poiAddByDistance => 'POI per Distanz hinzufügen';

  @override
  String get poiAddByMapTap => 'POI per Kartenantippen hinzufügen';

  @override
  String get poiTabAdd => 'POI hinzufügen';

  @override
  String get poiTabEdit => 'POI bearbeiten / löschen';

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
  String get changePoiPosition => 'Zu dieser Position ändern';

  @override
  String get dragMarkerHint => 'Markierung ziehen, um die Position zu ändern';

  @override
  String get longPressPoiHint =>
      'Lange auf den Punkt drücken, an dem Sie einen POI hinzufügen möchten';

  @override
  String get poiRegistered => 'POI registriert';

  @override
  String get poiAddedFromShare => 'POI von geteiltem Link hinzugefügt';

  @override
  String get shareUrlInvalid =>
      'Koordinaten konnten nicht aus dem geteilten Link extrahiert werden';

  @override
  String get registerThisPlaceAsPoi => 'Diesen Ort als POI registrieren?';

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
  String get noPoiRegistered => 'Kein POI registriert';

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
  String sleepSetMessage(int minutes) {
    return 'Bildschirmschlaf auf $minutes Minuten eingestellt';
  }

  @override
  String get sleepOff => 'AUS';

  @override
  String get sleep1min => '1 Min';

  @override
  String get sleep5min => '5 Min';

  @override
  String get sleep10min => '10 Min';

  @override
  String get distanceUnit => 'Distanzeinheiten-Einstellungen';

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
  String get offlineMapDownloading => 'Wird heruntergeladen ... ';

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
}

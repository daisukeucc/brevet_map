// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get cancel => 'Annulla';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Elimina';

  @override
  String get edit => 'Modifica';

  @override
  String get change => 'Modifica';

  @override
  String get add => 'Aggiungi';

  @override
  String get settings => 'Impostazioni';

  @override
  String get share => 'Condividi';

  @override
  String get shareFailed => 'Condivisione non riuscita';

  @override
  String get showMyLocation => 'Mostra la mia posizione';

  @override
  String get sleepSettings => 'Spegnimento schermo';

  @override
  String get sleepInfoMessage1 =>
      'Disattiva il GPS quando lo schermo va in sospensione per risparmiare batteria';

  @override
  String get sleepInfoMessage2 =>
      'Per risparmiare ancora più batteria, metti il dispositivo in sospensione. Il GPS si disattiva anch\'esso';

  @override
  String get sleepInfoDontShowAgain => 'Non mostrare più';

  @override
  String get switchGpsLevel => 'Precisione posizione';

  @override
  String get gpxImport => 'Importa file GPX';

  @override
  String get gpxExport => 'Esporta file GPX';

  @override
  String get gpxExportDialogTitle => 'Nome file';

  @override
  String get gpxExportFilenameHint =>
      'Inserisci il nome del file (data/ora se vuoto)';

  @override
  String gpxExportComplete(String filename) {
    return 'Salvato $filename';
  }

  @override
  String get gpxExportFailed => 'Esportazione fallita';

  @override
  String get gpxExportPermissionDenied => 'Permesso di salvataggio file negato';

  @override
  String get poiAdd => 'Aggiungi POI';

  @override
  String get poiAddEdit => 'Aggiungi o modifica POI';

  @override
  String get poiAddByDistance => 'Aggiungi POI alla distanza';

  @override
  String get poiAddByMapTap => 'Aggiungi POI dalla mappa';

  @override
  String get poiTabAdd => 'Aggiungi POI';

  @override
  String get poiTabEdit => 'Modifica o elimina POI';

  @override
  String get poiType => 'Tipo di POI';

  @override
  String get checkpoint => 'Punto di controllo';

  @override
  String get information => 'Informazione';

  @override
  String get title => 'Titolo';

  @override
  String get body => 'Testo';

  @override
  String get distance => 'Distanza';

  @override
  String get titleNone => '(Nessun titolo)';

  @override
  String get kmRequired => 'La distanza è obbligatoria';

  @override
  String get offRoute => 'Fuori percorso';

  @override
  String kmPoint(String km) {
    return 'Punto $km km';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI al punto $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'Modifica POI';

  @override
  String get changePoiPosition => 'Imposta questa posizione';

  @override
  String get poiRegistered => 'POI aggiunto';

  @override
  String get poiAddedFromShare => 'POI aggiunto da link condiviso';

  @override
  String get shareUrlInvalid =>
      'Impossibile estrarre le coordinate dal link condiviso';

  @override
  String get registerThisPlaceAsPoi => 'Aggiungi POI qui';

  @override
  String get poiUpdated => 'POI aggiornato';

  @override
  String get poiDeleted => 'POI eliminato';

  @override
  String get poiPositionChanged => 'Posizione del POI modificata';

  @override
  String get changePoiText => 'Modifica titolo e testo del POI';

  @override
  String get changePoiPositionTitle => 'Modifica posizione del POI';

  @override
  String get deletePoiConfirm => 'Eliminare questo POI?';

  @override
  String get noPoiRegistered => 'Nessun POI aggiunto';

  @override
  String get changePoiTextTitle => 'Modifica contenuto del POI';

  @override
  String get routeOverwrite => 'Sovrascrivi percorso attuale';

  @override
  String get selectGpxFile => 'Seleziona un file GPX';

  @override
  String get routeNotLoaded => 'Il percorso non è caricato';

  @override
  String get kmPointNotFound => 'Punto km specificato non trovato';

  @override
  String get gpxInvalidFormat => 'Questo file non è in formato GPX';

  @override
  String get gpxNoRouteOrWaypoint => 'Il GPX non contiene percorso o waypoint';

  @override
  String get locationFailed => 'Impossibile ottenere la posizione';

  @override
  String get mapStyleNormal => 'Mostra mappa in modalità normale';

  @override
  String get mapStyleDark => 'Mostra mappa in modalità scura';

  @override
  String get showFullRoute => 'Mostra percorso completo';

  @override
  String get locationUnavailable => 'Posizione non disponibile';

  @override
  String get locationUnavailableWithRetry =>
      'Posizione non disponibile. Tocca \"Mostra la mia posizione\" per riprovare o consenti l\'accesso alla posizione nelle impostazioni.';

  @override
  String get openSettings => 'Apri impostazioni';

  @override
  String get locationInvalid => 'Posizione non valida';

  @override
  String get locationServiceOff =>
      'Il servizio di localizzazione è disattivato. Attivalo nelle impostazioni del dispositivo.';

  @override
  String get locationPermissionRequired =>
      'Permesso di localizzazione richiesto';

  @override
  String get locationPermissionDenied =>
      'Il permesso di localizzazione è stato negato. Non puoi mostrare la tua posizione senza permesso.';

  @override
  String get locationPermissionDeniedForever =>
      'Il permesso di localizzazione è impostato su \"Non chiedere più\". Attivalo nelle impostazioni dell\'app.';

  @override
  String get sleepOffMessage => 'Spegnimento schermo disattivato';

  @override
  String sleepSetMessage(int minutes) {
    return 'Spegnimento schermo impostato a $minutes minuti';
  }

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleep1min => '1 min';

  @override
  String get sleep5min => '5 min';

  @override
  String get sleep10min => '10 min';

  @override
  String get distanceUnit => 'Unità di distanza';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'miglia';

  @override
  String get distanceUnitSetToKm => 'Unità di distanza impostata su km';

  @override
  String get distanceUnitSetToMile => 'Unità di distanza impostata su miglia';

  @override
  String get checkingConnectivity => 'Verifica connessione...';

  @override
  String get fetchingLocation => 'Ottenimento posizione...';

  @override
  String get offline => 'Offline';

  @override
  String get retryConnectivity => 'Riprova';

  @override
  String get offlineMap => 'Mappa offline';

  @override
  String get offlineMapMinimalMap => 'Zoom max: 14';

  @override
  String get offlineMapStandardMap => 'Zoom max: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Zoom max: 14 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Zoom max: 16 ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'Zoom: Limitato';

  @override
  String get offlineMapZoomMedium => 'Zoom: Standard';

  @override
  String get offlineMapZoomLarge => 'Zoom: Esteso';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'Zoom: Limitato ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'Zoom: Standard ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'Zoom: Esteso ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'È necessaria una connessione di rete per scaricare le mappe offline';

  @override
  String get offlineMapNoRoute =>
      'Il percorso non è caricato. Importa prima un file GPX.';

  @override
  String get offlineMapDownloading => 'Download in corso... ';

  @override
  String get offlineMapCancel => 'Annulla';

  @override
  String get offlineMapDownloadComplete => 'Download mappa offline completato';

  @override
  String get offlineMapDownloadFailed => 'Download fallito';

  @override
  String get offlineMapDownloadCancelled => 'Download annullato';

  @override
  String get offlineMapWifiRecommendation =>
      'Si consiglia di scaricare tramite Wi-Fi a causa delle dimensioni dei dati';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'Si consiglia di scaricare tramite Wi-Fi a causa delle dimensioni dei dati.\n\nDimensione stimata: ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'Salvato: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'Svuota cache ($size)';
  }

  @override
  String get offlineMapCacheClear => 'Svuota cache';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'Quando i dati della cache (inclusi i map offline) aumentano, la visualizzazione della mappa può rallentare.\n\nFlusso di visualizzazione della mappa:\n\n1. Consultazione cache\n2-1. In cache:\nnessun accesso di rete\n2-2. Non in cache:\naccesso di rete e salvataggio in cache\n3. Visualizzazione mappa\n\nIl passaggio 1 richiede più tempo con dati più grandi. In caso di mappa lenta o mappa offline di grandi dimensioni per brevet, si consiglia di eliminare la cache.';

  @override
  String get offlineMapCacheClearConfirmButton => 'Elimina';

  @override
  String get offlineMapCacheCleared => 'Cache svuotata';

  @override
  String get offlineMapInfoMessage1 =>
      'Le mappe offline riducono l\'accesso alla rete e risparmiano batteria anche quando si è online';

  @override
  String get offlineMapInfoMessage2 =>
      'Per mantenere l\'app fluida, si consiglia di eliminare le mappe scaricate quando non sono più necessarie';

  @override
  String get offlineMapInfoButton => 'Scarica';

  @override
  String get registerAtPosition => 'Aggiungi qui';
}

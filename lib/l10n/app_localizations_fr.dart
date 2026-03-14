// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get change => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get settings => 'Paramètres';

  @override
  String get share => 'Partager';

  @override
  String get shareFailed => 'Échec du partage';

  @override
  String get showMyLocation => 'Afficher ma position';

  @override
  String get sleepSettings => 'Mise en veille';

  @override
  String get sleepInfoMessage1 =>
      'Désactive le GPS lors de la mise en veille de l\'écran pour économiser la batterie';

  @override
  String get sleepInfoMessage2 =>
      'Pour économiser encore plus de batterie, mettez votre appareil en veille. Le GPS se désactive également';

  @override
  String get sleepInfoDontShowAgain => 'Ne plus afficher';

  @override
  String get switchGpsLevel => 'Précision de localisation';

  @override
  String get gpxImport => 'Importer un fichier GPX';

  @override
  String get gpxExport => 'Exporter un fichier GPX';

  @override
  String get gpxExportDialogTitle => 'Nom du fichier';

  @override
  String get gpxExportFilenameHint =>
      'Entrez le nom du fichier (date/heure si vide)';

  @override
  String gpxExportComplete(String filename) {
    return 'Enregistré $filename';
  }

  @override
  String get gpxExportFailed => 'Échec de l\'export';

  @override
  String get gpxExportPermissionDenied =>
      'Permission d\'enregistrement refusée';

  @override
  String get poiAdd => 'Ajouter un POI';

  @override
  String get poiAddEdit => 'Ajouter ou modifier un POI';

  @override
  String get poiAddByDistance => 'Ajouter un POI à distance';

  @override
  String get poiAddByMapTap => 'Ajouter un POI depuis la carte';

  @override
  String get poiTabAdd => 'Ajouter POI';

  @override
  String get poiTabEdit => 'Modifier ou supprimer un POI';

  @override
  String get poiType => 'Type de POI';

  @override
  String get checkpoint => 'Point de contrôle';

  @override
  String get information => 'Information';

  @override
  String get title => 'Titre';

  @override
  String get body => 'Texte';

  @override
  String get distance => 'Distance';

  @override
  String get titleNone => '(Sans titre)';

  @override
  String get kmRequired => 'La distance est obligatoire';

  @override
  String get offRoute => 'Hors itinéraire';

  @override
  String kmPoint(String km) {
    return 'Point $km km';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI au point $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'Modifier le POI';

  @override
  String get changePoiPosition => 'Définir cette position';

  @override
  String get poiRegistered => 'POI ajouté';

  @override
  String get poiAddedFromShare => 'POI ajouté depuis un lien partagé';

  @override
  String get shareUrlInvalid =>
      'Impossible d\'extraire les coordonnées du lien partagé';

  @override
  String get registerThisPlaceAsPoi => 'Ajouter un POI ici';

  @override
  String get poiUpdated => 'POI modifié';

  @override
  String get poiDeleted => 'POI supprimé';

  @override
  String get poiPositionChanged => 'Position du POI modifiée';

  @override
  String get changePoiText => 'Modifier le titre et le texte du POI';

  @override
  String get changePoiPositionTitle => 'Modifier la position du POI';

  @override
  String get deletePoiConfirm => 'Supprimer ce POI ?';

  @override
  String get noPoiRegistered => 'Aucun POI ajouté';

  @override
  String get changePoiTextTitle => 'Modifier le contenu du POI';

  @override
  String get routeOverwrite => 'Remplacer l\'itinéraire actuel';

  @override
  String get selectGpxFile => 'Veuillez sélectionner un fichier GPX';

  @override
  String get routeNotLoaded => 'L\'itinéraire n\'est pas chargé';

  @override
  String get kmPointNotFound => 'Point km spécifié introuvable';

  @override
  String get gpxInvalidFormat => 'Ce fichier n\'est pas au format GPX';

  @override
  String get gpxNoRouteOrWaypoint =>
      'Le fichier GPX ne contient pas d\'itinéraire ou de waypoints';

  @override
  String get locationFailed => 'Échec de l\'obtention de la position';

  @override
  String get mapStyleNormal => 'Afficher la carte en mode normal';

  @override
  String get mapStyleDark => 'Afficher la carte en mode sombre';

  @override
  String get showFullRoute => 'Afficher l\'itinéraire complet';

  @override
  String get locationUnavailable => 'Position indisponible';

  @override
  String get locationUnavailableWithRetry =>
      'Position indisponible. Appuyez sur \"Afficher ma position\" pour réessayer ou autorisez l\'accès à la position dans les paramètres.';

  @override
  String get openSettings => 'Ouvrir les paramètres';

  @override
  String get locationInvalid => 'Position invalide';

  @override
  String get locationServiceOff =>
      'Le service de localisation est désactivé. Veuillez l\'activer dans les paramètres de l\'appareil.';

  @override
  String get locationPermissionRequired =>
      'Autorisation de localisation requise';

  @override
  String get locationPermissionDenied =>
      'L\'autorisation de localisation a été refusée. Vous ne pouvez pas afficher votre position sans autorisation.';

  @override
  String get locationPermissionDeniedForever =>
      'L\'autorisation de localisation est définie sur \"Ne plus demander\". Veuillez l\'activer dans les paramètres de l\'application.';

  @override
  String get sleepOffMessage => 'Mise en veille désactivée';

  @override
  String sleepSetMessage(int minutes) {
    return 'Mise en veille réglée sur $minutes minutes';
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
  String get distanceUnit => 'Unité de distance';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'mile';

  @override
  String get distanceUnitSetToKm => 'Unité de distance réglée sur km';

  @override
  String get distanceUnitSetToMile => 'Unité de distance réglée sur mile';

  @override
  String get checkingConnectivity => 'Vérification de la connexion...';

  @override
  String get fetchingLocation => 'Obtention de la position...';

  @override
  String get offline => 'Hors ligne';

  @override
  String get retryConnectivity => 'Réessayer';

  @override
  String get offlineMap => 'Carte hors ligne';

  @override
  String get offlineMapMinimalMap => 'Zoom max : 15';

  @override
  String get offlineMapStandardMap => 'Zoom max : 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Zoom max : 15 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Zoom max : 16 ($size)';
  }

  @override
  String get offlineMapHighResMap => 'Zoom max : 17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return 'Zoom max : 17 ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'Zoom : Limité';

  @override
  String get offlineMapZoomMedium => 'Zoom : Standard';

  @override
  String get offlineMapZoomLarge => 'Zoom : Étendu';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'Zoom : Limité ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'Zoom : Standard ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'Zoom : Étendu ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'Une connexion réseau est requise pour télécharger les cartes hors ligne';

  @override
  String get offlineMapNoRoute =>
      'L\'itinéraire n\'est pas chargé. Veuillez importer un fichier GPX d\'abord.';

  @override
  String get offlineMapDownloading => 'Téléchargement... ';

  @override
  String get offlineMapCancel => 'Annuler';

  @override
  String get offlineMapDownloadComplete =>
      'Téléchargement de la carte hors ligne terminé';

  @override
  String get offlineMapDownloadFailed => 'Échec du téléchargement';

  @override
  String get offlineMapDownloadCancelled => 'Téléchargement annulé';

  @override
  String get offlineMapWifiRecommendation =>
      'Nous recommandons le téléchargement via Wi-Fi en raison de la taille des données';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'Nous recommandons le téléchargement via Wi-Fi en raison de la taille des données.\n\nTaille estimée : ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'Enregistré : $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'Vider le cache ($size)';
  }

  @override
  String get offlineMapCacheClear => 'Vider le cache';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'Lorsque les données en cache (y compris les cartes hors ligne) augmentent, l\'affichage de la carte peut devenir plus lent.\n\nFlux d\'affichage de la carte :\n\n1. Consultation du cache\n2-1. En cache :\npas d\'accès réseau\n2-2. Pas en cache :\naccès réseau et enregistrement dans le cache\n3. Affichage de la carte\n\nL\'étape 1 prend plus de temps lorsque les données sont volumineuses. En cas d\'affichage lent ou de grande carte hors ligne pour brevet, il est recommandé de supprimer le cache.';

  @override
  String get offlineMapCacheClearConfirmButton => 'Supprimer';

  @override
  String get offlineMapCacheCleared => 'Cache vidé';

  @override
  String get offlineMapInfoMessage1 =>
      'Les cartes hors ligne réduisent les accès réseau et économisent la batterie, même en ligne';

  @override
  String get offlineMapInfoMessage2 =>
      'Pour que l\'application fonctionne correctement, nous recommandons de supprimer les cartes téléchargées lorsque vous n\'en avez plus besoin';

  @override
  String get offlineMapInfoButton => 'Télécharger';

  @override
  String get registerAtPosition => 'Ajouter ici';
}

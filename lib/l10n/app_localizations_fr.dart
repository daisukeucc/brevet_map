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
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => 'Annuler';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Suppr.';

  @override
  String get edit => 'Éditer';

  @override
  String get change => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get next => 'Suivant';

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
      'Le GPS se coupe lors de la mise en veille de l\'écran. Nous recommandons donc d\'activer la mise en veille si vous souhaitez réduire la consommation de la batterie.';

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
  String get gpxExportSaveLocationMessage =>
      'Par défaut, les fichiers exportés sont enregistrés aux emplacements suivants :\n\niOS :\n[Sur mon iPhone] > [Brevet MAP]\n\nAndroid :\n[Fichiers] > [Téléchargements]';

  @override
  String get poiAdd => 'Ajouter un POI';

  @override
  String get poiAddEdit => 'Ajouter ou modifier un POI';

  @override
  String get poiAddByDistance => 'Ajouter un POI à distance';

  @override
  String get poiAddByMapTap => 'Ajouter un POI en appuyant sur la carte';

  @override
  String get poiTabAdd => 'Ajouter POI';

  @override
  String get poiTabEdit => 'Éditer un POI';

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
  String get plannedArrival => 'Arrivée prévue';

  @override
  String get plannedDeparture => 'Départ prévu';

  @override
  String get plannedClose => 'Fermeture';

  @override
  String get arrivalShort => 'Arrivée';

  @override
  String get departureShort => 'Départ';

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
  String get kmExceedsRoute => 'Dépasse la distance totale de l\'itinéraire';

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
  String get sleepOnMessage => 'Mise en veille activée';

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleepOn => 'ON';

  @override
  String get sleepSettingsNote =>
      'Consultez la durée de mise en veille dans l\'application Réglages de votre appareil';

  @override
  String get openSettingsApp => 'Ouvrir l\'app Réglages';

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

  @override
  String get locationSharing => 'Partage de position';

  @override
  String get aboutApp => 'À propos de l\'application';

  @override
  String get openSourceLicenses => 'Licences open source';

  @override
  String get rateApp => 'Évaluer l\'application';

  @override
  String get contactUs => 'Contact';

  @override
  String get language => 'Langue';

  @override
  String get useSystemLanguage => 'Langue du système';

  @override
  String get appSettingsTitle => 'Paramètres & plus';

  @override
  String get contactFormMailError => 'Impossible d\'ouvrir l\'application mail';

  @override
  String get batteryLevelDisplay => 'Afficher le niveau de batterie';

  @override
  String get batteryLevelDisplayOn => 'Afficher';

  @override
  String get batteryLevelDisplayOff => 'Masquer';

  @override
  String get batteryLevelDisplayIosNote =>
      'Sur iOS, les valeurs sont affichées par incréments de 5% en raison des limitations du système d\'exploitation';

  @override
  String get trialInfoClose => 'Fermer';

  @override
  String get trialInfoSubscribe => 'Abonnement';

  @override
  String get trialInfoMessage =>
      'Essayez gratuitement l\'ajout de POI et l\'export GPX pendant 30 jours.';

  @override
  String trialInfoRemainingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Il reste $days jours',
      one: 'Il reste 1 jour',
    );
    return '$_temp0';
  }

  @override
  String get poiPremiumMessage =>
      'Abonnez-vous à Brevet MAP Premium pour modifier et supprimer des POIs !';

  @override
  String get poiPremiumViewPlans => 'Voir les offres';

  @override
  String get subscription => 'Abonnement';

  @override
  String get restorePurchases => 'Restaurer les achats';

  @override
  String get restorePurchasesSuccess => 'Achats restaurés';

  @override
  String subscriptionAccountId(String id) {
    return 'ID de compte: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return 'Expiration: $date';
  }

  @override
  String get subscriptionNotActive => 'Non abonné';

  @override
  String get subscriptionTerms => 'Conditions d\'abonnement';

  @override
  String get manageSubscription => 'Gérer l\'abonnement';

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
      'L\'itinéraire affiché sur la carte est un itinéraire d\'exemple. Pour une utilisation réelle, veuillez importer et utiliser un fichier GPX exporté depuis une application de cyclisme ou fourni par un événement.';

  @override
  String get volumeButtonTutorial =>
      'Vous pouvez ajuster le niveau de zoom de la carte avec les boutons de volume de l\'appareil';

  @override
  String get save => 'Enregistrer';

  @override
  String get saveChangesConfirm => 'Enregistrer les modifications ?';

  @override
  String get setStartDate => 'Définir la date de départ';

  @override
  String get changeRideDate => 'Modifier la date de départ';

  @override
  String get releaseNotesDialogTitle => 'Notes de version';

  @override
  String get releaseNotesV11018Message =>
      'Dans la version 1.1, nous avons ajouté plus de détails sur les POI pour vous aider à mieux planifier vos brevets !\nToutes les fonctionnalités sont débloquées dans cette version, alors n\'hésitez pas à l\'essayer !';
}

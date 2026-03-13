// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get cancel => 'Cancelar';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get change => 'Cambiar';

  @override
  String get register => 'Agregar';

  @override
  String get settings => 'Ajustes';

  @override
  String get share => 'Compartir';

  @override
  String get shareFailed => 'Error al compartir';

  @override
  String get showMyLocation => 'Mostrar mi ubicación';

  @override
  String get sleepSettings => 'Pantalla en espera';

  @override
  String get sleepInfoMessage1 =>
      'Apaga el GPS cuando la pantalla entra en reposo para ahorrar batería';

  @override
  String get sleepInfoMessage2 =>
      'Para ahorrar aún más batería, pon tu dispositivo en suspensión. El GPS también se apaga';

  @override
  String get sleepInfoDontShowAgain => 'No mostrar de nuevo';

  @override
  String get switchGpsLevel => 'Precisión de ubicación';

  @override
  String get gpxImport => 'Importar archivo GPX';

  @override
  String get gpxExport => 'Exportar archivo GPX';

  @override
  String get gpxExportDialogTitle => 'Nombre del archivo';

  @override
  String get gpxExportFilenameHint =>
      'Introduzca el nombre del archivo (fecha/hora si está vacío)';

  @override
  String gpxExportComplete(String filename) {
    return 'Guardado $filename';
  }

  @override
  String get gpxExportFailed => 'Exportación fallida';

  @override
  String get gpxExportPermissionDenied => 'Permiso de guardado denegado';

  @override
  String get poiAdd => 'Añadir POI';

  @override
  String get poiAddEdit => 'Agregar o editar POI';

  @override
  String get poiAddByDistance => 'Agregar POI por distancia';

  @override
  String get poiAddByMapTap => 'Agregar POI desde el mapa';

  @override
  String get poiTabAdd => 'Añadir POI';

  @override
  String get poiTabEdit => 'Editar o eliminar POI';

  @override
  String get poiType => 'Tipo de POI';

  @override
  String get checkpoint => 'Punto de control';

  @override
  String get information => 'Información';

  @override
  String get title => 'Título';

  @override
  String get body => 'Texto';

  @override
  String get distance => 'Distancia';

  @override
  String get titleNone => '(Sin título)';

  @override
  String get kmRequired => 'La distancia es obligatoria';

  @override
  String get offRoute => 'Fuera de ruta';

  @override
  String kmPoint(String km) {
    return 'Punto $km km';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI en el punto $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'Editar POI';

  @override
  String get changePoiPosition => 'Establecer esta posición';

  @override
  String get dragMarkerHint => 'Arrastra el marcador para moverlo';

  @override
  String get longPressPoiHint =>
      'Mantenga pulsado el punto donde desea añadir un POI';

  @override
  String get poiRegistered => 'POI registrado';

  @override
  String get poiAddedFromShare => 'POI añadido desde enlace compartido';

  @override
  String get shareUrlInvalid =>
      'No se pudieron extraer las coordenadas del enlace compartido';

  @override
  String get registerThisPlaceAsPoi => '¿Registrar esta ubicación como POI?';

  @override
  String get poiUpdated => 'POI actualizado';

  @override
  String get poiDeleted => 'POI eliminado';

  @override
  String get poiPositionChanged => 'Posición del POI cambiada';

  @override
  String get changePoiText => 'Cambiar título y texto del POI';

  @override
  String get changePoiPositionTitle => 'Cambiar posición del POI';

  @override
  String get deletePoiConfirm => '¿Eliminar este POI?';

  @override
  String get noPoiRegistered => 'No hay POI registrado';

  @override
  String get changePoiTextTitle => 'Cambiar contenido del POI';

  @override
  String get routeOverwrite => 'Sobrescribir ruta actual';

  @override
  String get selectGpxFile => 'Por favor seleccione un archivo GPX';

  @override
  String get routeNotLoaded => 'La ruta no está cargada';

  @override
  String get kmPointNotFound => 'Punto km especificado no encontrado';

  @override
  String get gpxInvalidFormat => 'Este archivo no está en formato GPX';

  @override
  String get gpxNoRouteOrWaypoint => 'El GPX no contiene ruta ni waypoints';

  @override
  String get locationFailed => 'Error al obtener la ubicación';

  @override
  String get mapStyleNormal => 'Mostrar mapa en modo normal';

  @override
  String get mapStyleDark => 'Mostrar mapa en modo oscuro';

  @override
  String get showFullRoute => 'Mostrar ruta completa';

  @override
  String get locationUnavailable => 'Ubicación no disponible';

  @override
  String get locationUnavailableWithRetry =>
      'Ubicación no disponible. Toque \"Mostrar mi ubicación\" para reintentar o permita el acceso a la ubicación en los ajustes.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get locationInvalid => 'Ubicación no válida';

  @override
  String get locationServiceOff =>
      'El servicio de ubicación está apagado. Por favor actívelo en la configuración del dispositivo.';

  @override
  String get locationPermissionRequired => 'Se requiere permiso de ubicación';

  @override
  String get locationPermissionDenied =>
      'Se denegó el permiso de ubicación. No puede mostrar su ubicación sin permiso.';

  @override
  String get locationPermissionDeniedForever =>
      'El permiso de ubicación está en \"No volver a preguntar\". Por favor actívelo en la configuración de la aplicación.';

  @override
  String get sleepOffMessage => 'Pantalla en espera desactivada';

  @override
  String sleepSetMessage(int minutes) {
    return 'Pantalla en espera configurada a $minutes minutos';
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
  String get distanceUnit => 'Unidad de distancia';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'millas';

  @override
  String get distanceUnitSetToKm => 'Unidad de distancia configurada a km';

  @override
  String get distanceUnitSetToMile =>
      'Unidad de distancia configurada a millas';

  @override
  String get checkingConnectivity => 'Comprobando conexión...';

  @override
  String get fetchingLocation => 'Obteniendo ubicación...';

  @override
  String get offline => 'Sin conexión';

  @override
  String get retryConnectivity => 'Reintentar';

  @override
  String get offlineMap => 'Mapa sin conexión';

  @override
  String get offlineMapMinimalMap => 'Zoom máx.: 14';

  @override
  String get offlineMapStandardMap => 'Zoom máx.: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'Zoom máx.: 14 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'Zoom máx.: 16 ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'Zoom: Limitado';

  @override
  String get offlineMapZoomMedium => 'Zoom: Estándar';

  @override
  String get offlineMapZoomLarge => 'Zoom: Extendido';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'Zoom: Limitado ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'Zoom: Estándar ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'Zoom: Extendido ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'Se requiere conexión de red para descargar mapas sin conexión';

  @override
  String get offlineMapNoRoute =>
      'La ruta no está cargada. Por favor importe un archivo GPX primero.';

  @override
  String get offlineMapDownloading => 'Descargando... ';

  @override
  String get offlineMapCancel => 'Cancelar';

  @override
  String get offlineMapDownloadComplete =>
      'Descarga del mapa sin conexión completada';

  @override
  String get offlineMapDownloadFailed => 'Descarga fallida';

  @override
  String get offlineMapDownloadCancelled => 'Descarga cancelada';

  @override
  String get offlineMapWifiRecommendation =>
      'Recomendamos descargar por Wi-Fi debido al gran tamaño de los datos';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'Recomendamos descargar por Wi-Fi debido al gran tamaño de los datos.\n\nTamaño estimado: ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'Almacenado: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'Borrar caché ($size)';
  }

  @override
  String get offlineMapCacheClear => 'Borrar caché';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'Cuando los datos de caché (incluidos mapas sin conexión) aumentan, la visualización del mapa puede ralentizarse.\n\nFlujo de visualización del mapa:\n\n1. Consulta de caché\n2-1. En caché:\nsin acceso a red\n2-2. No en caché:\nacceso a red y guardado en caché\n3. Visualización del mapa\n\nEl paso 1 tarda más cuando hay más datos. Se recomienda eliminar la caché si el mapa va lento o ha guardado un mapa sin conexión grande para brevet.';

  @override
  String get offlineMapCacheClearConfirmButton => 'Eliminar';

  @override
  String get offlineMapCacheCleared => 'Caché borrada';
}

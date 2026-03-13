// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ブルベMAP';

  @override
  String get cancel => 'キャンセル';

  @override
  String get ok => 'OK';

  @override
  String get ng => 'NG';

  @override
  String get delete => '削除';

  @override
  String get edit => '編集';

  @override
  String get change => '変更';

  @override
  String get register => '登録';

  @override
  String get settings => '設定';

  @override
  String get share => '共有';

  @override
  String get shareFailed => '共有に失敗しました';

  @override
  String get showMyLocation => '現在地を表示';

  @override
  String get sleepSettings => '画面スリープ';

  @override
  String get sleepInfoMessage1 => '画面スリープ時はGPSがOFFになるためバッテリー消費が減ります';

  @override
  String get sleepInfoMessage2 =>
      'さらにバッテリー消費を抑えるためには端末自体をスリープして下さい\n端末スリープでもGPSはOFFになります';

  @override
  String get sleepInfoDontShowAgain => '以後表示しない';

  @override
  String get switchGpsLevel => '位置情報レベルを切り替え';

  @override
  String get gpxImport => 'GPXファイルをインポート';

  @override
  String get gpxExport => 'GPXファイルをエクスポート';

  @override
  String get gpxExportDialogTitle => 'ファイル名';

  @override
  String get gpxExportFilenameHint => 'ファイル名を入力してください（未入力の場合は日時を使用）';

  @override
  String gpxExportComplete(String filename) {
    return '$filename を保存しました';
  }

  @override
  String get gpxExportFailed => 'エクスポートに失敗しました';

  @override
  String get gpxExportPermissionDenied => 'ファイル保存の権限がありません';

  @override
  String get poiAdd => 'POIの登録';

  @override
  String get poiAddEdit => 'POIの登録・編集';

  @override
  String get poiAddByDistance => '距離入力でPOIを登録';

  @override
  String get poiAddByMapTap => '地図タップでPOIを登録';

  @override
  String get poiTabAdd => 'POI 登録';

  @override
  String get poiTabEdit => 'POI 編集 / 削除';

  @override
  String get poiType => 'POIタイプ';

  @override
  String get checkpoint => 'チェックポイント';

  @override
  String get information => 'インフォメーション';

  @override
  String get title => 'タイトル';

  @override
  String get body => '本文';

  @override
  String get distance => '距離';

  @override
  String get titleNone => '(タイトルなし)';

  @override
  String get kmRequired => '距離の入力は必須です';

  @override
  String get offRoute => 'ルート外';

  @override
  String kmPoint(String km) {
    return '${km}km地点';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return '$kmLabel地点のPOI';
  }

  @override
  String get poiOffRoutePoi => 'POIの編集';

  @override
  String get changePoiPosition => 'この位置に変更する';

  @override
  String get longPressPoiHint => 'POIを登録したいポイントを長押しして下さい';

  @override
  String get poiRegistered => 'POIを登録しました';

  @override
  String get poiAddedFromShare => '共有リンクからPOIを登録しました';

  @override
  String get shareUrlInvalid => '共有されたリンクから座標を取得できませんでした';

  @override
  String get registerThisPlaceAsPoi => 'この場所をPOIとして登録する';

  @override
  String get poiUpdated => 'POIを変更しました';

  @override
  String get poiDeleted => 'POIを削除しました';

  @override
  String get poiPositionChanged => 'POIの位置を変更しました';

  @override
  String get changePoiText => 'POIのタイトル・本文を変更';

  @override
  String get changePoiPositionTitle => 'POIの位置を変更';

  @override
  String get deletePoiConfirm => 'このPOIを削除しますか？';

  @override
  String get noPoiRegistered => 'POIの登録はありません';

  @override
  String get changePoiTextTitle => 'POIの内容を変更';

  @override
  String get routeOverwrite => '現在のルートを上書きします';

  @override
  String get selectGpxFile => 'GPXファイルを選択してください';

  @override
  String get routeNotLoaded => 'ルートが読み込まれていません';

  @override
  String get kmPointNotFound => '指定したkm地点が見つかりません';

  @override
  String get gpxInvalidFormat => 'このファイルはGPX形式ではありません';

  @override
  String get gpxNoRouteOrWaypoint => 'GPXにルートまたはウェイポイントが含まれていません';

  @override
  String get locationFailed => '位置情報の取得に失敗しました';

  @override
  String get mapStyleNormal => '地図を通常表示';

  @override
  String get mapStyleDark => '地図をダーク表示';

  @override
  String get showFullRoute => 'ルート全体を表示';

  @override
  String get locationUnavailable => '位置情報を取得できません';

  @override
  String get locationUnavailableWithRetry =>
      '位置情報を取得できません。「現在地を表示」で再試行するか、設定から位置情報を許可してください。';

  @override
  String get openSettings => '設定を開く';

  @override
  String get locationInvalid => '位置情報が無効です';

  @override
  String get locationServiceOff => '位置情報サービスがオフになっています。端末の設定でオンにしてください。';

  @override
  String get locationPermissionRequired => '位置情報の許可が必要です';

  @override
  String get locationPermissionDenied => '位置情報の許可が拒否されました。許可しない場合は現在地を表示できません。';

  @override
  String get locationPermissionDeniedForever =>
      '位置情報の許可が「今後表示しない」になっています。アプリ設定から許可をオンにしてください。';

  @override
  String get sleepOffMessage => '画面スリープをOFFにしました';

  @override
  String sleepSetMessage(int minutes) {
    return '画面スリープを$minutes分に設定しました';
  }

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleep1min => '1分';

  @override
  String get sleep5min => '5分';

  @override
  String get sleep10min => '10分';

  @override
  String get distanceUnit => '距離の単位';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => 'mile';

  @override
  String get distanceUnitSetToKm => '距離の単位をkmに設定しました';

  @override
  String get distanceUnitSetToMile => '距離の単位をmileに設定しました';

  @override
  String get checkingConnectivity => '接続を確認しています...';

  @override
  String get fetchingLocation => '位置情報を取得しています...';

  @override
  String get offline => 'オフラインです';

  @override
  String get retryConnectivity => '再接続';

  @override
  String get offlineMap => 'オフラインマップ';

  @override
  String get offlineMapMinimalMap => '最大ズーム：14';

  @override
  String get offlineMapStandardMap => '最大ズーム：16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return '最大ズーム：14（$size）';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return '最大ズーム：16（$size）';
  }

  @override
  String get offlineMapZoomSmall => 'ズーム：小';

  @override
  String get offlineMapZoomMedium => 'ズーム：中';

  @override
  String get offlineMapZoomLarge => 'ズーム：大';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'ズーム：小（$size）';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'ズーム：中（$size）';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'ズーム：大（$size）';
  }

  @override
  String get offlineMapRequiresNetwork => 'オフラインマップのダウンロードにはネットワーク接続が必要です';

  @override
  String get offlineMapNoRoute => 'ルートが読み込まれていません。GPXをインポートしてからダウンロードしてください。';

  @override
  String get offlineMapDownloading => 'ダウンロード中 ... ';

  @override
  String get offlineMapCancel => 'キャンセル';

  @override
  String get offlineMapDownloadComplete => 'オフラインマップのダウンロードが完了しました';

  @override
  String get offlineMapDownloadFailed => 'ダウンロードに失敗しました';

  @override
  String get offlineMapDownloadCancelled => 'ダウンロードをキャンセルしました';

  @override
  String get offlineMapWifiRecommendation =>
      'データサイズが大きいためWi-Fi接続でのダウンロードをお勧めします';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'データサイズが大きいためWi-Fi接続でのダウンロードをお勧めします。\n\n推定サイズ: 約$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return '保存済み: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'キャッシュ削除（$size）';
  }

  @override
  String get offlineMapCacheClear => 'キャッシュ削除';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'キャッシュデータ（オフラインマップ含む）が増えると、地図の表示が遅くなることがあります\n\n地図表示の流れ\n\n1. キャッシュ参照\n2-1. キャッシュあり：\nネットワークアクセスなし\n2-2. キャッシュなし：\nネットワークアクセスしキャッシュ保存\n3. 地図表示\n\n1のキャッシュ参照はデータが大きいほど時間がかかります\nそのため、地図表示が遅くなったり、ブルベ用に大容量のオフラインマップを保存した場合、キャッシュ削除することをおすすめします';

  @override
  String get offlineMapCacheClearConfirmButton => '削除';

  @override
  String get offlineMapCacheCleared => 'キャッシュを削除しました';
}

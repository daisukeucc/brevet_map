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
  String get appTitleBrand => 'Brevet Map';

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
  String get add => '追加';

  @override
  String get next => '次へ';

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
  String get sleepInfoMessage1 =>
      '画面スリープ時はGPSがOFFになるため、バッテリー消費を抑えたい場合は、画面スリープを有効にすることをおすすめします';

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
  String get gpxExportSaveLocationMessage =>
      '初期設定では、エクスポートしたファイルは下記に保存されます\n\niOS:\n[このiPhone内] > [ブルベMAP]\n\nAndroid:\n[Files] > [ダウンロード]';

  @override
  String get poiAdd => 'POIの追加';

  @override
  String get poiAddEdit => 'POIの追加・編集';

  @override
  String get poiAddByDistance => '距離入力でPOIを追加';

  @override
  String get poiAddByMapTap => '地図上でPOIを追加';

  @override
  String get poiTabAdd => 'POI 追加';

  @override
  String get poiTabEdit => 'POI 編集';

  @override
  String get poiType => 'POIタイプ';

  @override
  String get checkpoint => 'チェックポイント';

  @override
  String get information => 'インフォメーション';

  @override
  String get poiTypePhotoCheck => 'フォトチェック';

  @override
  String get poiTypeStore => 'コンビニ';

  @override
  String get poiTypeHotel => 'ホテル';

  @override
  String get poiTypeDining => '食事';

  @override
  String get poiTypeStation => '駅';

  @override
  String get title => 'タイトル';

  @override
  String get body => '本文';

  @override
  String get plannedArrival => '到着予定';

  @override
  String get plannedDeparture => '出発予定';

  @override
  String get plannedClose => 'クローズ';

  @override
  String get arrivalShort => '到着予定';

  @override
  String get departureShort => '出発予定';

  @override
  String get distance => '距離';

  @override
  String get titleNone => '(タイトルなし)';

  @override
  String get kmRequired => '距離の入力は必須です';

  @override
  String get routeLegOutboundShort => '往路';

  @override
  String get routeLegReturnShort => '復路';

  @override
  String get routeLegAmbiguousShort => '往復判定不可';

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
  String get poiRegistered => 'POIを追加しました';

  @override
  String get poiAddedFromShare => '共有リンクからPOIを追加しました';

  @override
  String get shareUrlInvalid => '共有されたリンクから座標を取得できませんでした';

  @override
  String get registerThisPlaceAsPoi => 'この場所にPOIを追加する';

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
  String get noPoiRegistered => '追加されたPOIはありません';

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
  String get kmExceedsRoute => 'ルートの総距離を超えています';

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
  String get sleepOnMessage => '画面スリープをONにしました';

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleepOn => 'ON';

  @override
  String get sleepSettingsNote => '画面スリープの時間は、端末設定アプリで確認してください';

  @override
  String get openSettingsApp => '設定アプリを開く';

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
  String get offlineMapMinimalMap => '最大ズーム：15';

  @override
  String get offlineMapStandardMap => '最大ズーム：16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return '最大ズーム：15（$size）';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return '最大ズーム：16（$size）';
  }

  @override
  String get offlineMapHighResMap => '最大ズーム：17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return '最大ズーム：17（$size）';
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

  @override
  String get offlineMapInfoMessage1 =>
      'オフラインマップは、オンライン時でもネットワークアクセスを減らし、バッテリー消費を抑えます';

  @override
  String get offlineMapInfoMessage2 =>
      '但し、アプリを快適に使用するために、ダウンロードしたマップは使用終了後に削除することをお勧めします';

  @override
  String get offlineMapInfoButton => 'ダウンロード';

  @override
  String get registerAtPosition => 'この位置に追加する';

  @override
  String get locationSharing => '位置情報の共有';

  @override
  String get aboutApp => 'このアプリについて';

  @override
  String get openSourceLicenses => 'オープンソースライセンス';

  @override
  String get rateApp => 'アプリを評価する';

  @override
  String get contactUs => 'お問い合わせ';

  @override
  String get language => '言語';

  @override
  String get useSystemLanguage => 'システム設定に従う';

  @override
  String get appSettingsTitle => '設定・その他';

  @override
  String get contactFormMailError => 'メールアプリを開けませんでした';

  @override
  String get batteryLevelDisplay => 'バッテリー残量表示';

  @override
  String get batteryLevelDisplayOn => '表示';

  @override
  String get batteryLevelDisplayOff => '非表示';

  @override
  String get batteryLevelDisplayIosNote => 'OSの制限のため、iOSは5%毎の表示になります';

  @override
  String get trialInfoClose => '閉じる';

  @override
  String get trialInfoSubscribe => '定期購入';

  @override
  String get trialInfoMessage => 'POIの追加、GPXファイルのエクスポート機能は、30日間無料でお試しいただけます！';

  @override
  String trialInfoRemainingDays(int days) {
    return '残り$days日';
  }

  @override
  String get poiPremiumMessage => 'ブルベMAPプレミアムへの加入で、POIの編集・削除ができる！';

  @override
  String get poiPremiumViewPlans => 'プラン確認';

  @override
  String get subscription => '定期購入';

  @override
  String get restorePurchases => '購入履歴の復元';

  @override
  String get restorePurchasesSuccess => '購入を復元しました';

  @override
  String subscriptionAccountId(String id) {
    return 'アカウントID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return '有効期限: $date';
  }

  @override
  String get subscriptionNotActive => '未加入';

  @override
  String get subscriptionTerms => '購読規約';

  @override
  String get manageSubscription => 'サブスクリプションを管理';

  @override
  String get subscriptionPremiumBlurb =>
      'ブルベMAPプレミアムは、購入した各サブスクリプション期間中、地図上のPOIの編集・削除などをご利用いただけます。';

  @override
  String subscriptionCurrentPlan(String name) {
    return '現在のプラン: $name';
  }

  @override
  String subscriptionPlanBillingUnit(String unit) {
    return '請求単位: $unit';
  }

  @override
  String get subscriptionUnitMonthly => '月額（毎月）';

  @override
  String get subscriptionUnitYearly => '年額（毎年）';

  @override
  String get subscriptionUnitWeekly => '週額（毎週）';

  @override
  String get subscriptionExpiryNoDate => 'プレミアムは有効ですが、更新日を取得できませんでした。';

  @override
  String get subscriptionAvailablePlans => 'プランと価格';

  @override
  String get subscriptionPlansLoadError =>
      'サブスクリプションプランを読み込めませんでした。通信状況を確認のうえ、再度お試しください。';

  @override
  String get subscriptionPlansNotConfigured => 'ストアから利用可能なプランがありません。';

  @override
  String subscriptionPlanRow(String title, String price, String periodSuffix) {
    return '$title\n$price$periodSuffix';
  }

  @override
  String subscriptionPeriodPart(String period) {
    return ' · $period';
  }

  @override
  String get subscriptionBillingPeriodWeek => '毎週';

  @override
  String get subscriptionBillingPeriodMonth => '毎月';

  @override
  String get subscriptionBillingPeriodThreeMonths => '3か月ごと';

  @override
  String get subscriptionBillingPeriodSixMonths => '6か月ごと';

  @override
  String get subscriptionBillingPeriodYear => '毎年';

  @override
  String subscriptionBillingPeriodUnknown(String code) {
    return '期間: $code';
  }

  @override
  String get linkPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get linkTermsOfUse => '利用規約';

  @override
  String get subscriptionOpenPaywall => '購入・プラン変更';

  @override
  String get sampleRouteDialogMessage =>
      '地図上のルートはサンプルルートのため、実際に使用する場合は、サイクリングアプリからエクスポートしたGPXファイルや、イベントで提供されるGPXファイルをインポートして使用してください。';

  @override
  String get volumeButtonTutorial => '端末のボリュームボタンで地図のズームレベルを調節可能です';

  @override
  String get save => '保存';

  @override
  String get saveChangesConfirm => '変更を保存しますか';

  @override
  String get setStartDate => '出走日を設定';

  @override
  String get changeRideDate => '出走日を変更';

  @override
  String get releaseNotesDialogTitle => 'リリースノート';

  @override
  String get releaseNotesV11018Message =>
      'ver1.1では、ブルベの走行計画が立てられるよう、POIの情報を増やしました！\nこのバージョンでは全機能を解放しておりますので、是非お試し下さい！';

  @override
  String get releaseNotesV12019Message =>
      'ver1.2ではPOI情報を大幅に拡充しました！\nこのバージョンでは全機能を解放しておりますので、是非お試し下さい！\n\n- POI種別にフォトチェックやコンビニ等を追加\n- POI情報にURLリンク項目を追加\n- PC間の標高グラフ表示\n- PC到着予想時刻の自動設定';

  @override
  String get poiSaveAsNote => 'メモとして保存';

  @override
  String get brevetTimeLimitLabel => '制限時間';

  @override
  String get poiCheckInConfirmMessage => 'チェックインしますか？';
}

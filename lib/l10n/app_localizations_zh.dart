// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => '取消';

  @override
  String get ok => '确定';

  @override
  String get ng => 'NG';

  @override
  String get delete => '删除';

  @override
  String get edit => '编辑';

  @override
  String get change => '更改';

  @override
  String get add => '添加';

  @override
  String get next => '下一个';

  @override
  String get settings => '设置';

  @override
  String get share => '分享';

  @override
  String get shareFailed => '分享失败';

  @override
  String get showMyLocation => '显示我的位置';

  @override
  String get sleepSettings => '屏幕休眠';

  @override
  String get sleepInfoMessage1 => '屏幕休眠时GPS会关闭，因此如果希望减少电量消耗，建议启用屏幕休眠。';

  @override
  String get sleepInfoDontShowAgain => '不再显示';

  @override
  String get switchGpsLevel => '位置精度';

  @override
  String get gpxImport => '导入 GPX 文件';

  @override
  String get gpxExport => '导出 GPX 文件';

  @override
  String get gpxExportDialogTitle => '文件名';

  @override
  String get gpxExportFilenameHint => '输入文件名（留空则使用日期/时间）';

  @override
  String gpxExportComplete(String filename) {
    return '已保存 $filename';
  }

  @override
  String get gpxExportFailed => '导出失败';

  @override
  String get gpxExportPermissionDenied => '文件保存权限被拒绝';

  @override
  String get gpxExportSaveLocationMessage =>
      '默认情况下，导出的文件将保存在以下位置：\n\niOS：\n[我的iPhone] > [Brevet MAP]\n\nAndroid：\n[Files] > [下载]';

  @override
  String get poiAdd => '添加 POI';

  @override
  String get poiAddEdit => '添加或编辑POI';

  @override
  String get poiAddByDistance => '按距离添加POI';

  @override
  String get poiAddByMapTap => '通过点击地图添加POI';

  @override
  String get poiTabAdd => '添加 POI';

  @override
  String get poiTabEdit => '编辑 POI';

  @override
  String get poiType => 'POI 类型';

  @override
  String get checkpoint => '检查点';

  @override
  String get information => '信息';

  @override
  String get title => '标题';

  @override
  String get body => '正文';

  @override
  String get plannedArrival => '到达';

  @override
  String get plannedDeparture => '出发';

  @override
  String get plannedClose => '截止时间';

  @override
  String get arrivalShort => '到达';

  @override
  String get departureShort => '出发';

  @override
  String get distance => '距离';

  @override
  String get titleNone => '（无标题）';

  @override
  String get kmRequired => '距离为必填项';

  @override
  String get offRoute => '偏离路线';

  @override
  String kmPoint(String km) {
    return '${km}km 点';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return '$kmLabel 点的 POI';
  }

  @override
  String get poiOffRoutePoi => '编辑 POI';

  @override
  String get changePoiPosition => '设为此位置';

  @override
  String get poiRegistered => 'POI 已添加';

  @override
  String get poiAddedFromShare => '已从分享链接添加 POI';

  @override
  String get shareUrlInvalid => '无法从分享链接提取坐标';

  @override
  String get registerThisPlaceAsPoi => '在此添加 POI';

  @override
  String get poiUpdated => 'POI 已更新';

  @override
  String get poiDeleted => 'POI 已删除';

  @override
  String get poiPositionChanged => 'POI 位置已更改';

  @override
  String get changePoiText => '更改 POI 标题和正文';

  @override
  String get changePoiPositionTitle => '更改 POI 位置';

  @override
  String get deletePoiConfirm => '删除此 POI？';

  @override
  String get noPoiRegistered => '未添加 POI';

  @override
  String get changePoiTextTitle => '更改 POI 内容';

  @override
  String get routeOverwrite => '覆盖当前路线';

  @override
  String get selectGpxFile => '请选择 GPX 文件';

  @override
  String get routeNotLoaded => '路线未加载';

  @override
  String get kmPointNotFound => '未找到指定的 km 点';

  @override
  String get kmExceedsRoute => '超过路线总距离';

  @override
  String get gpxInvalidFormat => '此文件不是 GPX 格式';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX 不包含路线或航点';

  @override
  String get locationFailed => '获取位置失败';

  @override
  String get mapStyleNormal => '以普通模式显示地图';

  @override
  String get mapStyleDark => '以深色模式显示地图';

  @override
  String get showFullRoute => '显示完整路线';

  @override
  String get locationUnavailable => '位置不可用';

  @override
  String get locationUnavailableWithRetry => '位置不可用。点击「显示我的位置」重试，或在设置中允许位置访问。';

  @override
  String get openSettings => '打开设置';

  @override
  String get locationInvalid => '位置无效';

  @override
  String get locationServiceOff => '定位服务已关闭。请在设备设置中开启。';

  @override
  String get locationPermissionRequired => '需要位置权限';

  @override
  String get locationPermissionDenied => '位置权限被拒绝。未经许可无法显示您的位置。';

  @override
  String get locationPermissionDeniedForever => '位置权限已设为「不再询问」。请在应用设置中启用。';

  @override
  String get sleepOffMessage => '屏幕休眠已禁用';

  @override
  String get sleepOnMessage => '屏幕休眠已启用';

  @override
  String get sleepOff => '关闭';

  @override
  String get sleepOn => '开启';

  @override
  String get sleepSettingsNote => '请在设备的设置应用中查看屏幕休眠时间';

  @override
  String get openSettingsApp => '打开设置应用';

  @override
  String get distanceUnit => '距离单位';

  @override
  String get unitKm => '公里';

  @override
  String get unitMile => '英里';

  @override
  String get distanceUnitSetToKm => '距离单位已设为公里';

  @override
  String get distanceUnitSetToMile => '距离单位已设为英里';

  @override
  String get checkingConnectivity => '正在检查连接...';

  @override
  String get fetchingLocation => '正在获取位置...';

  @override
  String get offline => '离线';

  @override
  String get retryConnectivity => '重试';

  @override
  String get offlineMap => '离线地图';

  @override
  String get offlineMapMinimalMap => '最大缩放：15';

  @override
  String get offlineMapStandardMap => '最大缩放：16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return '最大缩放：15（$size）';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return '最大缩放：16（$size）';
  }

  @override
  String get offlineMapHighResMap => '最大缩放：17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return '最大缩放：17（$size）';
  }

  @override
  String get offlineMapZoomSmall => '缩放：限定';

  @override
  String get offlineMapZoomMedium => '缩放：标准';

  @override
  String get offlineMapZoomLarge => '缩放：扩展';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return '缩放：限定（$size）';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return '缩放：标准（$size）';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return '缩放：扩展（$size）';
  }

  @override
  String get offlineMapRequiresNetwork => '下载离线地图需要网络连接';

  @override
  String get offlineMapNoRoute => '路线未加载。请先导入 GPX 文件。';

  @override
  String get offlineMapDownloading => '下载中... ';

  @override
  String get offlineMapCancel => '取消';

  @override
  String get offlineMapDownloadComplete => '离线地图下载完成';

  @override
  String get offlineMapDownloadFailed => '下载失败';

  @override
  String get offlineMapDownloadCancelled => '下载已取消';

  @override
  String get offlineMapWifiRecommendation => '由于数据量大，建议使用 Wi-Fi 下载';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return '由于数据量大，建议使用 Wi-Fi 下载。\n\n预计大小：约 $size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return '已保存: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return '清除缓存（$size）';
  }

  @override
  String get offlineMapCacheClear => '清除缓存';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      '缓存数据（含离线地图）增多时，地图显示可能会变慢。\n\n地图显示流程：\n\n1. 缓存查询\n2-1. 有缓存：\n无需网络访问\n2-2. 无缓存：\n网络访问并保存到缓存\n3. 地图显示\n\n步骤1的缓存查询在数据越大时耗时越长。若地图显示变慢或为 brevet 保存了大容量离线地图，建议删除缓存。';

  @override
  String get offlineMapCacheClearConfirmButton => '删除';

  @override
  String get offlineMapCacheCleared => '缓存已清除';

  @override
  String get offlineMapInfoMessage1 => '离线地图即使在线时也能减少网络访问并节省电量';

  @override
  String get offlineMapInfoMessage2 => '为保持应用顺畅运行，建议在不再需要时删除已下载的地图';

  @override
  String get offlineMapInfoButton => '下载';

  @override
  String get registerAtPosition => '在此添加';

  @override
  String get locationSharing => '位置共享';

  @override
  String get aboutApp => '关于本应用';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get rateApp => '评价应用';

  @override
  String get contactUs => '联系我们';

  @override
  String get language => '语言';

  @override
  String get useSystemLanguage => '使用系统语言';

  @override
  String get appSettingsTitle => '设置与其他';

  @override
  String get contactFormMailError => '无法打开邮件应用';

  @override
  String get batteryLevelDisplay => '显示电量';

  @override
  String get batteryLevelDisplayOn => '显示';

  @override
  String get batteryLevelDisplayOff => '隐藏';

  @override
  String get batteryLevelDisplayIosNote => '由于iOS系统限制，电量以5%为单位显示';

  @override
  String get trialInfoClose => '关闭';

  @override
  String get trialInfoSubscribe => '订阅';

  @override
  String get trialInfoMessage => 'POI 添加和 GPX 导出功能可免费试用 30 天！';

  @override
  String trialInfoRemainingDays(int days) {
    return '剩余 $days 天';
  }

  @override
  String get poiPremiumMessage => '订阅 Brevet MAP 高级版，即可编辑和删除 POI！';

  @override
  String get poiPremiumViewPlans => '查看方案';

  @override
  String get subscription => '订阅';

  @override
  String get restorePurchases => '恢复购买';

  @override
  String get restorePurchasesSuccess => '购买已恢复';

  @override
  String subscriptionAccountId(String id) {
    return '账户ID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return '到期日: $date';
  }

  @override
  String get subscriptionNotActive => '未订阅';

  @override
  String get subscriptionTerms => '订阅条款';

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get subscriptionPremiumBlurb =>
      'Brevet Map 高级版可在您购买的每个订阅周期内解锁地图上的 POI 编辑与删除等功能。';

  @override
  String subscriptionCurrentPlan(String name) {
    return '当前方案：$name';
  }

  @override
  String subscriptionPlanBillingUnit(String unit) {
    return '计费周期：$unit';
  }

  @override
  String get subscriptionUnitMonthly => '按月';

  @override
  String get subscriptionUnitYearly => '按年';

  @override
  String get subscriptionUnitWeekly => '按周';

  @override
  String get subscriptionExpiryNoDate => '高级版已生效，但无法加载续订日期。';

  @override
  String get subscriptionAvailablePlans => '方案与价格';

  @override
  String get subscriptionPlansLoadError => '无法加载订阅方案。请检查网络后重试。';

  @override
  String get subscriptionPlansNotConfigured => '商店当前没有可用的订阅方案。';

  @override
  String subscriptionPlanRow(String title, String price, String periodSuffix) {
    return '$title\n$price$periodSuffix';
  }

  @override
  String subscriptionPeriodPart(String period) {
    return ' · $period';
  }

  @override
  String get subscriptionBillingPeriodWeek => '每周';

  @override
  String get subscriptionBillingPeriodMonth => '每月';

  @override
  String get subscriptionBillingPeriodThreeMonths => '每 3 个月';

  @override
  String get subscriptionBillingPeriodSixMonths => '每 6 个月';

  @override
  String get subscriptionBillingPeriodYear => '每年';

  @override
  String subscriptionBillingPeriodUnknown(String code) {
    return '周期：$code';
  }

  @override
  String get linkPrivacyPolicy => '隐私政策';

  @override
  String get linkTermsOfUse => '使用条款';

  @override
  String get subscriptionOpenPaywall => '订阅或更改方案';

  @override
  String get sampleRouteDialogMessage =>
      '地图上显示的路线是示例路线。实际使用时，请导入并使用从骑行应用导出的GPX文件或活动提供的GPX文件。';

  @override
  String get volumeButtonTutorial => '您可以使用设备的音量键调整地图缩放级别';

  @override
  String get save => '保存';

  @override
  String get saveChangesConfirm => '保存更改？';

  @override
  String get setStartDate => '设置出发日期';

  @override
  String get changeRideDate => '更改出发日期';

  @override
  String get releaseNotesDialogTitle => '发行说明';

  @override
  String get releaseNotesV11018Message =>
      '在 1.1 版本中，我们增强了 POI 信息，让您可以更高效地规划您的长距离骑行！\n此版本已解锁全部功能，欢迎体验！';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => '取消';

  @override
  String get ok => '確定';

  @override
  String get ng => 'NG';

  @override
  String get delete => '刪除';

  @override
  String get edit => '編輯';

  @override
  String get change => '更改';

  @override
  String get add => '添加';

  @override
  String get next => '下一個';

  @override
  String get settings => '設定';

  @override
  String get share => '分享';

  @override
  String get shareFailed => '分享失敗';

  @override
  String get showMyLocation => '顯示我的位置';

  @override
  String get sleepSettings => '螢幕休眠';

  @override
  String get sleepInfoMessage1 => '螢幕休眠時GPS會關閉，因此如果希望減少電量消耗，建議啟用螢幕休眠。';

  @override
  String get sleepInfoDontShowAgain => '不再顯示';

  @override
  String get switchGpsLevel => '位置精度';

  @override
  String get gpxImport => '匯入 GPX 檔案';

  @override
  String get gpxExport => '匯出 GPX 檔案';

  @override
  String get gpxExportDialogTitle => '檔案名稱';

  @override
  String get gpxExportFilenameHint => '輸入檔案名稱（留空則使用日期/時間）';

  @override
  String gpxExportComplete(String filename) {
    return '已儲存 $filename';
  }

  @override
  String get gpxExportFailed => '匯出失敗';

  @override
  String get gpxExportPermissionDenied => '檔案儲存權限被拒絕';

  @override
  String get gpxExportSaveLocationMessage =>
      '預設情況下，匯出的檔案將儲存在以下位置：\n\niOS：\n[我的 iPhone] > [Brevet MAP]\n\nAndroid：\n[Files] > [下載]';

  @override
  String get poiAdd => '添加 POI';

  @override
  String get poiAddEdit => '添加或編輯 POI';

  @override
  String get poiAddByDistance => '依距離添加 POI';

  @override
  String get poiAddByMapTap => '透過點擊地圖添加 POI';

  @override
  String get poiTabAdd => '添加 POI';

  @override
  String get poiTabEdit => '編輯 POI';

  @override
  String get poiType => 'POI 類型';

  @override
  String get checkpoint => '檢查點';

  @override
  String get information => '資訊';

  @override
  String get title => '標題';

  @override
  String get body => '內容';

  @override
  String get plannedArrival => '到達';

  @override
  String get plannedDeparture => '出發';

  @override
  String get plannedClose => '截止時間';

  @override
  String get arrivalShort => '到達';

  @override
  String get departureShort => '出發';

  @override
  String get distance => '距離';

  @override
  String get titleNone => '（無標題）';

  @override
  String get kmRequired => '距離為必填項';

  @override
  String get offRoute => '偏離路線';

  @override
  String kmPoint(String km) {
    return '${km}km 點';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return '$kmLabel 點的 POI';
  }

  @override
  String get poiOffRoutePoi => '編輯 POI';

  @override
  String get changePoiPosition => '設為此位置';

  @override
  String get poiRegistered => 'POI 已添加';

  @override
  String get poiAddedFromShare => '已從分享連結添加 POI';

  @override
  String get shareUrlInvalid => '無法從分享連結取得座標';

  @override
  String get registerThisPlaceAsPoi => '在此添加 POI';

  @override
  String get poiUpdated => 'POI 已更新';

  @override
  String get poiDeleted => 'POI 已刪除';

  @override
  String get poiPositionChanged => 'POI 位置已更改';

  @override
  String get changePoiText => '更改 POI 標題和內容';

  @override
  String get changePoiPositionTitle => '更改 POI 位置';

  @override
  String get deletePoiConfirm => '刪除此 POI？';

  @override
  String get noPoiRegistered => '未添加 POI';

  @override
  String get changePoiTextTitle => '更改 POI 內容';

  @override
  String get routeOverwrite => '覆蓋目前路線';

  @override
  String get selectGpxFile => '請選擇 GPX 檔案';

  @override
  String get routeNotLoaded => '路線未載入';

  @override
  String get kmPointNotFound => '未找到指定的 km 點';

  @override
  String get kmExceedsRoute => '超過路線總距離';

  @override
  String get gpxInvalidFormat => '此檔案不是 GPX 格式';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX 不包含路線或航點';

  @override
  String get locationFailed => '取得位置失敗';

  @override
  String get mapStyleNormal => '以一般模式顯示地圖';

  @override
  String get mapStyleDark => '以深色模式顯示地圖';

  @override
  String get showFullRoute => '顯示完整路線';

  @override
  String get locationUnavailable => '位置不可用';

  @override
  String get locationUnavailableWithRetry => '位置不可用。點擊「顯示我的位置」重試，或在設定中允許位置存取。';

  @override
  String get openSettings => '開啟設定';

  @override
  String get locationInvalid => '位置無效';

  @override
  String get locationServiceOff => '定位服務已關閉。請在裝置設定中開啟。';

  @override
  String get locationPermissionRequired => '需要位置權限';

  @override
  String get locationPermissionDenied => '位置權限被拒絕。未取得授權無法顯示您的位置。';

  @override
  String get locationPermissionDeniedForever => '位置權限已設為「不再詢問」。請在應用程式設定中啟用。';

  @override
  String get sleepOffMessage => '螢幕休眠已停用';

  @override
  String get sleepOnMessage => '螢幕休眠已啟用';

  @override
  String get sleepOff => '關閉';

  @override
  String get sleepOn => '開啟';

  @override
  String get sleepSettingsNote => '請在裝置的設定應用程式中查看螢幕休眠時間';

  @override
  String get openSettingsApp => '開啟設定應用程式';

  @override
  String get distanceUnit => '距離單位';

  @override
  String get unitKm => '公里';

  @override
  String get unitMile => '英里';

  @override
  String get distanceUnitSetToKm => '距離單位已設為公里';

  @override
  String get distanceUnitSetToMile => '距離單位已設為英里';

  @override
  String get checkingConnectivity => '正在檢查連線...';

  @override
  String get fetchingLocation => '正在取得位置...';

  @override
  String get offline => '離線';

  @override
  String get retryConnectivity => '重試';

  @override
  String get offlineMap => '離線地圖';

  @override
  String get offlineMapMinimalMap => '最大縮放：15';

  @override
  String get offlineMapStandardMap => '最大縮放：16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return '最大縮放：15（$size）';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return '最大縮放：16（$size）';
  }

  @override
  String get offlineMapHighResMap => '最大縮放：17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return '最大縮放：17（$size）';
  }

  @override
  String get offlineMapZoomSmall => '縮放：限定';

  @override
  String get offlineMapZoomMedium => '縮放：標準';

  @override
  String get offlineMapZoomLarge => '縮放：擴展';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return '縮放：限定（$size）';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return '縮放：標準（$size）';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return '縮放：擴展（$size）';
  }

  @override
  String get offlineMapRequiresNetwork => '下載離線地圖需要網路連線';

  @override
  String get offlineMapNoRoute => '路線未載入。請先匯入 GPX 檔案。';

  @override
  String get offlineMapDownloading => '下載中... ';

  @override
  String get offlineMapCancel => '取消';

  @override
  String get offlineMapDownloadComplete => '離線地圖下載完成';

  @override
  String get offlineMapDownloadFailed => '下載失敗';

  @override
  String get offlineMapDownloadCancelled => '下載已取消';

  @override
  String get offlineMapWifiRecommendation => '由於資料量大，建議使用 Wi-Fi 下載';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return '由於資料量大，建議使用 Wi-Fi 下載。\n\n預計大小：約 $size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return '已儲存: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return '清除快取（$size）';
  }

  @override
  String get offlineMapCacheClear => '清除快取';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      '快取資料（含離線地圖）增多時，地圖顯示可能會變慢。\n\n地圖顯示流程：\n\n1. 快取查詢\n2-1. 有快取：\n無需網路存取\n2-2. 無快取：\n網路存取並儲存至快取\n3. 地圖顯示\n\n步驟1的快取查詢在資料越大時耗時越長。若地圖顯示變慢或為 brevet 儲存了大容量離線地圖，建議刪除快取。';

  @override
  String get offlineMapCacheClearConfirmButton => '刪除';

  @override
  String get offlineMapCacheCleared => '快取已清除';

  @override
  String get offlineMapInfoMessage1 => '離線地圖即使在線時也能減少網路存取並節省電量';

  @override
  String get offlineMapInfoMessage2 => '為保持應用程式順暢運行，建議在不再需要時刪除已下載的地圖';

  @override
  String get offlineMapInfoButton => '下載';

  @override
  String get registerAtPosition => '在此添加';

  @override
  String get locationSharing => '位置分享';

  @override
  String get aboutApp => '關於本應用程式';

  @override
  String get openSourceLicenses => '開源授權';

  @override
  String get rateApp => '評價應用程式';

  @override
  String get contactUs => '聯絡我們';

  @override
  String get language => '語言';

  @override
  String get useSystemLanguage => '使用系統語言';

  @override
  String get appSettingsTitle => '設定與其他';

  @override
  String get contactFormMailError => '無法開啟郵件應用程式';

  @override
  String get batteryLevelDisplay => '顯示電量';

  @override
  String get batteryLevelDisplayOn => '顯示';

  @override
  String get batteryLevelDisplayOff => '隱藏';

  @override
  String get batteryLevelDisplayIosNote => '由於iOS系統限制，電量以5%為單位顯示';

  @override
  String get trialInfoClose => '關閉';

  @override
  String get trialInfoSubscribe => '訂閱';

  @override
  String get trialInfoMessage => 'POI 添加和 GPX 匯出功能可免費試用 30 天！';

  @override
  String trialInfoRemainingDays(int days) {
    return '剩餘 $days 天';
  }

  @override
  String get poiPremiumMessage => '訂閱 Brevet MAP 進階版，即可編輯和刪除 POI！';

  @override
  String get poiPremiumViewPlans => '查看方案';

  @override
  String get subscription => '訂閱';

  @override
  String get restorePurchases => '恢復購買';

  @override
  String get restorePurchasesSuccess => '購買已恢復';

  @override
  String subscriptionAccountId(String id) {
    return '帳戶ID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return '到期日: $date';
  }

  @override
  String get subscriptionNotActive => '未訂閱';

  @override
  String get subscriptionTerms => '訂閱條款';

  @override
  String get manageSubscription => '管理訂閱';

  @override
  String get subscriptionPremiumBlurb =>
      'Brevet Map 進階版可在您購買的每個訂閱週期內解鎖地圖上的 POI 編輯與刪除等功能。';

  @override
  String subscriptionCurrentPlan(String name) {
    return '目前方案：$name';
  }

  @override
  String subscriptionPlanBillingUnit(String unit) {
    return '計費週期：$unit';
  }

  @override
  String get subscriptionUnitMonthly => '按月';

  @override
  String get subscriptionUnitYearly => '按年';

  @override
  String get subscriptionUnitWeekly => '按週';

  @override
  String get subscriptionExpiryNoDate => '進階版已生效，但無法載入續訂日期。';

  @override
  String get subscriptionAvailablePlans => '方案與價格';

  @override
  String get subscriptionPlansLoadError => '無法載入訂閱方案。請檢查網路後重試。';

  @override
  String get subscriptionPlansNotConfigured => '商店目前沒有可用的訂閱方案。';

  @override
  String subscriptionPlanRow(String title, String price, String periodSuffix) {
    return '$title\n$price$periodSuffix';
  }

  @override
  String subscriptionPeriodPart(String period) {
    return ' · $period';
  }

  @override
  String get subscriptionBillingPeriodWeek => '每週';

  @override
  String get subscriptionBillingPeriodMonth => '每月';

  @override
  String get subscriptionBillingPeriodThreeMonths => '每 3 個月';

  @override
  String get subscriptionBillingPeriodSixMonths => '每 6 個月';

  @override
  String get subscriptionBillingPeriodYear => '每年';

  @override
  String subscriptionBillingPeriodUnknown(String code) {
    return '週期：$code';
  }

  @override
  String get linkPrivacyPolicy => '隱私權政策';

  @override
  String get linkTermsOfUse => '使用條款';

  @override
  String get subscriptionOpenPaywall => '訂閱或變更方案';

  @override
  String get sampleRouteDialogMessage =>
      '地圖上顯示的路線是示範路線。實際使用時，請匯入並使用從騎行應用程式匯出的 GPX 檔案或活動提供的 GPX 檔案。';

  @override
  String get volumeButtonTutorial => '您可以使用裝置的音量鍵調整地圖縮放級別';

  @override
  String get save => '儲存';

  @override
  String get saveChangesConfirm => '儲存變更？';

  @override
  String get setStartDate => '設定出發日期';

  @override
  String get changeRideDate => '更改出發日期';

  @override
  String get releaseNotesDialogTitle => '發行說明';

  @override
  String get releaseNotesV11018Message =>
      '在 1.1 版本中，我們強化了 POI 資訊，讓您能更有效地規劃長距離騎行！\n此版本已開放所有功能，歡迎體驗！';
}

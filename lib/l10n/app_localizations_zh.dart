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
  String get sleepInfoMessage1 => '屏幕休眠时关闭GPS以节省电量';

  @override
  String get sleepInfoMessage2 => '要进一步节省电量，请将设备置于休眠状态。GPS也会关闭';

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
  String get poiAdd => '添加 POI';

  @override
  String get poiAddEdit => '添加或编辑POI';

  @override
  String get poiAddByDistance => '按距离添加POI';

  @override
  String get poiAddByMapTap => '从地图添加POI';

  @override
  String get poiTabAdd => '添加 POI';

  @override
  String get poiTabEdit => '编辑或删除POI';

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
  String get sleepOffMessage => '屏幕休眠已关闭';

  @override
  String sleepSetMessage(int minutes) {
    return '屏幕休眠已设置为 $minutes 分钟';
  }

  @override
  String get sleepOff => '关闭';

  @override
  String get sleep1min => '1分钟';

  @override
  String get sleep5min => '5分钟';

  @override
  String get sleep10min => '10分钟';

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
}

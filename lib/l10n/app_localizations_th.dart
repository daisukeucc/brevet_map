// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get ok => 'ตกลง';

  @override
  String get ng => 'NG';

  @override
  String get delete => 'ลบ';

  @override
  String get edit => 'แก้ไข';

  @override
  String get change => 'เปลี่ยน';

  @override
  String get add => 'เพิ่ม';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get share => 'แชร์';

  @override
  String get shareFailed => 'แชร์ล้มเหลว';

  @override
  String get showMyLocation => 'แสดงตำแหน่งของฉัน';

  @override
  String get sleepSettings => 'หน้าจอพักหน้าจอ';

  @override
  String get sleepInfoMessage1 =>
      'GPS จะปิดเมื่อหน้าจอพัก ดังนั้นแนะนำให้เปิดใช้งานการพักหน้าจอหากต้องการประหยัดแบตเตอรี่';

  @override
  String get sleepInfoDontShowAgain => 'ไม่แสดงอีก';

  @override
  String get switchGpsLevel => 'ความแม่นยำของตำแหน่ง';

  @override
  String get gpxImport => 'นำเข้าไฟล์ GPX';

  @override
  String get gpxExport => 'ส่งออกไฟล์ GPX';

  @override
  String get gpxExportDialogTitle => 'ชื่อไฟล์';

  @override
  String get gpxExportFilenameHint =>
      'ป้อนชื่อไฟล์ (ใช้วันที่/เวลาหากว่างเปล่า)';

  @override
  String gpxExportComplete(String filename) {
    return 'บันทึก $filename แล้ว';
  }

  @override
  String get gpxExportFailed => 'ส่งออกล้มเหลว';

  @override
  String get gpxExportPermissionDenied => 'ไม่มีสิทธิ์บันทึกไฟล์';

  @override
  String get poiAdd => 'เพิ่ม POI';

  @override
  String get poiAddEdit => 'เพิ่มหรือแก้ไข POI';

  @override
  String get poiAddByDistance => 'เพิ่ม POI ตามระยะทาง';

  @override
  String get poiAddByMapTap => 'เพิ่ม POI จากการแตะแผนที่';

  @override
  String get poiTabAdd => 'เพิ่ม POI';

  @override
  String get poiTabEdit => 'แก้ไขหรือลบ POI';

  @override
  String get poiType => 'ประเภท POI';

  @override
  String get checkpoint => 'จุดตรวจ';

  @override
  String get information => 'ข้อมูล';

  @override
  String get title => 'ชื่อเรื่อง';

  @override
  String get body => 'เนื้อหา';

  @override
  String get distance => 'ระยะทาง';

  @override
  String get titleNone => '(ไม่มีชื่อ)';

  @override
  String get kmRequired => 'ต้องระบุระยะทาง';

  @override
  String get offRoute => 'ออกนอกเส้นทาง';

  @override
  String kmPoint(String km) {
    return 'จุด $km กม.';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return 'POI ที่ $kmLabel';
  }

  @override
  String get poiOffRoutePoi => 'แก้ไข POI';

  @override
  String get changePoiPosition => 'ตั้งตำแหน่งนี้';

  @override
  String get poiRegistered => 'เพิ่ม POI แล้ว';

  @override
  String get poiAddedFromShare => 'เพิ่ม POI จากลิงก์ที่แชร์แล้ว';

  @override
  String get shareUrlInvalid => 'ไม่สามารถดึงพิกัดจากลิงก์ที่แชร์ได้';

  @override
  String get registerThisPlaceAsPoi => 'เพิ่ม POI ที่ตำแหน่งนี้';

  @override
  String get poiUpdated => 'อัปเดต POI แล้ว';

  @override
  String get poiDeleted => 'ลบ POI แล้ว';

  @override
  String get poiPositionChanged => 'เปลี่ยนตำแหน่ง POI แล้ว';

  @override
  String get changePoiText => 'เปลี่ยนชื่อและเนื้อหา POI';

  @override
  String get changePoiPositionTitle => 'เปลี่ยนตำแหน่ง POI';

  @override
  String get deletePoiConfirm => 'ลบ POI นี้?';

  @override
  String get noPoiRegistered => 'ไม่มี POI ที่ลงทะเบียน';

  @override
  String get changePoiTextTitle => 'เปลี่ยนเนื้อหา POI';

  @override
  String get routeOverwrite => 'เขียนทับเส้นทางปัจจุบัน';

  @override
  String get selectGpxFile => 'กรุณาเลือกไฟล์ GPX';

  @override
  String get routeNotLoaded => 'ยังไม่ได้โหลดเส้นทาง';

  @override
  String get kmPointNotFound => 'ไม่พบจุด กม. ที่ระบุ';

  @override
  String get kmExceedsRoute => 'เกินระยะทางรวมของเส้นทาง';

  @override
  String get gpxInvalidFormat => 'ไฟล์นี้ไม่ใช่รูปแบบ GPX';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX ไม่มีเส้นทางหรือ waypoint';

  @override
  String get locationFailed => 'ไม่สามารถรับตำแหน่งได้';

  @override
  String get mapStyleNormal => 'แสดงแผนที่ในโหมดปกติ';

  @override
  String get mapStyleDark => 'แสดงแผนที่ในโหมดมืด';

  @override
  String get showFullRoute => 'แสดงเส้นทางทั้งหมด';

  @override
  String get locationUnavailable => 'ไม่สามารถระบุตำแหน่งได้';

  @override
  String get locationUnavailableWithRetry =>
      'ไม่สามารถระบุตำแหน่งได้ แตะ \"แสดงตำแหน่งของฉัน\" เพื่อลองใหม่ หรืออนุญาตการเข้าถึงตำแหน่งในการตั้งค่า';

  @override
  String get openSettings => 'เปิดการตั้งค่า';

  @override
  String get locationInvalid => 'ตำแหน่งไม่ถูกต้อง';

  @override
  String get locationServiceOff =>
      'บริการตำแหน่งปิดอยู่ กรุณาเปิดในการตั้งค่าอุปกรณ์';

  @override
  String get locationPermissionRequired => 'ต้องการสิทธิ์ตำแหน่ง';

  @override
  String get locationPermissionDenied =>
      'สิทธิ์ตำแหน่งถูกปฏิเสธ ไม่สามารถแสดงตำแหน่งของคุณได้หากไม่มีสิทธิ์';

  @override
  String get locationPermissionDeniedForever =>
      'สิทธิ์ตำแหน่งถูกตั้งเป็น \"ไม่ถามอีก\" กรุณาเปิดใช้งานในการตั้งค่าแอป';

  @override
  String get sleepOffMessage => 'ปิดการพักหน้าจอแล้ว';

  @override
  String get sleepOnMessage => 'เปิดการพักหน้าจอแล้ว';

  @override
  String get sleepOff => 'ปิด';

  @override
  String get sleepOn => 'เปิด';

  @override
  String get sleepSettingsNote =>
      'ตรวจสอบระยะเวลาพักหน้าจอในแอปการตั้งค่าของอุปกรณ์';

  @override
  String get openSettingsApp => 'เปิดแอปการตั้งค่า';

  @override
  String get distanceUnit => 'หน่วยระยะทาง';

  @override
  String get unitKm => 'กม.';

  @override
  String get unitMile => 'ไมล์';

  @override
  String get distanceUnitSetToKm => 'ตั้งหน่วยระยะทางเป็น กม. แล้ว';

  @override
  String get distanceUnitSetToMile => 'ตั้งหน่วยระยะทางเป็น ไมล์ แล้ว';

  @override
  String get checkingConnectivity => 'กำลังตรวจสอบการเชื่อมต่อ...';

  @override
  String get fetchingLocation => 'กำลังรับตำแหน่ง...';

  @override
  String get offline => 'ออฟไลน์';

  @override
  String get retryConnectivity => 'ลองใหม่';

  @override
  String get offlineMap => 'แผนที่ออฟไลน์';

  @override
  String get offlineMapMinimalMap => 'ซูมสูงสุด: 15';

  @override
  String get offlineMapStandardMap => 'ซูมสูงสุด: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return 'ซูมสูงสุด: 15 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return 'ซูมสูงสุด: 16 ($size)';
  }

  @override
  String get offlineMapHighResMap => 'ซูมสูงสุด: 17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return 'ซูมสูงสุด: 17 ($size)';
  }

  @override
  String get offlineMapZoomSmall => 'ซูม: จำกัด';

  @override
  String get offlineMapZoomMedium => 'ซูม: มาตรฐาน';

  @override
  String get offlineMapZoomLarge => 'ซูม: ขยาย';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return 'ซูม: จำกัด ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return 'ซูม: มาตรฐาน ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return 'ซูม: ขยาย ($size)';
  }

  @override
  String get offlineMapRequiresNetwork =>
      'ต้องการการเชื่อมต่อเครือข่ายเพื่อดาวน์โหลดแผนที่ออฟไลน์';

  @override
  String get offlineMapNoRoute =>
      'ยังไม่ได้โหลดเส้นทาง กรุณานำเข้าไฟล์ GPX ก่อน';

  @override
  String get offlineMapDownloading => 'กำลังดาวน์โหลด... ';

  @override
  String get offlineMapCancel => 'ยกเลิก';

  @override
  String get offlineMapDownloadComplete => 'ดาวน์โหลดแผนที่ออฟไลน์เสร็จสมบูรณ์';

  @override
  String get offlineMapDownloadFailed => 'ดาวน์โหลดล้มเหลว';

  @override
  String get offlineMapDownloadCancelled => 'ยกเลิกการดาวน์โหลดแล้ว';

  @override
  String get offlineMapWifiRecommendation =>
      'แนะนำให้ดาวน์โหลดผ่าน Wi-Fi เนื่องจากข้อมูลมีขนาดใหญ่';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return 'แนะนำให้ดาวน์โหลดผ่าน Wi-Fi เนื่องจากข้อมูลมีขนาดใหญ่\n\nขนาดโดยประมาณ: ~$size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return 'จัดเก็บแล้ว: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return 'ล้างแคช ($size)';
  }

  @override
  String get offlineMapCacheClear => 'ล้างแคช';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      'เมื่อข้อมูลแคช (รวมถึงแผนที่ออฟไลน์) เพิ่มขึ้น การแสดงแผนที่อาจช้าลง\n\nขั้นตอนการแสดงแผนที่:\n\n1. ค้นหาแคช\n2-1. หากมีแคช:\nไม่เข้าถึงเครือข่าย\n2-2. หากไม่มีแคช:\nเข้าถึงเครือข่ายและบันทึกลงแคช\n3. แสดงแผนที่\n\nขั้นตอนที่ 1 ใช้เวลานานขึ้นเมื่อข้อมูลมีขนาดใหญ่ ดังนั้นหากแผนที่ช้าลงหรือคุณบันทึกแผนที่ออฟไลน์ขนาดใหญ่ไว้ แนะนำให้ลบแคช';

  @override
  String get offlineMapCacheClearConfirmButton => 'ลบ';

  @override
  String get offlineMapCacheCleared => 'ล้างแคชแล้ว';

  @override
  String get offlineMapInfoMessage1 =>
      'แผนที่ออฟไลน์ช่วยลดการเข้าถึงเครือข่ายและประหยัดแบตเตอรี่แม้ขณะออนไลน์';

  @override
  String get offlineMapInfoMessage2 =>
      'เพื่อให้แอปทำงานได้อย่างราบรื่น แนะนำให้ลบแผนที่ที่ดาวน์โหลดไว้เมื่อไม่ต้องการแล้ว';

  @override
  String get offlineMapInfoButton => 'ดาวน์โหลด';

  @override
  String get registerAtPosition => 'เพิ่มที่นี่';

  @override
  String get locationSharing => 'แชร์ตำแหน่ง';

  @override
  String get aboutApp => 'เกี่ยวกับแอปนี้';

  @override
  String get rateApp => 'ให้คะแนนแอปนี้';

  @override
  String get contactUs => 'ติดต่อ';

  @override
  String get language => 'ภาษา';

  @override
  String get useSystemLanguage => 'ค่าเริ่มต้นของระบบ';

  @override
  String get appSettingsTitle => 'การตั้งค่าและอื่นๆ';

  @override
  String get contactFormMailError => 'ไม่สามารถเปิดแอปเมลได้';

  @override
  String get batteryLevelDisplay => 'แสดงระดับแบตเตอรี่';

  @override
  String get batteryLevelDisplayOn => 'เปิด';

  @override
  String get batteryLevelDisplayOff => 'ปิด';

  @override
  String get batteryLevelDisplayIosNote =>
      'บน iOS ค่าจะแสดงเป็นขั้น 5% เนื่องจากข้อจำกัดของ OS';

  @override
  String get trialInfoClose => 'ปิด';

  @override
  String get trialInfoSubscribe => 'สมัครสมาชิก';

  @override
  String get trialInfoMessage =>
      'ลองใช้ฟีเจอร์เพิ่ม POI และส่งออก GPX ฟรี 30 วัน';

  @override
  String trialInfoRemainingDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'เหลือ $days วัน',
      one: 'เหลือ 1 วัน',
    );
    return '$_temp0';
  }

  @override
  String get poiPremiumMessage =>
      'สมัคร Brevet MAP Premium เพื่อแก้ไขและลบ POI!';

  @override
  String get poiPremiumViewPlans => 'ดูแผน';

  @override
  String get subscription => 'สมัครสมาชิก';

  @override
  String get restorePurchases => 'กู้คืนการซื้อ';

  @override
  String get restorePurchasesSuccess => 'กู้คืนการซื้อแล้ว';

  @override
  String subscriptionAccountId(String id) {
    return 'รหัสบัญชี: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return 'หมดอายุ: $date';
  }

  @override
  String get subscriptionNotActive => 'ยังไม่ได้สมัครสมาชิก';

  @override
  String get subscriptionTerms => 'เงื่อนไขการสมัครสมาชิก';

  @override
  String get manageSubscription => 'จัดการการสมัครสมาชิก';
}

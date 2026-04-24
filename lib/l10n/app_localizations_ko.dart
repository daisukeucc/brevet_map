// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Brevet Map';

  @override
  String get appTitleBrand => 'Brevet Map';

  @override
  String get cancel => '취소';

  @override
  String get ok => '확인';

  @override
  String get ng => 'NG';

  @override
  String get delete => '삭제';

  @override
  String get edit => '편집';

  @override
  String get change => '변경';

  @override
  String get add => '추가';

  @override
  String get next => '다음';

  @override
  String get settings => '설정';

  @override
  String get share => '공유';

  @override
  String get shareFailed => '공유 실패';

  @override
  String get showMyLocation => '내 위치 표시';

  @override
  String get sleepSettings => '화면 절전';

  @override
  String get sleepInfoMessage1 =>
      '화면이 절전 상태가 되면 GPS가 꺼집니다. 배터리 소비를 줄이려면 화면 절전을 활성화하는 것을 권장합니다.';

  @override
  String get sleepInfoDontShowAgain => '다시 표시하지 않음';

  @override
  String get switchGpsLevel => '위치 정확도';

  @override
  String get gpxImport => 'GPX 파일 가져오기';

  @override
  String get gpxExport => 'GPX 파일 내보내기';

  @override
  String get gpxExportDialogTitle => '파일 이름';

  @override
  String get gpxExportFilenameHint => '파일 이름 입력 (비워두면 날짜/시간 사용)';

  @override
  String gpxExportComplete(String filename) {
    return '$filename 저장됨';
  }

  @override
  String get gpxExportFailed => '내보내기 실패';

  @override
  String get gpxExportPermissionDenied => '파일 저장 권한이 거부되었습니다';

  @override
  String get gpxExportSaveLocationMessage =>
      '기본적으로 내보낸 파일은 다음 위치에 저장됩니다.\n\niOS:\n[나의 iPhone] > [Brevet MAP]\n\nAndroid:\n[파일] > [다운로드]';

  @override
  String get poiAdd => 'POI 추가';

  @override
  String get poiAddEdit => 'POI 추가 또는 편집';

  @override
  String get poiAddByDistance => '거리로 POI 추가';

  @override
  String get poiAddByMapTap => '지도에서 탭하여 POI 추가';

  @override
  String get poiTabAdd => 'POI 추가';

  @override
  String get poiTabEdit => 'POI 편집 또는 삭제';

  @override
  String get poiType => 'POI 유형';

  @override
  String get checkpoint => '체크포인트';

  @override
  String get information => '정보';

  @override
  String get title => '제목';

  @override
  String get body => '본문';

  @override
  String get plannedArrival => '도착 예정';

  @override
  String get plannedDeparture => '출발 예정';

  @override
  String get arrivalShort => '도착 예정';

  @override
  String get departureShort => '출발 예정';

  @override
  String get distance => '거리';

  @override
  String get titleNone => '(제목 없음)';

  @override
  String get kmRequired => '거리를 입력해 주세요';

  @override
  String get offRoute => '경로 이탈';

  @override
  String kmPoint(String km) {
    return '${km}km 지점';
  }

  @override
  String poiAtKmPoint(String kmLabel) {
    return '$kmLabel 지점의 POI';
  }

  @override
  String get poiOffRoutePoi => 'POI 편집';

  @override
  String get changePoiPosition => '이 위치로 설정';

  @override
  String get poiRegistered => 'POI 추가됨';

  @override
  String get poiAddedFromShare => '공유 링크에서 POI 추가됨';

  @override
  String get shareUrlInvalid => '공유된 링크에서 좌표를 추출할 수 없습니다';

  @override
  String get registerThisPlaceAsPoi => '여기에 POI 추가';

  @override
  String get poiUpdated => 'POI 업데이트됨';

  @override
  String get poiDeleted => 'POI 삭제됨';

  @override
  String get poiPositionChanged => 'POI 위치 변경됨';

  @override
  String get changePoiText => 'POI 제목 및 본문 변경';

  @override
  String get changePoiPositionTitle => 'POI 위치 변경';

  @override
  String get deletePoiConfirm => '이 POI를 삭제하시겠습니까?';

  @override
  String get noPoiRegistered => '추가된 POI가 없습니다';

  @override
  String get changePoiTextTitle => 'POI 내용 변경';

  @override
  String get routeOverwrite => '현재 경로 덮어쓰기';

  @override
  String get selectGpxFile => 'GPX 파일을 선택해 주세요';

  @override
  String get routeNotLoaded => '경로가 로드되지 않았습니다';

  @override
  String get kmPointNotFound => '지정한 km 지점을 찾을 수 없습니다';

  @override
  String get kmExceedsRoute => '루트 총 거리를 초과했습니다';

  @override
  String get gpxInvalidFormat => '이 파일은 GPX 형식이 아닙니다';

  @override
  String get gpxNoRouteOrWaypoint => 'GPX에 경로 또는 웨이포인트가 없습니다';

  @override
  String get locationFailed => '위치를 가져오지 못했습니다';

  @override
  String get mapStyleNormal => '일반 모드로 지도 표시';

  @override
  String get mapStyleDark => '다크 모드로 지도 표시';

  @override
  String get showFullRoute => '전체 경로 표시';

  @override
  String get locationUnavailable => '위치를 사용할 수 없음';

  @override
  String get locationUnavailableWithRetry =>
      '위치를 사용할 수 없습니다. \"내 위치 표시\"를 탭하여 다시 시도하거나 설정에서 위치 액세스를 허용하세요.';

  @override
  String get openSettings => '설정 열기';

  @override
  String get locationInvalid => '위치가 올바르지 않습니다';

  @override
  String get locationServiceOff => '위치 서비스가 꺼져 있습니다. 기기 설정에서 켜 주세요.';

  @override
  String get locationPermissionRequired => '위치 권한이 필요합니다';

  @override
  String get locationPermissionDenied =>
      '위치 권한이 거부되었습니다. 권한 없이는 위치를 표시할 수 없습니다.';

  @override
  String get locationPermissionDeniedForever =>
      '위치 권한이 \"다시 묻지 않음\"으로 설정되어 있습니다. 앱 설정에서 활성화해 주세요.';

  @override
  String get sleepOffMessage => '화면 절전 꺼짐';

  @override
  String get sleepOnMessage => '화면 절전 켜짐';

  @override
  String get sleepOff => 'OFF';

  @override
  String get sleepOn => 'ON';

  @override
  String get sleepSettingsNote => '화면 절전 시간은 기기의 설정 앱에서 확인하세요';

  @override
  String get openSettingsApp => '설정 앱 열기';

  @override
  String get distanceUnit => '거리 단위';

  @override
  String get unitKm => 'km';

  @override
  String get unitMile => '마일';

  @override
  String get distanceUnitSetToKm => '거리 단위를 km로 설정했습니다';

  @override
  String get distanceUnitSetToMile => '거리 단위를 마일로 설정했습니다';

  @override
  String get checkingConnectivity => '연결 확인 중...';

  @override
  String get fetchingLocation => '위치 가져오는 중...';

  @override
  String get offline => '오프라인';

  @override
  String get retryConnectivity => '다시 시도';

  @override
  String get offlineMap => '오프라인 지도';

  @override
  String get offlineMapMinimalMap => '최대 줌: 15';

  @override
  String get offlineMapStandardMap => '최대 줌: 16';

  @override
  String offlineMapMinimalMapWithSize(String size) {
    return '최대 줌: 15 ($size)';
  }

  @override
  String offlineMapStandardMapWithSize(String size) {
    return '최대 줌: 16 ($size)';
  }

  @override
  String get offlineMapHighResMap => '최대 줌: 17';

  @override
  String offlineMapHighResMapWithSize(String size) {
    return '최대 줌: 17 ($size)';
  }

  @override
  String get offlineMapZoomSmall => '줌: 제한';

  @override
  String get offlineMapZoomMedium => '줌: 표준';

  @override
  String get offlineMapZoomLarge => '줌: 확장';

  @override
  String offlineMapZoomSmallWithSize(String size) {
    return '줌: 제한 ($size)';
  }

  @override
  String offlineMapZoomMediumWithSize(String size) {
    return '줌: 표준 ($size)';
  }

  @override
  String offlineMapZoomLargeWithSize(String size) {
    return '줌: 확장 ($size)';
  }

  @override
  String get offlineMapRequiresNetwork => '오프라인 지도를 다운로드하려면 네트워크 연결이 필요합니다';

  @override
  String get offlineMapNoRoute => '경로가 로드되지 않았습니다. 먼저 GPX 파일을 가져오세요.';

  @override
  String get offlineMapDownloading => '다운로드 중... ';

  @override
  String get offlineMapCancel => '취소';

  @override
  String get offlineMapDownloadComplete => '오프라인 지도 다운로드 완료';

  @override
  String get offlineMapDownloadFailed => '다운로드 실패';

  @override
  String get offlineMapDownloadCancelled => '다운로드 취소됨';

  @override
  String get offlineMapWifiRecommendation =>
      '데이터 용량이 크므로 Wi-Fi로 다운로드하는 것을 권장합니다';

  @override
  String offlineMapWifiRecommendationWithSize(String size) {
    return '데이터 용량이 크므로 Wi-Fi로 다운로드하는 것을 권장합니다.\n\n예상 크기: 약 $size';
  }

  @override
  String offlineMapCurrentStorage(String size) {
    return '저장됨: $size';
  }

  @override
  String offlineMapCacheClearWithSize(String size) {
    return '캐시 지우기 ($size)';
  }

  @override
  String get offlineMapCacheClear => '캐시 지우기';

  @override
  String get offlineMapCacheClearConfirmMessage =>
      '캐시 데이터(오프라인 지도 포함)가 늘어나면 지도 표시가 느려질 수 있습니다.\n\n지도 표시 흐름:\n\n1. 캐시 조회\n2-1. 캐시 있음:\n네트워크 접근 없음\n2-2. 캐시 없음:\n네트워크 접근 후 캐시 저장\n3. 지도 표시\n\n1단계 캐시 조회는 데이터가 클수록 시간이 더 걸립니다. 지도가 느려지거나 브레베용 대용량 오프라인 지도를 저장한 경우 캐시 삭제를 권장합니다.';

  @override
  String get offlineMapCacheClearConfirmButton => '삭제';

  @override
  String get offlineMapCacheCleared => '캐시를 지웠습니다';

  @override
  String get offlineMapInfoMessage1 =>
      '오프라인 지도는 온라인 상태에서도 네트워크 접근을 줄이고 배터리를 절약합니다';

  @override
  String get offlineMapInfoMessage2 =>
      '앱을 원활하게 사용하기 위해 더 이상 필요하지 않은 지도는 삭제하는 것을 권장합니다';

  @override
  String get offlineMapInfoButton => '다운로드';

  @override
  String get registerAtPosition => '여기에 추가';

  @override
  String get locationSharing => '위치 정보 공유';

  @override
  String get aboutApp => '이 앱에 대해';

  @override
  String get openSourceLicenses => '오픈 소스 라이선스';

  @override
  String get rateApp => '앱 평가하기';

  @override
  String get contactUs => '문의';

  @override
  String get language => '언어';

  @override
  String get useSystemLanguage => '시스템 설정 사용';

  @override
  String get appSettingsTitle => '설정 & 기타';

  @override
  String get contactFormMailError => '메일 앱을 열 수 없습니다';

  @override
  String get batteryLevelDisplay => '배터리 잔량 표시';

  @override
  String get batteryLevelDisplayOn => '표시';

  @override
  String get batteryLevelDisplayOff => '숨김';

  @override
  String get batteryLevelDisplayIosNote => 'iOS에서는 OS 제한으로 인해 5% 단위로 표시됩니다';

  @override
  String get trialInfoClose => '닫기';

  @override
  String get trialInfoSubscribe => '구독';

  @override
  String get trialInfoMessage => 'POI 추가 및 GPX 내보내기 기능을 30일간 무료로 이용하실 수 있습니다!';

  @override
  String trialInfoRemainingDays(int days) {
    return '남은 기간: $days일';
  }

  @override
  String get poiPremiumMessage => 'Brevet MAP 프리미엄에 가입하여 POI를 편집하고 삭제하세요!';

  @override
  String get poiPremiumViewPlans => '플랜 보기';

  @override
  String get subscription => '구독';

  @override
  String get restorePurchases => '구매 복원';

  @override
  String get restorePurchasesSuccess => '구매가 복원되었습니다';

  @override
  String subscriptionAccountId(String id) {
    return '계정 ID: $id';
  }

  @override
  String subscriptionExpiry(String date) {
    return '만료일: $date';
  }

  @override
  String get subscriptionNotActive => '미가입';

  @override
  String get subscriptionTerms => '구독 약관';

  @override
  String get manageSubscription => '구독 관리';

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
      '지도에 표시된 경로는 샘플 경로입니다. 실제로 사용하려면 사이클링 앱에서 내보낸 GPX 파일이나 이벤트에서 제공된 GPX 파일을 가져와 사용해 주세요.';

  @override
  String get volumeButtonTutorial => '기기의 볼륨 버튼으로 지도 줌 레벨을 조절할 수 있습니다';

  @override
  String get save => '저장';

  @override
  String get saveChangesConfirm => '변경 사항을 저장하시겠습니까?';

  @override
  String get setStartDate => '출발 날짜 설정';

  @override
  String get changeRideDate => '출발 날짜 변경';
}

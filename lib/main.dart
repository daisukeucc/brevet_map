import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import 'config/tile_config.dart';
import 'data/repositories/first_launch_repository.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/providers.dart';
import 'presentation/screens/home_screen.dart';

Future<void> _initRevenueCat() async {
  final apiKey = Platform.isIOS
      ? dotenv.env['REVENUECAT_IOS_API_KEY'] ?? ''
      : dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
  if (apiKey.isEmpty) return;
  await Purchases.setLogLevel(LogLevel.debug);
  await Purchases.configure(PurchasesConfiguration(apiKey));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // スプラッシュ画面を表示する
  WidgetsBinding.instance.deferFirstFrame();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // デコード済みタイル画像のメモリキャッシュを拡張（デフォルト: 100MB / 1000枚）
  // ルート表示・地図回転時のグレー化を軽減する
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      256 * 1024 * 1024; // 256MB
  PaintingBinding.instance.imageCache.maximumSize = 3000;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // RevenueCat は await せず起動をブロックしない（fire-and-forget）。
  // await すると Android でスプラッシュ画面が固まることがある。
  // また、await なしで常に configure を呼ぶことで、オフライン時も SDK が初期化済みになり
  // Purchases.getCustomerInfo() 呼び出し時のネイティブクラッシュを防ぐ。
  _initRevenueCat();

  await TileConfig.initUserAgentPackageName();

  // 初回起動判定を main() で事前ロードする。
  // initState() での SharedPreferences 初期化は RevenueCat の
  // ネイティブ処理と競合して 1〜3 秒遅延することがあり、
  // その間 ConnectivityCheckingView が表示されてスプラッシュが固着して見えるため。
  bool firstLaunch = false;
  try {
    firstLaunch = await isFirstLaunch()
        .timeout(const Duration(seconds: 3), onTimeout: () => false);
  } catch (_) {}

  // FMTC（タイルキャッシュ）は allowFirstFrame 後に [_FmtcBackgroundInit] で起動。
  // main で await するとスプラッシュが長く止まるため。

  runApp(
    ProviderScope(
      overrides: [cachedFirstLaunchProvider.overrideWithValue(firstLaunch)],
      child: const _FmtcBackgroundInit(
        child: MyApp(),
      ),
    ),
  );
  // await Future.delayed(const Duration(milliseconds: 200));
  WidgetsBinding.instance.allowFirstFrame();
}

/// allowFirstFrame 後の最初のフレームで FMTC を初期化し、成功時にタイルレイヤーを再構築する。
class _FmtcBackgroundInit extends ConsumerStatefulWidget {
  const _FmtcBackgroundInit({required this.child});

  final Widget child;

  @override
  ConsumerState<_FmtcBackgroundInit> createState() =>
      _FmtcBackgroundInitState();
}

class _FmtcBackgroundInitState extends ConsumerState<_FmtcBackgroundInit> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFmtcInit());
  }

  Future<void> _runFmtcInit() async {
    try {
      await FMTCObjectBoxBackend()
          .initialise()
          .timeout(const Duration(seconds: 5));
      await const FMTCStore('mapStore')
          .manage
          .create()
          .timeout(const Duration(seconds: 3));
      if (!mounted) return;
      TileConfig.fmtcReady = true;
      ref.read(mapTileProviderKeyProvider.notifier).state++;
    } catch (_) {
      // FMTC 初期化失敗時はキャッシュなしで動作継続（NetworkTileProvider を使用）
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Brevet Map',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Builder(
        builder: (context) => MyHomePage(
          title: AppLocalizations.of(context)!.appTitle,
        ),
      ),
    );
  }
}

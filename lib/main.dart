import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/tile_config.dart';
import 'l10n/app_localizations.dart';
import 'presentation/providers/app_settings_providers.dart';
import 'presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await initializeDateFormatting();

  // デコード済みタイル画像のメモリキャッシュを拡張（デフォルト: 100MB / 1000枚）
  // ルート表示・地図回転時のグレー化を軽減する
  PaintingBinding.instance.imageCache.maximumSizeBytes =
      256 * 1024 * 1024; // 256MB
  PaintingBinding.instance.imageCache.maximumSize = 3000;

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}
  await TileConfig.initUserAgentPackageName();
  // クラッシュ後の ObjectBox DB 不正状態で initialise() が無限待機することがある。
  // タイムアウトで強制脱出し、キャッシュなしで起動を継続する。
  try {
    await FMTCObjectBoxBackend()
        .initialise()
        .timeout(const Duration(seconds: 5));
    await const FMTCStore('mapStore')
        .manage
        .create()
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    // FMTC 初期化失敗時はキャッシュなしで動作継続
  }
  runApp(const ProviderScope(child: MyApp()));
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

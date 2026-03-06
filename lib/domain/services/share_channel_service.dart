import 'package:flutter/services.dart';

/// 共有（Google Maps URL など）受信用の MethodChannel。Android / iOS 共通。
class ShareChannelService {
  ShareChannelService._();

  static const _channel = MethodChannel('com.example.brevet_map/share');

  /// 共有されたテキスト（URL）を受信したときのハンドラを登録する。
  static void setMethodCallHandler(void Function(String url) onSharedUrlReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrlReceived' && call.arguments != null) {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          onSharedUrlReceived(url);
        }
      }
    });
  }

  /// 起動時に共有されたURLを取得する。無い場合は null。
  static Future<String?> getInitialSharedUrl() async {
    try {
      return await _channel.invokeMethod<String?>('getInitialSharedUrl');
    } on PlatformException catch (_) {
      return null;
    }
  }
}

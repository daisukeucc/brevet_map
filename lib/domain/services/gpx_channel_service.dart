import 'package:flutter/services.dart';

/// GPX ファイル受信用の MethodChannel。ハンドラ登録と起動時コンテンツ取得を提供する。
class GpxChannelService {
  GpxChannelService._();

  static const _channel = MethodChannel('com.example.brevet_map/gpx');

  /// ネイティブから GPX が渡されたときに呼ばれるハンドラを登録する。
  static void setMethodCallHandler(void Function(String content) onGpxReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onGpxFileReceived' && call.arguments != null) {
        final content = call.arguments as String?;
        if (content != null && content.isNotEmpty) {
          onGpxReceived(content);
        }
      }
    });
  }

  /// 起動時にネイティブへ「初期 GPX コンテンツ」を要求する。無い場合は null。
  static Future<String?> getInitialGpxContent() async {
    try {
      return await _channel.invokeMethod<String?>('getInitialGpxContent');
    } on PlatformException catch (_) {
      return null;
    }
  }
}

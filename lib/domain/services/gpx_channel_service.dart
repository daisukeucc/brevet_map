import 'package:flutter/services.dart';

/// ネイティブから受け取った GPX（本文と、取れた場合はインポート用ファイル名ベース）
class GpxChannelPayload {
  const GpxChannelPayload({required this.content, this.importBasename});

  final String content;

  /// 拡張子 `.gpx` を除く表示名。[saveGpxImportBasename] に保存する値と同じ形式。
  final String? importBasename;

  static GpxChannelPayload? parse(dynamic arguments) {
    if (arguments == null) return null;
    if (arguments is String) {
      final s = arguments.trim();
      return s.isEmpty ? null : GpxChannelPayload(content: s);
    }
    if (arguments is Map) {
      final content = arguments['content'];
      if (content is! String || content.trim().isEmpty) return null;
      final baseRaw = arguments['basename'];
      String? base;
      if (baseRaw is String) {
        final t = baseRaw.trim();
        if (t.isNotEmpty) base = t;
      }
      return GpxChannelPayload(content: content, importBasename: base);
    }
    return null;
  }
}

/// GPX ファイル受信用の MethodChannel。ハンドラ登録と起動時コンテンツ取得を提供する。
class GpxChannelService {
  GpxChannelService._();

  static const _channel = MethodChannel('com.brevetmap/gpx');

  /// ネイティブから GPX が渡されたときに呼ばれるハンドラを登録する。
  static void setMethodCallHandler(void Function(GpxChannelPayload payload) onGpxReceived) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onGpxFileReceived' && call.arguments != null) {
        final payload = GpxChannelPayload.parse(call.arguments);
        if (payload != null) {
          onGpxReceived(payload);
        }
      }
    });
  }

  /// 起動時にネイティブへ「初期 GPX」を要求する。無い場合は null。
  static Future<GpxChannelPayload?> getInitialGpxPayload() async {
    try {
      final raw = await _channel.invokeMethod<Object?>('getInitialGpxContent');
      return GpxChannelPayload.parse(raw);
    } on PlatformException catch (_) {
      return null;
    } on MissingPluginException catch (_) {
      return null;
    }
  }
}

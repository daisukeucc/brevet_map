import 'package:http/http.dart' as http;

/// 軽量な接続チェック用 URL（204 No Content を返す）
const connectivityCheckUrl = 'https://www.gstatic.com/generate_204';

/// デフォルトの接続チェックタイムアウト
const defaultConnectivityTimeout = Duration(seconds: 5);

/// ネットワーク接続状態をチェックする。
///
/// HTTP リクエストで実インターネット到達を確認する。
/// connectivity_plus の iOS クラッシュを避けるためにこの方式を採用。
///
/// [timeout] を指定しない場合 [defaultConnectivityTimeout] が使用される。
///
/// 使用例:
/// ```dart
/// if (await checkConnectivity()) {
///   // オンライン時の処理
/// } else {
///   // オフライン時の処理
/// }
/// ```
Future<bool> checkConnectivity({
  Duration timeout = defaultConnectivityTimeout,
}) async {
  try {
    final response = await http
        .head(Uri.parse(connectivityCheckUrl))
        .timeout(timeout);
    return response.statusCode == 204 || response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

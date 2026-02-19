import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Maps 系API用のキー
///
/// 優先順位: .env の GOOGLE_MAPS_API_KEY → --dart-define=GOOGLE_MAPS_API_KEY
/// .env を使う場合: プロジェクトルートに .env を作成し GOOGLE_MAPS_API_KEY=あなたのキー を記述。
/// （env.example をコピー: cp env.example .env）
String get googleMapsApiKey =>
    dotenv.env['GOOGLE_MAPS_API_KEY']?.trim() ??
    String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: '');

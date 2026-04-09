import 'package:flutter/material.dart';

/// アプリ全体で使用するテキストスタイル
abstract class AppTextStyles {
  /// 見出し
  static const TextStyle headline =
      TextStyle(fontSize: 20, color: Colors.black87);

  /// タイトル
  static const TextStyle title = TextStyle(fontSize: 17, color: Colors.black87);

  /// 本文
  static const TextStyle body = TextStyle(fontSize: 16, color: Colors.black87);

  /// 本文（小）
  static const TextStyle bodySmall =
      TextStyle(fontSize: 15, color: Colors.black87);

  /// ラベル（ラジオ項目など）
  static const TextStyle label = TextStyle(fontSize: 16, color: Colors.black87);

  /// ボタン
  static const TextStyle button =
      TextStyle(fontSize: 17, color: Colors.black54);

  /// ボタン（小）
  static const TextStyle buttonSmall =
      TextStyle(fontSize: 14, color: Colors.black54);
}

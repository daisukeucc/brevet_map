import 'package:flutter/material.dart';

/// アプリ全体で使用するテキストスタイル
abstract class AppTextStyles {
  /// 見出し
  static const TextStyle headline =
      TextStyle(fontSize: 20, color: Colors.black87);

  /// 見出し
  static const TextStyle headlineMedium =
      TextStyle(fontSize: 18, color: Colors.black87);

  /// タイトル
  static const TextStyle title = TextStyle(fontSize: 17, color: Colors.black87);

  static const TextStyle poiLarge = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    color: Colors.black54,
  );

  static const TextStyle poiSchedule = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static const TextStyle poiTitle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static const TextStyle poiDetail = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

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

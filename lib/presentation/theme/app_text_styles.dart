import 'package:flutter/material.dart';

/// アプリ全体で使用するカラー定数
abstract class AppColors {
  static const Color muted = Colors.black54;
}

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
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
  );

  static const TextStyle poiMedium = TextStyle(
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.muted,
  );

  static const TextStyle poiScheduleLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  static const TextStyle poiSchedule = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const TextStyle poiTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
  );

  static const TextStyle poiDetail = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
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
      TextStyle(fontSize: 17, color: AppColors.muted);

  /// ボタン（小）
  static const TextStyle buttonSmall =
      TextStyle(fontSize: 14, color: AppColors.muted);
}

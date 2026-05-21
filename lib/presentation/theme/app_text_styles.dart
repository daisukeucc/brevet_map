import 'package:flutter/material.dart';

/// アプリ全体で使用するカラー定数
abstract class AppColors {
  static const Color muted = Color(0xA6000A18);

  static const Color mutedLarge = Color(0x99000A18);

  /// [muted] より一段薄い補助テキスト（読み取り専用行など）
  static const Color mutedLight = Colors.black38;

  /// 軸線より上のチャート領域（経過バー）の背景
  static final Color chartPlotBackground = Colors.blueGrey.shade700;

  /// 軸線から下（目盛り・時間ラベル）の帯の背景
  static const Color chartLabelStripBackground = Colors.blueGrey;

  /// チャート軸線
  static const Color chartAxis = Colors.white;

  /// 上段チェックイン経過バー
  static const Color chartCheckInBar = Colors.cyan;

  /// 下段スケジュール経過バー
  static const Color chartScheduleBar = Colors.cyanAccent;

  /// POI 日付バッジの枠線・テキスト色
  static const Color poiDateBadge = muted;

  /// チェックイン済み表示色（到着実績時刻・休憩実績時刻・日付バッジ）
  static const Color checkInResult = Color(0xFFB71C1C);
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

  /// POI フォームのタイトル・本文入力文字
  static const TextStyle poiFormTitleBody = TextStyle(
    fontSize: 16,
    height: 1.6,
    color: Colors.black87,
  );

  static const TextStyle poiLarge = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: AppColors.mutedLarge,
  );

  static const TextStyle poiMedium = TextStyle(
    fontSize: 18,
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

  /// チェックボックスラベル
  static const TextStyle checkBoxLabel =
      TextStyle(fontSize: 15, color: Colors.black87);

  /// チャート目盛りラベル
  static const TextStyle chartTick = TextStyle(
    fontSize: 10,
    color: Colors.white,
    height: 1.1,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_settings_providers.dart';
import '../widgets/radio_selection_dialog.dart';

/// 言語コードから Locale を生成する。zh_Hant はスクリプトコードが必要なため特別処理。
Locale codeToLocale(String code) {
  if (code == 'zh_Hant') {
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  }
  return Locale(code);
}

/// 保存済みの言語コードから現在の選択値を返す（ダイアログの initialValue 用）
String localeToCode(Locale? locale) {
  if (locale == null) return '';
  if (locale.scriptCode == 'Hant') return 'zh_Hant';
  return locale.languageCode;
}

/// 言語選択ダイアログを表示し、選択された言語をアプリに反映・保存する
void showLanguageSelectionFlow(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final currentCode = localeToCode(ref.read(localeProvider));

  showRadioSelectionDialog<String>(
    context: context,
    title: l10n.language,
    options: [
      ('', l10n.useSystemLanguage),
      ('en', 'English'),
      ('ja', '日本語'),
      ('th', 'ภาษาไทย'),
      ('ko', '한국어'),
      ('zh', '中文（简体）'),
      ('zh_Hant', '繁體中文'),
      ('fr', 'Français'),
      ('de', 'Deutsch'),
      ('es', 'Español'),
      ('it', 'Italiano'),
    ],
    initialValue: currentCode,
    onChanged: (code) {
      // ラジオ選択状態を表示してからダイアログが閉じた後にロケールを変更する
      // showRadioSelectionDialog が 400ms 後にダイアログを閉じるため、
      // それより後（500ms）にロケールを変更して再ビルドによる早期閉鎖を防ぐ
      Future.delayed(const Duration(milliseconds: 300), () {
        final locale = code.isEmpty ? null : codeToLocale(code);
        ref.read(localeProvider.notifier).state = locale;
        saveLocale(code);
      });
    },
  );
}

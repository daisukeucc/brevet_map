import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/first_launch_repository.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_settings_providers.dart';
import '../widgets/radio_selection_dialog.dart';

/// 言語選択ダイアログを表示し、選択された言語をアプリに反映・保存する
void showLanguageSelectionFlow(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final currentCode = ref.read(localeProvider)?.languageCode ?? '';

  showRadioSelectionDialog<String>(
    context: context,
    title: l10n.language,
    options: [
      ('', l10n.useSystemLanguage),
      ('en', 'English'),
      ('ja', '日本語'),
      ('ko', '한국어'),
      ('zh', '中文'),
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
        final locale = code.isEmpty ? null : Locale(code);
        ref.read(localeProvider.notifier).state = locale;
        saveLocale(code);
      });
    },
  );
}

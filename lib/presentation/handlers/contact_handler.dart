import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../utils/snackbar_utils.dart';

/// メーラーを開いてお問い合わせ先メールアドレスを渡す
Future<void> openContactEmail(BuildContext context) async {
  final uri = Uri(scheme: 'mailto', path: kContactEmail);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  } else {
    if (context.mounted) {
      showAppSnackBar(
        context,
        AppLocalizations.of(context)!.contactFormMailError,
      );
    }
  }
}

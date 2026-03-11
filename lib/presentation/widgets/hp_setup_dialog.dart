import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_text_styles.dart';
import 'hp_gauge.dart';

/// HP設定ダイアログ。OKで0〜100の値を返す。キャンセルでnull。
Future<int?> showHpSetupDialog(BuildContext context) async {
  return showDialog<int>(
    context: context,
    builder: (ctx) => const _HpSetupDialog(),
  );
}

class _HpSetupDialog extends StatefulWidget {
  const _HpSetupDialog();

  @override
  State<_HpSetupDialog> createState() => _HpSetupDialogState();
}

class _HpSetupDialogState extends State<_HpSetupDialog> {
  int _hp = 100;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compactButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      titlePadding: const EdgeInsets.fromLTRB(24, 26, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      title: null,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HpGauge(
              value: _hp / 100,
              width: 195,
              height: 14,
              labelFontSize: 16,
            ),
            const SizedBox(height: 1),
            const _GaugeScale(gaugeWidth: 210, labelGap: 6, labelFontSize: 16),
            const SizedBox(height: 2),
            Slider(
              value: _hp.toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              onChanged: (v) => setState(() => _hp = v.round()),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      actions: [
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel, style: AppTextStyles.button),
        ),
        TextButton(
          style: compactButtonStyle,
          onPressed: () => Navigator.of(context).pop(_hp),
          child: Text(l10n.ok, style: AppTextStyles.button),
        ),
      ],
    );
  }
}

class _GaugeScale extends StatelessWidget {
  const _GaugeScale({
    required this.gaugeWidth,
    required this.labelGap,
    required this.labelFontSize,
  });

  final double gaugeWidth;
  final double labelGap;
  final double labelFontSize;

  @override
  Widget build(BuildContext context) {
    final labelW = labelFontSize * 1.5;
    final leftOffset = labelW + labelGap;
    return Row(
      children: [
        SizedBox(width: leftOffset),
        SizedBox(
          width: gaugeWidth,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0%',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),
              Text(
                '|',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  color: Colors.black54,
                ),
              ),
              Text(
                '50%',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),
              Text(
                '|',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  color: Colors.black54,
                ),
              ),
              Text(
                '100%',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

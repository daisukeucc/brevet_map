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

class _HpSetupDialogState extends State<_HpSetupDialog>
    with SingleTickerProviderStateMixin {
  int _hp = 100;
  bool _hasInteracted = false;

  late final AnimationController _gaugeAnimationController;
  late final Animation<double> _gaugeAnimation;

  @override
  void initState() {
    super.initState();
    _gaugeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _gaugeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _gaugeAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _gaugeAnimationController.forward();
  }

  @override
  void dispose() {
    _gaugeAnimationController.dispose();
    super.dispose();
  }

  double get _displayedGaugeValue {
    if (_hasInteracted || !_gaugeAnimationController.isAnimating) {
      return _hp / 100;
    }
    return _gaugeAnimation.value * (_hp / 100);
  }

  double get _displayedSliderValue {
    if (_hasInteracted || !_gaugeAnimationController.isAnimating) {
      return _hp.toDouble();
    }
    return _gaugeAnimation.value * _hp;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final compactButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    return AlertDialog(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.fromLTRB(3, 25, 0, 0),
      title: null,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: SizedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedBuilder(
                      animation: _gaugeAnimation,
                      builder: (context, _) => HpGauge(
                        value: _displayedGaugeValue,
                        width: 222,
                        height: 14,
                        labelFontSize: 20,
                        labelOnTop: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const _GaugeScale(gaugeWidth: 225),
                  ],
                ),
              ),
            ),
            SizedBox(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
                child: AnimatedBuilder(
                  animation: _gaugeAnimation,
                  builder: (context, _) => Slider(
                    value: _displayedSliderValue,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    onChanged: (v) => setState(() {
                      _hasInteracted = true;
                      _hp = v.round();
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
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
  const _GaugeScale({required this.gaugeWidth});

  final double gaugeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
    );
  }
}

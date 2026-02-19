import 'package:flutter/material.dart';

/// 画面下部の再生/停止バーと位置取得中のプログレスバー
class LocationBottomBar extends StatelessWidget {
  const LocationBottomBar({
    super.key,
    required this.isStreamActive,
    required this.onTap,
    this.progressBarValue,
  });

  final bool isStreamActive;
  final VoidCallback onTap;
  final ValueNotifier<double>? progressBarValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: isStreamActive ? Colors.red : Colors.green,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              height: 80,
              child: Center(
                child: Icon(
                  isStreamActive ? Icons.stop : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        if (isStreamActive && progressBarValue != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 3,
            child: Container(
              width: double.infinity,
              color: Colors.red.shade900,
              child: ClipRect(
                child: ValueListenableBuilder<double>(
                  valueListenable: progressBarValue!,
                  builder: (context, value, child) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        const barWidth = 80.0;
                        final left = (value *
                                (constraints.maxWidth + barWidth)) -
                            barWidth;
                        return Stack(
                          children: [
                            Positioned(
                              left: left,
                              top: 0,
                              child: Container(
                                width: barWidth,
                                height: 3,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

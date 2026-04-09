import 'package:flutter/material.dart';

/// Google Maps 風の青い丸＋波紋アニメーションの現在地マーカー
class PulsingLocationMarker extends StatefulWidget {
  const PulsingLocationMarker({
    super.key,
    this.size = 72,
    this.centerDotRadius = 8,
    this.waveColor,
    this.centerColor,
    this.isDarkMode = false,
  });

  final double size;
  final double centerDotRadius;
  final Color? waveColor;
  final Color? centerColor;

  /// ダークモード時は波動を白にする
  final bool isDarkMode;

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waveColor = widget.waveColor ??
        (widget.isDarkMode
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.blue.withValues(alpha: 0.5));
    final centerColor = widget.centerColor ?? Colors.blue;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _PulsePainter(
              progress: _controller.value,
              centerDotRadius: widget.centerDotRadius,
              waveColor: waveColor,
              centerColor: centerColor,
              maxWaveRadius: widget.size * 0.42,
            ),
          );
        },
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter({
    required this.progress,
    required this.centerDotRadius,
    required this.waveColor,
    required this.centerColor,
    required this.maxWaveRadius,
  });

  final double progress;
  final double centerDotRadius;
  final Color waveColor;
  final Color centerColor;
  final double maxWaveRadius;

  /// 波の数（連続的に広がる波紋）
  static const int _waveCount = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // 波紋を描画（Google Maps 風：広がりながらフェードアウト）
    for (var i = 0; i < _waveCount; i++) {
      final phase = (progress + i / _waveCount) % 1.0;
      final waveProgress = Curves.easeOut.transform(phase);
      final radius = centerDotRadius + waveProgress * (maxWaveRadius - centerDotRadius);
      final opacity = (1 - waveProgress) * 0.35;

      // 塗りつぶし（薄い青の円が広がる）
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = waveColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
      // 縁取り
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = waveColor.withValues(alpha: opacity * 1.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // 外側の白い縁取り（ドットの視認性向上）
    canvas.drawCircle(
      center,
      centerDotRadius + 2,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 中央の青い丸
    canvas.drawCircle(
      center,
      centerDotRadius,
      Paint()
        ..color = centerColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

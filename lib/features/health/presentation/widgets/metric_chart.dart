import 'package:flutter/material.dart';

import '../../../../app/theme.dart';

/// Biểu đồ đường đơn giản (không cần thư viện ngoài) cho chuỗi chỉ số.
class MetricChart extends StatelessWidget {
  const MetricChart({super.key, required this.primary, this.secondary});

  final List<double> primary;
  final List<double>? secondary;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ChartPainter(primary: primary, secondary: secondary),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.primary, this.secondary});

  final List<double> primary;
  final List<double>? secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...primary, ...?secondary];
    if (all.length < 2) {
      return;
    }
    var minValue = all.reduce((a, b) => a < b ? a : b);
    var maxValue = all.reduce((a, b) => a > b ? a : b);
    if (maxValue - minValue < 1) {
      maxValue += 1;
      minValue -= 1;
    }
    const padding = 8.0;
    final width = size.width - padding * 2;
    final height = size.height - padding * 2;

    final gridPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = padding + height * i / 2;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    void drawLine(List<double> values, Color color) {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final dotPaint = Paint()..color = color;
      final path = Path();
      for (var i = 0; i < values.length; i++) {
        final x = padding + width * i / (values.length - 1);
        final y =
            padding +
            height * (1 - (values[i] - minValue) / (maxValue - minValue));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(Offset(x, y), 3, dotPaint);
      }
      canvas.drawPath(path, linePaint);
    }

    drawLine(primary, AppTheme.primaryBlue);
    final second = secondary;
    if (second != null && second.length == primary.length) {
      drawLine(second, AppTheme.warning);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}

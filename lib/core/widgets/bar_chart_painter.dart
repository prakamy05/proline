import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SimpleBarChartPainter extends CustomPainter {
  final List<double> dataPoints;
  final List<String> labels;
  final Color barColor;

  SimpleBarChartPainter({
    required this.dataPoints,
    required this.labels,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final double spacing = size.width / (dataPoints.length * 2 + 1);
    final double barWidth = spacing;

    for (int i = 0; i < dataPoints.length; i++) {
      final double left = spacing + i * (barWidth + spacing * 2);
      final double barHeight = size.height * dataPoints[i] * 0.82;
      final double top = size.height - barHeight - 20;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(left + (barWidth - textPainter.width) / 2, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant SimpleBarChartPainter oldDelegate) => false;
}
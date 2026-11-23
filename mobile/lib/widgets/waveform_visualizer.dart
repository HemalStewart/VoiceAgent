import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final double amplitude;
  final bool isRecording;

  const WaveformVisualizer({
    super.key,
    required this.amplitude,
    required this.isRecording,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  final List<double> _samples = List.filled(28, 0.05);
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    )..addListener(() {
        if (widget.isRecording) {
          setState(() {
            _samples.removeAt(0);
            // Add subtle random jitter based on current amplitude for realistic audio visualizer
            final jitter = (math.Random().nextDouble() - 0.5) * 0.2;
            final val = (widget.amplitude + jitter).clamp(0.08, 1.0);
            _samples.add(val);
          });
        }
      });
    _animController.repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0E12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: CustomPaint(
        painter: _WaveformPainter(_samples, widget.isRecording),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final bool isRecording;

  _WaveformPainter(this.samples, this.isRecording);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = isRecording ? AppColors.secondary : AppColors.primary
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    final double barSpacing = size.width / samples.length;
    final double midY = size.height / 2;

    for (int i = 0; i < samples.length; i++) {
      final double x = i * barSpacing + (barSpacing / 2);
      final double sampleHeight = (samples[i] * size.height * 0.85).clamp(4.0, size.height);
      final double topY = midY - (sampleHeight / 2);
      final double bottomY = midY + (sampleHeight / 2);

      canvas.drawLine(Offset(x, topY), Offset(x, bottomY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

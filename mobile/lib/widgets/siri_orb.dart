import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SiriOrb extends StatefulWidget {
  final bool isThinking;
  final bool isPlaying;
  final bool isRecording;
  final double amplitude;
  final double size;

  const SiriOrb({
    super.key,
    required this.isThinking,
    required this.isPlaying,
    required this.isRecording,
    this.amplitude = 0.0,
    this.size = 140.0,
  });

  @override
  State<SiriOrb> createState() => _SiriOrbState();
}

class _SiriOrbState extends State<SiriOrb> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double ampScale = widget.isRecording ? (1.0 + widget.amplitude * 0.4) : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _pulseController]),
      builder: (context, child) {
        final double pulse = widget.isThinking
            ? _pulseAnimation.value
            : (widget.isPlaying ? (0.95 + (_pulseController.value * 0.15)) : 1.0);

        final double currentScale = pulse * ampScale;

        return SizedBox(
          width: widget.size * currentScale,
          height: widget.size * currentScale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing Aura 1 (Indigo)
              Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: widget.isThinking ? 0.6 : 0.4),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Outer Glowing Aura 2 (Rose Pink)
              Transform.rotate(
                angle: -_rotationController.value * 2 * math.pi * 0.7,
                child: Container(
                  width: widget.size * 0.85,
                  height: widget.size * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.secondary.withValues(alpha: widget.isThinking ? 0.5 : 0.3),
                        AppColors.secondary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),

              // Inner Morphing Circle (Emerald/Accent)
              if (widget.isThinking || widget.isPlaying)
                Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi * 1.3,
                  child: Container(
                    width: widget.size * 0.7,
                    height: widget.size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.45),
                          AppColors.accent.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

              // Glass Orb Body
              Container(
                width: widget.size * 0.55,
                height: widget.size * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1B2035),
                  border: Border.all(
                    color: widget.isThinking
                        ? AppColors.primary
                        : (widget.isPlaying
                            ? AppColors.accent
                            : (widget.isRecording
                                ? AppColors.secondary
                                : AppColors.primary.withValues(alpha: 0.5))),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isThinking
                              ? AppColors.primary
                              : (widget.isPlaying
                                  ? AppColors.accent
                                  : AppColors.secondary))
                          .withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isThinking
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white,
                                blurRadius: 12,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        )
                      : Icon(
                          widget.isPlaying
                              ? Icons.volume_up_rounded
                              : (widget.isRecording
                                  ? Icons.mic_rounded
                                  : Icons.headset_mic_rounded),
                          color: Colors.white,
                          size: widget.size * 0.26,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

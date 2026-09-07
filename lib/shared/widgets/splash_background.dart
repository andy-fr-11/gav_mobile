import 'package:flutter/material.dart';

class SplashBackground extends StatelessWidget {
  const SplashBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF002866),
                  Color(0xFF0047AB),
                  Color(0xFF4A90E2),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -90,
          left: -80,
          child: _GlowCircle(
            color: const Color(0xFF6DA9FF),
            diameter: 260,
            opacity: 0.18,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -40,
          child: _GlowCircle(
            color: const Color(0xFFB71C1C),
            diameter: 220,
            opacity: 0.16,
          ),
        ),
        Positioned(
          top: 90,
          right: 0,
          child: _FloatingBlob(
            color: const Color(0xFFFFFFFF),
            diameter: 100,
            opacity: 0.16,
          ),
        ),
        Positioned(
          bottom: 140,
          left: 20,
          child: _FloatingBlob(
            color: const Color(0xFF1565C0),
            diameter: 120,
            opacity: 0.14,
          ),
        ),
        Positioned(
          bottom: 36,
          right: 50,
          child: _FloatingBlob(
            color: const Color(0xFFB71C1C),
            diameter: 90,
            opacity: 0.18,
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.color,
    required this.diameter,
    required this.opacity,
  });

  final Color color;
  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: 80,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _FloatingBlob extends StatelessWidget {
  const _FloatingBlob({
    required this.color,
    required this.diameter,
    required this.opacity,
  });

  final Color color;
  final double diameter;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
    );
  }
}

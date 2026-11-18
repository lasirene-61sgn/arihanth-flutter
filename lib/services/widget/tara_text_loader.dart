import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TaraTextLoader extends StatefulWidget {
  final double fontSize;
  const TaraTextLoader({Key? key, this.fontSize = 42.0}) : super(key: key);

  @override
  State<TaraTextLoader> createState() => _TaraTextLoaderState();
}

class _TaraTextLoaderState extends State<TaraTextLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            // Metallic Gold Linear Gradient with moving shimmer sweep
            return ui.Gradient.linear(
              Offset(bounds.width * (_controller.value * 2 - 0.5), 0),
              Offset(bounds.width * (_controller.value * 2 + 0.5), bounds.height),
              [
                const Color(0xFFB8860B), // Deep Gold
                const Color(0xFFFFD700), // Bright Gold
                const Color(0xFFFFF8DC), // High-light Gold/White
                const Color(0xFFFFD700), // Bright Gold
                const Color(0xFFB8860B), // Deep Gold
              ],
              [0.0, 0.35, 0.5, 0.65, 1.0],
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'TARA',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4.0,
                  fontFamily: 'Serif', // Match elegant serif typography
                ),
              ),
              const SizedBox(width: 4),
              // Sparkling star accent matching logo star flare
              Transform.scale(
                scale: 0.8 + (0.3 * (1 - (_controller.value - 0.5).abs() * 2)),
                child: Icon(
                  Icons.star,
                  size: widget.fontSize * 0.45,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}


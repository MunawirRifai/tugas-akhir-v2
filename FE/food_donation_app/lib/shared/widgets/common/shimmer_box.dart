import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry margin;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.xl,
    this.margin = EdgeInsets.zero,
    this.baseColor = AppColors.surfaceSoft,
    this.highlightColor = const Color(0x88FFFFFF),
    this.duration = const Duration(milliseconds: 1300),
    this.shape = BoxShape.rectangle,
  });

  const ShimmerBox.compact({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.md,
    this.margin = EdgeInsets.zero,
    this.baseColor = AppColors.surfaceSoft,
    this.highlightColor = const Color(0x88FFFFFF),
    this.duration = const Duration(milliseconds: 1100),
    this.shape = BoxShape.rectangle,
  });

  const ShimmerBox.circle({
    super.key,
    required double size,
    this.margin = EdgeInsets.zero,
    this.baseColor = AppColors.surfaceSoft,
    this.highlightColor = const Color(0x88FFFFFF),
    this.duration = const Duration(milliseconds: 1300),
  })  : width = size,
        height = size,
        borderRadius = 999,
        shape = BoxShape.circle;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget base = Container(
      width: widget.width ?? double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.baseColor,
        shape: widget.shape,
        borderRadius: widget.shape == BoxShape.circle
            ? null
            : BorderRadius.circular(widget.borderRadius),
      ),
    );

    return Padding(
      padding: widget.margin,
      child: AnimatedBuilder(
        animation: _controller,
        child: base,
        builder: (context, child) {
          final double offset = _controller.value * 2 - 1;

          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment(offset - 1, 0),
                end: Alignment(offset + 1, 0),
                colors: [
                  widget.baseColor.withValues(alpha: 0.70),
                  widget.highlightColor,
                  widget.baseColor.withValues(alpha: 0.70),
                ],
                stops: const [0.25, 0.50, 0.75],
              ).createShader(rect);
            },
            child: child,
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow> boxShadow;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.xl,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.card,
    this.width,
    this.height,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  const AppSurfaceCard.compact({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x1),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.card,
    this.width,
    this.height,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  const AppSurfaceCard.soft({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.xl,
    this.backgroundColor = AppColors.surfaceSoft,
    this.borderColor = AppColors.border,
    this.boxShadow = const <BoxShadow>[],
    this.width,
    this.height,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final BorderRadius resolvedBorderRadius = BorderRadius.circular(
      borderRadius,
    );

    final Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedBorderRadius,
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: boxShadow,
      ),
      clipBehavior: clipBehavior,
      child: child,
    );

    if (onTap == null) {
      return Padding(
        padding: margin,
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        borderRadius: resolvedBorderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: resolvedBorderRadius,
          child: content,
        ),
      ),
    );
  }
}
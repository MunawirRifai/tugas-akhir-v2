import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppBottomSheetHandle extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final EdgeInsetsGeometry margin;
  final BorderRadiusGeometry borderRadius;

  const AppBottomSheetHandle({
    super.key,
    this.width = 48,
    this.height = 5,
    this.color = AppColors.border,
    this.margin = const EdgeInsets.only(
      top: AppSpacing.x2,
      bottom: AppSpacing.x3,
    ),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(999),
    ),
  });

  const AppBottomSheetHandle.compact({
    super.key,
    this.width = 42,
    this.height = 4,
    this.color = AppColors.border,
    this.margin = const EdgeInsets.only(
      top: AppSpacing.x1,
      bottom: AppSpacing.x2,
    ),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(999),
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}
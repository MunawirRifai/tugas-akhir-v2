import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'app_surface_card.dart';

class AppInfoPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color? backgroundColor;
  final Widget? trailing;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool showBorder;
  final bool showShadow;
  final int titleMaxLines;
  final int descriptionMaxLines;
  final CrossAxisAlignment crossAxisAlignment;

  const AppInfoPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.color = AppColors.primaryDark,
    this.backgroundColor,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
    this.showShadow = false,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  const AppInfoPanel.info({
    super.key,
    this.icon = Icons.info_outline_rounded,
    required this.title,
    required this.description,
    this.color = AppColors.primaryDark,
    this.backgroundColor = AppColors.primarySoft,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
    this.showShadow = false,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  const AppInfoPanel.success({
    super.key,
    this.icon = Icons.check_circle_outline_rounded,
    required this.title,
    required this.description,
    this.color = AppColors.primary,
    this.backgroundColor = AppColors.primarySoft,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
    this.showShadow = false,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  const AppInfoPanel.warning({
    super.key,
    this.icon = Icons.warning_amber_rounded,
    required this.title,
    required this.description,
    this.color = AppColors.accent,
    this.backgroundColor = AppColors.accentSoft,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
    this.showShadow = false,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  const AppInfoPanel.error({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    required this.description,
    this.color = AppColors.danger,
    this.backgroundColor = AppColors.dangerSoft,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.showBorder = true,
    this.showShadow = false,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  const AppInfoPanel.surface({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.color = AppColors.primaryDark,
    this.backgroundColor = AppColors.surface,
    this.trailing,
    this.action,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.xl,
    this.showBorder = true,
    this.showShadow = true,
    this.titleMaxLines = 2,
    this.descriptionMaxLines = 4,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackgroundColor =
        backgroundColor ?? color.withValues(alpha: 0.09);

    final Color resolvedBorderColor = showBorder
        ? color.withValues(alpha: 0.18)
        : Colors.transparent;

    return AppSurfaceCard(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: resolvedBackgroundColor,
      borderColor: resolvedBorderColor,
      boxShadow: showShadow ? AppShadows.card : const <BoxShadow>[],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: crossAxisAlignment,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.x1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: descriptionMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.x1),
                trailing!,
              ],
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.x2),
            action!,
          ],
        ],
      ),
    );
  }
}

class AppInlineInfoPanel extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final int maxLines;
  final Widget? trailing;

  const AppInlineInfoPanel({
    super.key,
    required this.icon,
    required this.message,
    this.color = AppColors.primaryDark,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.maxLines = 3,
    this.trailing,
  });

  const AppInlineInfoPanel.info({
    super.key,
    this.icon = Icons.info_outline_rounded,
    required this.message,
    this.color = AppColors.primaryDark,
    this.backgroundColor = AppColors.primarySoft,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.maxLines = 3,
    this.trailing,
  });

  const AppInlineInfoPanel.warning({
    super.key,
    this.icon = Icons.warning_amber_rounded,
    required this.message,
    this.color = AppColors.accent,
    this.backgroundColor = AppColors.accentSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.maxLines = 3,
    this.trailing,
  });

  const AppInlineInfoPanel.error({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.message,
    this.color = AppColors.danger,
    this.backgroundColor = AppColors.dangerSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.maxLines = 3,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackgroundColor =
        backgroundColor ?? color.withValues(alpha: 0.09);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: resolvedBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Text(
              message,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.x1),
            trailing!,
          ],
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'app_surface_card.dart';

class AppSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final List<BoxShadow> boxShadow;
  final CrossAxisAlignment crossAxisAlignment;

  const AppSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDark,
    this.iconBackgroundColor = AppColors.primarySoft,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.x3),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.xl,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.card,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  const AppSectionCard.compact({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDark,
    this.iconBackgroundColor = AppColors.primarySoft,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.lg,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.boxShadow = AppShadows.card,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  const AppSectionCard.soft({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDark,
    this.iconBackgroundColor = AppColors.primarySoft,
    this.trailing,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
    this.margin = EdgeInsets.zero,
    this.borderRadius = AppRadius.xl,
    this.backgroundColor = AppColors.background,
    this.borderColor = AppColors.border,
    this.boxShadow = const <BoxShadow>[],
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      boxShadow: boxShadow,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          _SectionHeader(
            title: title,
            subtitle: subtitle,
            icon: icon,
            iconColor: iconColor,
            iconBackgroundColor: iconBackgroundColor,
            trailing: trailing,
          ),
          const SizedBox(height: AppSpacing.x2),
          child,
        ],
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final CrossAxisAlignment crossAxisAlignment;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDark,
    this.iconBackgroundColor = AppColors.primarySoft,
    this.trailing,
    this.padding = EdgeInsets.zero,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: _SectionHeader(
        title: title,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        iconBackgroundColor: iconBackgroundColor,
        trailing: trailing,
        crossAxisAlignment: crossAxisAlignment,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final Widget? trailing;
  final CrossAxisAlignment crossAxisAlignment;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasIcon = icon != null;
    final bool hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        if (hasIcon) ...[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.x2),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (hasSubtitle) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.x1),
          trailing!,
        ],
      ],
    );
  }
}
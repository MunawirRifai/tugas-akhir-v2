import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'app_surface_card.dart';

class AppMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData icon;
  final Color color;
  final bool isCompact;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int valueMaxLines;
  final int labelMaxLines;
  final double? width;
  final EdgeInsetsGeometry padding;

  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subValue,
    this.isCompact = false,
    this.isDark = false,
    this.onTap,
    this.trailing,
    this.valueMaxLines = 1,
    this.labelMaxLines = 1,
    this.width,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
  });

  const AppMetricTile.compact({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subValue,
    this.isCompact = true,
    this.isDark = false,
    this.onTap,
    this.trailing,
    this.valueMaxLines = 1,
    this.labelMaxLines = 1,
    this.width,
    this.padding = const EdgeInsets.all(AppSpacing.x1),
  });

  const AppMetricTile.dark({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = Colors.white,
    this.subValue,
    this.isCompact = false,
    this.isDark = true,
    this.onTap,
    this.trailing,
    this.valueMaxLines = 1,
    this.labelMaxLines = 1,
    this.width,
    this.padding = const EdgeInsets.all(AppSpacing.x2),
  });

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isDark ? Colors.white : color;

    final Color labelColor = isDark
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    final Color backgroundColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : color.withValues(alpha: 0.10);

    final Color iconBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : color.withValues(alpha: 0.16);

    final double iconContainerSize = isCompact ? 38 : 46;
    final double iconSize = isCompact ? 20 : 24;

    return AppSurfaceCard(
      width: width,
      onTap: onTap,
      padding: padding,
      borderRadius: isCompact ? AppRadius.lg : AppRadius.xl,
      backgroundColor:
          isDark ? Colors.white.withValues(alpha: 0.10) : AppColors.surface,
      borderColor:
          isDark ? Colors.white.withValues(alpha: 0.14) : AppColors.border,
      boxShadow: isDark ? const <BoxShadow>[] : AppShadows.card,
      child: Row(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(
                isCompact ? AppRadius.md : AppRadius.lg,
              ),
              border: Border.all(
                color: iconBorderColor,
              ),
            ),
            child: Icon(
              icon,
              color: foregroundColor,
              size: iconSize,
            ),
          ),
          const SizedBox(width: AppSpacing.x1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: valueMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: (isCompact
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.titleLarge)
                      ?.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subValue == null ? label : '$label • $subValue',
                  maxLines: labelMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
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
    );
  }
}

class AppMetricGrid extends StatelessWidget {
  final List<Widget> children;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;
  final ScrollPhysics physics;
  final bool shrinkWrap;

  const AppMetricGrid({
    super.key,
    required this.children,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = AppSpacing.x1,
    this.crossAxisSpacing = AppSpacing.x1,
    this.childAspectRatio = 1.75,
    this.padding = EdgeInsets.zero,
    this.physics = const NeverScrollableScrollPhysics(),
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      children: children,
    );
  }
}
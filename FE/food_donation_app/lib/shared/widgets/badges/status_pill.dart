import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool isLarge;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;
  final int maxLines;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.isLarge = false,
    this.showBorder = false,
    this.padding,
    this.maxLines = 1,
  });

  factory StatusPill.fromFoodStatus(
    Object? status, {
    Key? key,
    bool isLarge = false,
    bool showBorder = false,
  }) {
    final _StatusPillStyle style = _StatusPillStyle.fromFoodStatus(status);

    return StatusPill(
      key: key,
      label: style.label,
      color: style.color,
      icon: style.icon,
      isLarge: isLarge,
      showBorder: showBorder,
    );
  }

  factory StatusPill.available({
    Key? key,
    bool isLarge = false,
    bool showBorder = false,
  }) {
    return StatusPill(
      key: key,
      label: 'Tersedia',
      color: AppColors.primary,
      icon: Icons.inventory_2_outlined,
      isLarge: isLarge,
      showBorder: showBorder,
    );
  }

  factory StatusPill.onTheWay({
    Key? key,
    bool isLarge = false,
    bool showBorder = false,
  }) {
    return StatusPill(
      key: key,
      label: 'Sedang Diambil',
      color: AppColors.teal,
      icon: Icons.directions_walk_rounded,
      isLarge: isLarge,
      showBorder: showBorder,
    );
  }

  factory StatusPill.completed({
    Key? key,
    bool isLarge = false,
    bool showBorder = false,
  }) {
    return StatusPill(
      key: key,
      label: 'Selesai',
      color: AppColors.textMuted,
      icon: Icons.check_circle_rounded,
      isLarge: isLarge,
      showBorder: showBorder,
    );
  }

  factory StatusPill.canceled({
    Key? key,
    bool isLarge = false,
    bool showBorder = false,
  }) {
    return StatusPill(
      key: key,
      label: 'Dibatalkan',
      color: AppColors.danger,
      icon: Icons.cancel_rounded,
      isLarge: isLarge,
      showBorder: showBorder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry resolvedPadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: isLarge ? AppSpacing.x2 : AppSpacing.x1,
          vertical: isLarge ? 7 : 5,
        );

    final TextStyle? textStyle =
        (isLarge
                ? Theme.of(context).textTheme.labelLarge
                : Theme.of(context).textTheme.labelSmall)
            ?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            );

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: showBorder
            ? Border.all(
                color: color.withValues(alpha: 0.22),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: color,
              size: isLarge ? 16 : 13,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPillStyle {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPillStyle({
    required this.label,
    required this.color,
    required this.icon,
  });

  factory _StatusPillStyle.fromFoodStatus(Object? status) {
    final String normalizedStatus = status?.toString().trim().toUpperCase() ?? '';

    switch (normalizedStatus) {
      case 'AVAILABLE':
      case 'POSTED':
        return const _StatusPillStyle(
          label: 'Tersedia',
          color: AppColors.primary,
          icon: Icons.inventory_2_outlined,
        );

      case 'ON_THE_WAY':
      case 'ON WAY':
      case 'PICKING_UP':
      case 'PICKING UP':
        return const _StatusPillStyle(
          label: 'Sedang Diambil',
          color: AppColors.teal,
          icon: Icons.directions_walk_rounded,
        );

      case 'PICKED_UP':
      case 'PICKED UP':
      case 'COMPLETED':
      case 'CLAIMED':
      case 'DONE':
        return const _StatusPillStyle(
          label: 'Selesai',
          color: AppColors.textMuted,
          icon: Icons.check_circle_rounded,
        );

      case 'CANCELED':
      case 'CANCELLED':
      case 'REJECTED':
        return const _StatusPillStyle(
          label: 'Dibatalkan',
          color: AppColors.danger,
          icon: Icons.cancel_rounded,
        );

      default:
        if (normalizedStatus.isEmpty || normalizedStatus == 'NULL') {
          return const _StatusPillStyle(
            label: 'Tersedia',
            color: AppColors.primary,
            icon: Icons.inventory_2_outlined,
          );
        }

        return _StatusPillStyle(
          label: _titleCaseStatus(normalizedStatus),
          color: AppColors.textSecondary,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  static String _titleCaseStatus(String status) {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .map((word) {
          final String lower = word.toLowerCase();

          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}
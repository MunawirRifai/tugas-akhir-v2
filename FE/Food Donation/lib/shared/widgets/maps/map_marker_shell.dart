import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum MapMarkerShellSize {
  small,
  medium,
  large,
}

class MapMarkerShell extends StatelessWidget {
  final IconData icon;
  final Color color;
  final MapMarkerShellSize size;
  final bool isSelected;
  final bool isOwnedByCurrentUser;
  final bool showPulse;
  final bool showBorder;
  final VoidCallback? onTap;
  final String? tooltip;
  final Widget? badge;
  final List<BoxShadow>? boxShadow;

  const MapMarkerShell({
    super.key,
    required this.icon,
    required this.color,
    this.size = MapMarkerShellSize.medium,
    this.isSelected = false,
    this.isOwnedByCurrentUser = false,
    this.showPulse = true,
    this.showBorder = true,
    this.onTap,
    this.tooltip,
    this.badge,
    this.boxShadow,
  });

  factory MapMarkerShell.foodCategory({
    Key? key,
    required String category,
    required Color color,
    MapMarkerShellSize size = MapMarkerShellSize.medium,
    bool isSelected = false,
    bool isOwnedByCurrentUser = false,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
  }) {
    return MapMarkerShell(
      key: key,
      icon: MapMarkerStyle.iconFromCategory(category),
      color: color,
      size: size,
      isSelected: isSelected,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
      onTap: onTap,
      tooltip: tooltip,
      badge: badge,
    );
  }

  factory MapMarkerShell.foodCondition({
    Key? key,
    required IconData icon,
    required String condition,
    MapMarkerShellSize size = MapMarkerShellSize.medium,
    bool isSelected = false,
    bool isOwnedByCurrentUser = false,
    VoidCallback? onTap,
    String? tooltip,
    Widget? badge,
  }) {
    return MapMarkerShell(
      key: key,
      icon: icon,
      color: MapMarkerStyle.colorFromCondition(condition),
      size: size,
      isSelected: isSelected,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
      onTap: onTap,
      tooltip: tooltip,
      badge: badge,
    );
  }

  double get _outerSize {
    switch (size) {
      case MapMarkerShellSize.small:
        return isSelected ? 54 : 48;
      case MapMarkerShellSize.medium:
        return isSelected ? 68 : 60;
      case MapMarkerShellSize.large:
        return isSelected ? 82 : 72;
    }
  }

  double get _innerSize {
    switch (size) {
      case MapMarkerShellSize.small:
        return isSelected ? 42 : 38;
      case MapMarkerShellSize.medium:
        return isSelected ? 56 : 50;
      case MapMarkerShellSize.large:
        return isSelected ? 68 : 60;
    }
  }

  double get _iconSize {
    switch (size) {
      case MapMarkerShellSize.small:
        return 22;
      case MapMarkerShellSize.medium:
        return 28;
      case MapMarkerShellSize.large:
        return 34;
    }
  }

  double get _radius {
    switch (size) {
      case MapMarkerShellSize.small:
        return AppRadius.md;
      case MapMarkerShellSize.medium:
        return AppRadius.lg;
      case MapMarkerShellSize.large:
        return AppRadius.xl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget marker = SizedBox(
      width: _outerSize,
      height: _outerSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (showPulse)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: _outerSize,
              height: _outerSize,
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: isSelected ? 0.20 : 0.13,
                ),
                shape: BoxShape.circle,
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: _innerSize,
            height: _innerSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(_radius),
              border: showBorder
                  ? Border.all(
                      color: isOwnedByCurrentUser
                          ? AppColors.teal
                          : Colors.white,
                      width: isOwnedByCurrentUser ? 4 : 3,
                    )
                  : null,
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: color.withValues(alpha: 0.30),
                      blurRadius: isSelected ? 26 : 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: _iconSize,
            ),
          ),
          if (badge != null)
            Positioned(
              right: -2,
              top: -2,
              child: badge!,
            ),
        ],
      ),
    );

    final Widget tappableMarker = onTap == null
        ? marker
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: marker,
            ),
          );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return tappableMarker;
    }

    return Tooltip(
      message: tooltip!,
      child: tappableMarker,
    );
  }
}

class MapPinMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool showPulse;
  final VoidCallback? onTap;
  final String? tooltip;

  const MapPinMarker({
    super.key,
    this.icon = Icons.location_on_rounded,
    this.color = AppColors.primary,
    this.isSelected = false,
    this.showPulse = true,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final Widget marker = SizedBox(
      width: isSelected ? 82 : 76,
      height: isSelected ? 82 : 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showPulse)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: isSelected ? 82 : 76,
              height: isSelected ? 82 : 76,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isSelected ? 0.20 : 0.14),
                shape: BoxShape.circle,
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: isSelected ? 58 : 52,
            height: isSelected ? 58 : 52,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.32),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isSelected ? 34 : 30,
            ),
          ),
        ],
      ),
    );

    final Widget tappableMarker = onTap == null
        ? marker
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: marker,
            ),
          );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return tappableMarker;
    }

    return Tooltip(
      message: tooltip!,
      child: tappableMarker,
    );
  }
}

class MapCurrentLocationMarker extends StatelessWidget {
  final Color color;
  final bool showPulse;

  const MapCurrentLocationMarker({
    super.key,
    this.color = AppColors.primary,
    this.showPulse = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showPulse)
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class MapDestinationMarker extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String? label;

  const MapDestinationMarker({
    super.key,
    this.color = AppColors.accent,
    this.icon = Icons.flag_rounded,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapMarkerShell(
          icon: icon,
          color: color,
          size: MapMarkerShellSize.medium,
          showPulse: true,
          tooltip: label,
        ),
        if (label != null && label!.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: AppColors.border,
              ),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x1,
                vertical: 4,
              ),
              child: Text(
                label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MapClusterBubble extends StatelessWidget {
  final int count;
  final Color color;
  final VoidCallback? onTap;
  final String? tooltip;

  const MapClusterBubble({
    super.key,
    required this.count,
    this.color = AppColors.primary,
    this.onTap,
    this.tooltip,
  });

  double get _size {
    if (count >= 100) return 66;
    if (count >= 10) return 58;
    return 52;
  }

  @override
  Widget build(BuildContext context) {
    final Widget bubble = TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.86,
        end: 1,
      ),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.32),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: _size - 14,
              height: _size - 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
            Text(
              '$count',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );

    final Widget tappableBubble = onTap == null
        ? bubble
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: bubble,
            ),
          );

    if (tooltip == null || tooltip!.trim().isEmpty) {
      return tappableBubble;
    }

    return Tooltip(
      message: tooltip!,
      child: tappableBubble,
    );
  }
}

class MapMarkerBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const MapMarkerBadge({
    super.key,
    required this.label,
    this.color = AppColors.accent,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Colors.white,
                size: 11,
              ),
              const SizedBox(width: 2),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapMarkerStyle {
  const MapMarkerStyle._();

  static IconData iconFromCategory(Object? category) {
    final String text = category?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'kompos',
      'compost',
    ])) {
      return Icons.compost_rounded;
    }

    if (_containsAny(text, [
      'minuman',
      'drink',
      'beverage',
      'teh',
      'kopi',
      'susu',
      'jus',
      'juice',
    ])) {
      return Icons.local_drink_rounded;
    }

    if (_containsAny(text, [
      'sembako',
      'grocery',
      'beras',
      'minyak',
      'mie',
      'gula',
      'tepung',
    ])) {
      return Icons.inventory_2_rounded;
    }

    if (_containsAny(text, [
      'kue',
      'snack',
      'roti',
      'cake',
      'cemilan',
      'camilan',
      'biskuit',
    ])) {
      return Icons.bakery_dining_rounded;
    }

    return Icons.restaurant_rounded;
  }

  static Color colorFromCondition(Object? condition) {
    final String text = condition?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'basi',
      'kompos',
      'compost',
      'pakan',
      'pakan ternak',
      'animal feed',
      'merah',
    ])) {
      return AppColors.danger;
    }

    if (_containsAny(text, [
      'segera',
      'cepat habis',
      'hari ini',
      'consume soon',
      'mendekati expired',
      'kuning',
    ])) {
      return AppColors.accent;
    }

    return AppColors.primary;
  }

  static String categoryLabel(Object? category) {
    final String text = category?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'kompos',
      'compost',
    ])) {
      return 'Kompos';
    }

    if (_containsAny(text, [
      'minuman',
      'drink',
      'beverage',
      'teh',
      'kopi',
      'susu',
      'jus',
      'juice',
    ])) {
      return 'Minuman';
    }

    if (_containsAny(text, [
      'sembako',
      'grocery',
      'beras',
      'minyak',
      'mie',
      'gula',
      'tepung',
    ])) {
      return 'Sembako';
    }

    if (_containsAny(text, [
      'kue',
      'snack',
      'roti',
      'cake',
      'cemilan',
      'camilan',
      'biskuit',
    ])) {
      return 'Kue/Snack';
    }

    return 'Makanan Berat';
  }

  static String conditionLabel(Object? condition) {
    final String text = condition?.toString().trim().toLowerCase() ?? '';

    if (_containsAny(text, [
      'basi',
      'kompos',
      'compost',
      'pakan',
      'pakan ternak',
      'animal feed',
      'merah',
    ])) {
      return 'Pakan/Kompos';
    }

    if (_containsAny(text, [
      'segera',
      'cepat habis',
      'hari ini',
      'consume soon',
      'mendekati expired',
      'kuning',
    ])) {
      return 'Segera Dihabiskan';
    }

    return 'Tahan Lama';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }
}
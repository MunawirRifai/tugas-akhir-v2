import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class HalalBadge extends StatelessWidget {
  final bool isHalal;
  final String halalLabel;
  final String nonHalalLabel;
  final bool isLarge;
  final bool showBorder;
  final bool showIcon;
  final EdgeInsetsGeometry? padding;
  final int maxLines;

  const HalalBadge({
    super.key,
    required this.isHalal,
    this.halalLabel = 'Halal',
    this.nonHalalLabel = 'Non-Halal',
    this.isLarge = false,
    this.showBorder = true,
    this.showIcon = true,
    this.padding,
    this.maxLines = 1,
  });

  factory HalalBadge.fromValue(
    Object? value, {
    Key? key,
    bool isLarge = false,
    bool showBorder = true,
    bool showIcon = true,
  }) {
    return HalalBadge(
      key: key,
      isHalal: _parseHalalValue(value),
      isLarge: isLarge,
      showBorder: showBorder,
      showIcon: showIcon,
    );
  }

  factory HalalBadge.halal({
    Key? key,
    bool isLarge = false,
    bool showBorder = true,
    bool showIcon = true,
  }) {
    return HalalBadge(
      key: key,
      isHalal: true,
      isLarge: isLarge,
      showBorder: showBorder,
      showIcon: showIcon,
    );
  }

  factory HalalBadge.nonHalal({
    Key? key,
    bool isLarge = false,
    bool showBorder = true,
    bool showIcon = true,
  }) {
    return HalalBadge(
      key: key,
      isHalal: false,
      isLarge: isLarge,
      showBorder: showBorder,
      showIcon: showIcon,
    );
  }

  Color get _color {
    return isHalal ? AppColors.primary : AppColors.danger;
  }

  IconData get _icon {
    return isHalal ? Icons.verified_rounded : Icons.warning_amber_rounded;
  }

  String get _label {
    return isHalal ? halalLabel : nonHalalLabel;
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
              color: _color,
              fontWeight: FontWeight.w800,
            );

    return Container(
      padding: resolvedPadding,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: showBorder
            ? Border.all(
                color: _color.withValues(alpha: 0.22),
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _icon,
              color: _color,
              size: isLarge ? 16 : 13,
            ),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              _label,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }

  static bool _parseHalalValue(Object? value) {
    if (value == null) {
      return true;
    }

    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text = value.toString().trim().toLowerCase();

    if (text.isEmpty || text == 'null') {
      return true;
    }

    if ([
      'false',
      '0',
      'no',
      'tidak',
      'non-halal',
      'non halal',
      'nonhalal',
      'haram',
      'pork',
      'babi',
    ].contains(text)) {
      return false;
    }

    if ([
      'true',
      '1',
      'yes',
      'ya',
      'halal',
      'aman',
      'verified',
    ].contains(text)) {
      return true;
    }

    if (text.contains('non-halal') ||
        text.contains('non halal') ||
        text.contains('nonhalal') ||
        text.contains('haram') ||
        text.contains('babi') ||
        text.contains('pork')) {
      return false;
    }

    return true;
  }
}
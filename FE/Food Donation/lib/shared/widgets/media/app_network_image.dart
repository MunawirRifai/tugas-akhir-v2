import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData placeholderIcon;
  final IconData errorIcon;
  final Color placeholderBackgroundColor;
  final Color placeholderIconColor;
  final Color errorBackgroundColor;
  final Color errorIconColor;
  final Color? borderColor;
  final String? heroTag;
  final String? semanticLabel;
  final EdgeInsetsGeometry margin;
  final Clip clipBehavior;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.lg,
    this.placeholderIcon = Icons.fastfood_rounded,
    this.errorIcon = Icons.broken_image_outlined,
    this.placeholderBackgroundColor = AppColors.accentSoft,
    this.placeholderIconColor = AppColors.accent,
    this.errorBackgroundColor = AppColors.surfaceSoft,
    this.errorIconColor = AppColors.textSecondary,
    this.borderColor,
    this.heroTag,
    this.semanticLabel,
    this.margin = EdgeInsets.zero,
    this.clipBehavior = Clip.antiAlias,
  });

  const AppNetworkImage.avatar({
    super.key,
    required this.imageUrl,
    required double size,
    this.fit = BoxFit.cover,
    this.borderRadius = 999,
    this.placeholderIcon = Icons.person_rounded,
    this.errorIcon = Icons.person_rounded,
    this.placeholderBackgroundColor = AppColors.primarySoft,
    this.placeholderIconColor = AppColors.primaryDark,
    this.errorBackgroundColor = AppColors.surfaceSoft,
    this.errorIconColor = AppColors.textSecondary,
    this.borderColor,
    this.heroTag,
    this.semanticLabel,
    this.margin = EdgeInsets.zero,
    this.clipBehavior = Clip.antiAlias,
  })  : width = size,
        height = size;

  const AppNetworkImage.food({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppRadius.lg,
    this.placeholderIcon = Icons.fastfood_rounded,
    this.errorIcon = Icons.fastfood_rounded,
    this.placeholderBackgroundColor = AppColors.accentSoft,
    this.placeholderIconColor = AppColors.accent,
    this.errorBackgroundColor = AppColors.accentSoft,
    this.errorIconColor = AppColors.accent,
    this.borderColor,
    this.heroTag,
    this.semanticLabel,
    this.margin = EdgeInsets.zero,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final String? resolvedImageUrl = _normalizedImageUrl;

    final Widget imageContent = resolvedImageUrl == null
        ? _ImageFallback(
            width: width,
            height: height,
            borderRadius: borderRadius,
            icon: placeholderIcon,
            backgroundColor: placeholderBackgroundColor,
            iconColor: placeholderIconColor,
            borderColor: borderColor,
            clipBehavior: clipBehavior,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            clipBehavior: clipBehavior,
            child: Image.network(
              resolvedImageUrl,
              width: width,
              height: height,
              fit: fit,
              semanticLabel: semanticLabel,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }

                return _ImageFallback(
                  width: width,
                  height: height,
                  borderRadius: borderRadius,
                  icon: placeholderIcon,
                  backgroundColor: placeholderBackgroundColor,
                  iconColor: placeholderIconColor,
                  borderColor: borderColor,
                  showLoader: true,
                  clipBehavior: clipBehavior,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return _ImageFallback(
                  width: width,
                  height: height,
                  borderRadius: borderRadius,
                  icon: errorIcon,
                  backgroundColor: errorBackgroundColor,
                  iconColor: errorIconColor,
                  borderColor: borderColor,
                  clipBehavior: clipBehavior,
                );
              },
            ),
          );

    final Widget resolvedContent = heroTag == null
        ? imageContent
        : Hero(
            tag: heroTag!,
            child: imageContent,
          );

    return Padding(
      padding: margin,
      child: resolvedContent,
    );
  }

  String? get _normalizedImageUrl {
    final String value = imageUrl?.trim() ?? '';

    if (value.isEmpty || value == 'null') {
      return null;
    }

    return value;
  }
}

class _ImageFallback extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color? borderColor;
  final bool showLoader;
  final Clip clipBehavior;

  const _ImageFallback({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.borderColor,
    required this.clipBehavior,
    this.showLoader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor == null
            ? null
            : Border.all(
                color: borderColor!,
              ),
      ),
      child: Center(
        child: showLoader
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                ),
              )
            : Icon(
                icon,
                color: iconColor,
                size: _iconSize,
              ),
      ),
    );
  }

  double get _iconSize {
    final double? resolvedWidth = width;
    final double? resolvedHeight = height;

    if (resolvedWidth == null || resolvedHeight == null) {
      return 34;
    }

    final double shortestSide =
        resolvedWidth < resolvedHeight ? resolvedWidth : resolvedHeight;

    if (shortestSide <= 48) {
      return 22;
    }

    if (shortestSide <= 88) {
      return 30;
    }

    return 42;
  }
}
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'app_surface_card.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color iconColor;
  final Color iconBackgroundColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double maxWidth;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor = AppColors.textSecondary,
    this.iconBackgroundColor = AppColors.surfaceSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.margin = EdgeInsets.zero,
    this.maxWidth = 360,
  });

  const AppEmptyState.search({
    super.key,
    this.icon = Icons.search_off_rounded,
    this.title = 'Tidak Ada Hasil',
    this.message =
        'Tidak ada data yang cocok dengan pencarian atau filter saat ini.',
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    this.iconColor = AppColors.textSecondary,
    this.iconBackgroundColor = AppColors.surfaceSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.margin = EdgeInsets.zero,
    this.maxWidth = 360,
  });

  const AppEmptyState.data({
    super.key,
    this.icon = Icons.inventory_2_outlined,
    this.title = 'Belum Ada Data',
    this.message = 'Data akan muncul di sini setelah tersedia.',
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    this.iconColor = AppColors.textSecondary,
    this.iconBackgroundColor = AppColors.surfaceSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.margin = EdgeInsets.zero,
    this.maxWidth = 360,
  });

  const AppEmptyState.error({
    super.key,
    this.icon = Icons.error_outline_rounded,
    this.title = 'Terjadi Kendala',
    this.message = 'Data belum bisa dimuat. Periksa koneksi lalu coba lagi.',
    this.actionLabel = 'Coba Lagi',
    this.actionIcon = Icons.refresh_rounded,
    this.onAction,
    this.iconColor = AppColors.danger,
    this.iconBackgroundColor = AppColors.dangerSoft,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    this.margin = EdgeInsets.zero,
    this.maxWidth = 360,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppSurfaceCard(
        margin: margin,
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.x3),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(
                      actionIcon ?? Icons.arrow_forward_rounded,
                    ),
                    label: Text(actionLabel!),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
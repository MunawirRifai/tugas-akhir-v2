import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/services/food_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/widgets/common/app_surface_card.dart';
import '../../../shared/widgets/media/app_network_image.dart';


class NotificationPage extends StatefulWidget {
  final String token;

  const NotificationPage({super.key, required this.token});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = true;
  bool _isRefreshing = false;
  late List<_NotificationItem> _notifications;

  int get _unreadCount {
    return _notifications.where((item) => !item.isRead).length;
  }

  int get _pickupCount {
    return _notifications
        .where((item) => item.category == _NotificationCategory.pickup)
        .length;
  }

  int get _donationCount {
    return _notifications
        .where((item) => item.category == _NotificationCategory.donation)
        .length;
  }

  @override
  void initState() {
    super.initState();

    _notifications = [];
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool showRefreshState = false}) async {
    if (showRefreshState && mounted) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final List<Map<String, dynamic>> result =
          await NotificationService.getNotifications(token: widget.token);

      if (!mounted) return;

      setState(() {
        _notifications = result.map(_NotificationItem.fromMap).toList();
        _isLoading = false;
      });

      if (showRefreshState) {
        _showSnack('Notifikasi berhasil diperbarui.', isError: false);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnack('Gagal memuat notifikasi: $error', isError: true);
    } finally {
      if (mounted && showRefreshState) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshNotifications() {
    return _loadNotifications(showRefreshState: true);
  }

  Future<void> _markAllAsRead() async {
    final List<_NotificationItem> previousNotifications = _notifications;

    setState(() {
      _notifications = _notifications
          .map((item) => item.copyWith(isRead: true))
          .toList();
    });

    _showSnack('Semua notifikasi ditandai sudah dibaca.', isError: false);

    try {
      await NotificationService.markAllAsRead(token: widget.token);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _notifications = previousNotifications;
      });

      _showSnack('Gagal menandai notifikasi: $error', isError: true);
    }
  }

  Future<void> _markAsRead(String id) async {
    setState(() {
      _notifications = _notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }

        return item;
      }).toList();
    });

    try {
      await NotificationService.markAsRead(
        token: widget.token,
        notificationId: id,
      );
    } catch (error) {
      debugPrint('MARK NOTIFICATION READ ERROR: $error');
    }
  }

  void _showNotificationDetail(_NotificationItem item) {
    _markAsRead(item.id);

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _NotificationDetailSheet(
          token: widget.token,
          item: item.copyWith(isRead: true),
        );
      },
    );
  }

  void _showSnack(String message, {required bool isError}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshNotifications,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x3,
                  AppSpacing.x2,
                ),
                sliver: SliverToBoxAdapter(
                  child: _NotificationHeader(
                    unreadCount: _unreadCount,
                    pickupCount: _pickupCount,
                    donationCount: _donationCount,
                    isRefreshing: _isRefreshing,
                    onRefresh: _refreshNotifications,
                    onMarkAllAsRead: _unreadCount == 0
                        ? null
                        : () => _markAllAsRead(),
                  ),
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_notifications.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyNotificationState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x3,
                    0,
                    AppSpacing.x3,
                    AppSpacing.x4,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) {
                      return const SizedBox(height: AppSpacing.x2);
                    },
                    itemBuilder: (context, index) {
                      final _NotificationItem item = _notifications[index];

                      return _NotificationCard(
                        item: item,
                        onTap: () => _showNotificationDetail(item),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  final int unreadCount;
  final int pickupCount;
  final int donationCount;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final VoidCallback? onMarkAllAsRead;

  const _NotificationHeader({
    required this.unreadCount,
    required this.pickupCount,
    required this.donationCount,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onMarkAllAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.brand,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifikasi',
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unreadCount == 0
                            ? 'Semua notifikasi sudah dibaca.'
                            : '$unreadCount notifikasi belum dibaca.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: isRefreshing ? null : onRefresh,
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x3),
            Row(
              children: [
                Expanded(
                  child: _NotificationSummaryTile(
                    label: 'Pickup',
                    value: '$pickupCount',
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _NotificationSummaryTile(
                    label: 'Donasi',
                    value: '$donationCount',
                    icon: Icons.volunteer_activism_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.x1),
                Expanded(
                  child: _NotificationSummaryTile(
                    label: 'Unread',
                    value: '$unreadCount',
                    icon: Icons.mark_email_unread_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x2),
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: onMarkAllAsRead,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.42)),
                ),
                icon: const Icon(Icons.done_all_rounded),
                label: const Text('Tandai Semua Dibaca'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _NotificationSummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final _NotificationStyle style = _NotificationStyle.fromCategory(
      item.category,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: item.isRead
              ? AppColors.border
              : style.color.withValues(alpha: 0.28),
          width: item.isRead ? 1 : 1.4,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(style.icon, color: style.color),
                    ),
                    if (!item.isRead)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Text(
                            item.timeAgoLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.x1),
                      Row(
                        children: [
                          _CategoryPill(
                            label: style.label,
                            color: style.color,
                            icon: style.icon,
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _CategoryPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x1,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationDetailSheet extends StatefulWidget {
  final String token;
  final _NotificationItem item;

  const _NotificationDetailSheet({
    required this.token,
    required this.item,
  });

  @override
  State<_NotificationDetailSheet> createState() => _NotificationDetailSheetState();
}

class _NotificationDetailSheetState extends State<_NotificationDetailSheet> {
  bool _isLoading = false;
  Map<String, dynamic>? _foodDetail;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDetailIfNeeded();
  }

  bool get _shouldFetchDetail {
    return widget.item.foodId != null &&
        (widget.item.category == _NotificationCategory.proof ||
            widget.item.category == _NotificationCategory.pickup);
  }

  Future<void> _fetchDetailIfNeeded() async {
    if (!_shouldFetchDetail) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await FoodService.getFoodDetail(
        token: widget.token,
        foodId: widget.item.foodId!,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          _foodDetail = response['data'] as Map<String, dynamic>? ?? response;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? 'Gagal memuat detail makanan.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat detail makanan: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _NotificationStyle style = _NotificationStyle.fromCategory(
      widget.item.category,
    );

    return SafeArea(
      top: false,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.x2),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x3,
                  AppSpacing.x2,
                  AppSpacing.x3,
                  AppSpacing.x3,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Icon(style.icon, color: style.color, size: 34),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    _CategoryPill(
                      label: style.label,
                      color: style.color,
                      icon: style.icon,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      widget.item.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      widget.item.message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      widget.item.timeAgoLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                    if (_shouldFetchDetail) ...[
                      const SizedBox(height: AppSpacing.x3),
                      const Divider(),
                      const SizedBox(height: AppSpacing.x2),
                      _buildDetailContent(),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.x3),
              child: SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mengerti'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.x4),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
          child: Column(
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.x2),
              OutlinedButton.icon(
                onPressed: _fetchDetailIfNeeded,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_foodDetail == null) {
      return const SizedBox.shrink();
    }

    final detail = _foodDetail!;
    final String foodName = detail['food_name']?.toString() ?? '-';
    final String? description = detail['description']?.toString();
    final String? address = detail['address']?.toString();
    final String? proofPhotoUrl = detail['proof_photo_url']?.toString();
    final String? claimerName = detail['claimer_name']?.toString();
    final String? claimerPhone = detail['claimer_phone']?.toString();
    final String? claimerNote = detail['claimer_note']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail Makanan',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: AppSpacing.x2),
        Card(
          elevation: 0,
          color: AppColors.surfaceSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (detail['photo_url'] != null) ...[
                      AppNetworkImage(
                        imageUrl: detail['photo_url'].toString(),
                        width: 72,
                        height: 72,
                        borderRadius: AppRadius.md,
                      ),
                      const SizedBox(width: AppSpacing.x2),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            foodName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (detail['category'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Kategori: ${detail['category']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (detail['food_condition'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Kondisi: ${detail['food_condition']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x2),
                  const Divider(),
                  const SizedBox(height: 4),
                  const Text(
                    'Deskripsi:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (address != null && address.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x1),
                  const Text(
                    'Lokasi Pengambilan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    address,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (claimerName != null || claimerPhone != null) ...[
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Informasi Penerima',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Card(
            elevation: 0,
            color: AppColors.surfaceSoft,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                title: Text(
                  claimerName ?? 'Penerima',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(claimerPhone ?? 'Tidak ada nomor telepon'),
                trailing: claimerPhone != null
                    ? IconButton(
                        icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                        tooltip: 'Salin Nomor',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: claimerPhone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nomor telepon berhasil disalin')),
                          );
                        },
                      )
                    : null,
              ),
            ),
          ),
        ],
        if (claimerNote != null && claimerNote.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Pesan dari Penerima',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.x2),
          AppSurfaceCard(
            padding: const EdgeInsets.all(AppSpacing.x3),
            backgroundColor: AppColors.accentSoft.withValues(alpha: 0.5),
            borderColor: AppColors.accent.withValues(alpha: 0.15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.x2),
                Expanded(
                  child: Text(
                    '"$claimerNote"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.item.category == _NotificationCategory.proof &&
            proofPhotoUrl != null &&
            proofPhotoUrl.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x3),
          Text(
            'Foto Bukti Penerimaan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpacing.x2),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: AppNetworkImage(
              imageUrl: proofPhotoUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }
}

class _EmptyNotificationState extends StatelessWidget {
  const _EmptyNotificationState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.card,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textSecondary,
                    size: 38,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  'Belum Ada Notifikasi',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  'Informasi klaim, pickup, dan aktivitas donasi akan muncul di sini.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _NotificationCategory { donation, pickup, route, proof, security }

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final _NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;
  final int? foodId;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.foodId,
  });

  factory _NotificationItem.fromMap(Map<String, dynamic> map) {
    final String category = _textOf(
      _valueOf(map, ['category', 'type']),
      fallback: 'donation',
    ).toLowerCase();

    return _NotificationItem(
      id: _textOf(_valueOf(map, ['id', 'notification_id']), fallback: ''),
      title: _textOf(_valueOf(map, ['title']), fallback: 'Notifikasi'),
      message: _textOf(
        _valueOf(map, ['message', 'body', 'description']),
        fallback: 'Ada pembaruan terbaru.',
      ),
      category: _categoryOf(category),
      createdAt:
          _dateTimeOf(_valueOf(map, ['created_at', 'createdAt'])) ??
          DateTime.now(),
      isRead: _boolOf(_valueOf(map, ['is_read', 'isRead', 'read'])),
      foodId: _intOf(_valueOf(map, ['food_id', 'foodId'])),
    );
  }

  _NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    _NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
    int? foodId,
  }) {
    return _NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      foodId: foodId ?? this.foodId,
    );
  }

  String get timeAgoLabel {
    final Duration difference = DateTime.now().difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    }

    return '${difference.inDays} hari lalu';
  }

  static _NotificationCategory _categoryOf(String value) {
    switch (value) {
      case 'pickup':
        return _NotificationCategory.pickup;
      case 'route':
        return _NotificationCategory.route;
      case 'proof':
        return _NotificationCategory.proof;
      case 'security':
        return _NotificationCategory.security;
      case 'donation':
      default:
        return _NotificationCategory.donation;
    }
  }
}

Object? _valueOf(Map<String, dynamic> data, List<String> keys) {
  for (final String key in keys) {
    if (data.containsKey(key)) {
      return data[key];
    }
  }

  return null;
}

String _textOf(Object? value, {required String fallback}) {
  final String text = value?.toString().trim() ?? '';

  if (text.isEmpty || text == 'null') {
    return fallback;
  }

  return text;
}

bool _boolOf(Object? value) {
  if (value is bool) return value;

  final String text = value?.toString().trim().toLowerCase() ?? '';

  return text == 'true' || text == '1' || text == 'yes';
}

int? _intOf(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  final String text = value.toString().trim();
  return int.tryParse(text);
}

DateTime? _dateTimeOf(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;

  return DateTime.tryParse(value.toString());
}

class _NotificationStyle {
  final String label;
  final IconData icon;
  final Color color;

  const _NotificationStyle({
    required this.label,
    required this.icon,
    required this.color,
  });

  factory _NotificationStyle.fromCategory(_NotificationCategory category) {
    switch (category) {
      case _NotificationCategory.donation:
        return const _NotificationStyle(
          label: 'Donasi',
          icon: Icons.volunteer_activism_rounded,
          color: AppColors.primary,
        );
      case _NotificationCategory.pickup:
        return const _NotificationStyle(
          label: 'Pickup',
          icon: Icons.shopping_bag_outlined,
          color: AppColors.accent,
        );
      case _NotificationCategory.route:
        return const _NotificationStyle(
          label: 'Rute',
          icon: Icons.route_rounded,
          color: AppColors.teal,
        );
      case _NotificationCategory.proof:
        return const _NotificationStyle(
          label: 'Bukti',
          icon: Icons.fact_check_rounded,
          color: AppColors.primaryDark,
        );
      case _NotificationCategory.security:
        return const _NotificationStyle(
          label: 'Keamanan',
          icon: Icons.privacy_tip_outlined,
          color: AppColors.danger,
        );
    }
  }
}

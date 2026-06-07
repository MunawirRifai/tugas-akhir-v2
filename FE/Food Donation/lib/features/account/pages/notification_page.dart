import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class NotificationPage extends StatefulWidget {
  final String token;

  const NotificationPage({
    super.key,
    required this.token,
  });

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
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

    _notifications = _mockNotifications();
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _isRefreshing = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 650),
    );

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
      _notifications = _mockNotifications();
    });

    _showSnack(
      'Notifikasi berhasil diperbarui.',
      isError: false,
    );
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map(
            (item) => item.copyWith(isRead: true),
          )
          .toList();
    });

    _showSnack(
      'Semua notifikasi ditandai sudah dibaca.',
      isError: false,
    );
  }

  void _markAsRead(String id) {
    setState(() {
      _notifications = _notifications.map((item) {
        if (item.id == id) {
          return item.copyWith(isRead: true);
        }

        return item;
      }).toList();
    });
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
          item: item.copyWith(isRead: true),
        );
      },
    );
  }

  void _showSnack(
    String message, {
    required bool isError,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.danger : AppColors.textPrimary,
        content: Text(message),
      ),
    );
  }

  List<_NotificationItem> _mockNotifications() {
    final DateTime now = DateTime.now();

    return [
      _NotificationItem(
        id: 'notif-001',
        title: 'Makanan berhasil diklaim',
        message:
            'Anda sedang mengambil Paket Nasi Box. Selesaikan pengambilan dengan bukti foto setelah makanan diterima.',
        category: _NotificationCategory.pickup,
        createdAt: now.subtract(
          const Duration(minutes: 8),
        ),
        isRead: false,
      ),
      _NotificationItem(
        id: 'notif-002',
        title: 'Ada penerima tertarik',
        message:
            'Postingan Roti dan Snack Anda dilihat oleh beberapa pengguna di radius terdekat.',
        category: _NotificationCategory.donation,
        createdAt: now.subtract(
          const Duration(minutes: 34),
        ),
        isRead: false,
      ),
      _NotificationItem(
        id: 'notif-003',
        title: 'Rute prioritas diperbarui',
        message:
            'Smart Cart mengatur ulang rute pickup berdasarkan skor prioritas dan jarak terbaru.',
        category: _NotificationCategory.route,
        createdAt: now.subtract(
          const Duration(hours: 1, minutes: 12),
        ),
        isRead: true,
      ),
      _NotificationItem(
        id: 'notif-004',
        title: 'Bukti pengambilan diproses',
        message:
            'Bukti foto Anda berhasil dikompresi secara simulatif dan status pengambilan berubah menjadi selesai.',
        category: _NotificationCategory.proof,
        createdAt: now.subtract(
          const Duration(hours: 3),
        ),
        isRead: true,
      ),
      _NotificationItem(
        id: 'notif-005',
        title: 'Tips keamanan donasi',
        message:
            'Gunakan komunikasi in-app dan hindari membagikan nomor pribadi saat proses pengambilan makanan.',
        category: _NotificationCategory.security,
        createdAt: now.subtract(
          const Duration(days: 1, hours: 2),
        ),
        isRead: true,
      ),
    ];
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
                    onMarkAllAsRead:
                        _unreadCount == 0 ? null : _markAllAsRead,
                  ),
                ),
              ),
              if (_notifications.isEmpty)
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
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
                      : const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
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
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
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
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
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

  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

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
                      child: Icon(
                        style.icon,
                        color: style.color,
                      ),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.x1),
                          Text(
                            item.timeAgoLabel,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
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
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 13,
          ),
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

class _NotificationDetailSheet extends StatelessWidget {
  final _NotificationItem item;

  const _NotificationDetailSheet({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final _NotificationStyle style = _NotificationStyle.fromCategory(
      item.category,
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x3,
            AppSpacing.x2,
            AppSpacing.x3,
            AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: AppSpacing.x3),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Icon(
                  style.icon,
                  color: style.color,
                  size: 34,
                ),
              ),
              const SizedBox(height: AppSpacing.x2),
              _CategoryPill(
                label: style.label,
                color: style.color,
                icon: style.icon,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                item.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                item.timeAgoLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: AppSpacing.x3),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        ),
      ),
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

enum _NotificationCategory {
  donation,
  pickup,
  route,
  proof,
  security,
}

class _NotificationItem {
  final String id;
  final String title;
  final String message;
  final _NotificationCategory category;
  final DateTime createdAt;
  final bool isRead;

  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });

  _NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    _NotificationCategory? category,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return _NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
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